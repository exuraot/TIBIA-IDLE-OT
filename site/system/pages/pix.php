<?php
global $db, $config, $twig, $logged, $account_logged, $action;

defined('MYAAC') or die('Direct access not allowed!');
$title = 'Doação via PIX (Instantâneo)';

require_once PLUGINS . 'mercadopago/config.php';
require_once LIBS . 'MercadoPago/MercadoPagoClient.php';

$twig->addGlobal('config', $config);

// 1. Ensure table exists
if (!$db->hasTable('mercadopago_transactions')) {
    $installSql = file_get_contents(PLUGINS . 'mercadopago/install.sql');
    if ($installSql) {
        $db->exec($installSql);
    }
}

// 2. Authentication check
if (!$logged || !$account_logged) {
    echo 'Para doar via PIX, você precisa estar logado na sua conta. ' . 
         generateLink(getLink('?subtopic=accountmanagement') . '&redirect=' . urlencode(BASE_URL . '?subtopic=pix'), 'Clique aqui para Logar') . '.';
    return;
}

$accessToken = $config['mercadoPago']['access_token'] ?? '';
if (empty($accessToken)) {
    warning("O sistema de doação via PIX está em configuração. Por favor, solicite ao administrador para preencher o Access Token do Mercado Pago em <code>plugins/mercadopago/config.php</code>.");
    return;
}

$accountId = (int)$account_logged->getId();
$accountEmail = $account_logged->getEMail();

// 3. Status Polling check (AJAX)
if ($action === 'check') {
    header('Content-Type: application/json; charset=UTF-8');
    $paymentId = preg_replace('/[^0-9]/', '', $_GET['payment_id'] ?? '');

    if (empty($paymentId)) {
        echo json_encode(['approved' => false, 'error' => 'invalid_id']);
        exit;
    }

    $stmt = $db->prepare("SELECT * FROM `mercadopago_transactions` WHERE `payment_id` = :pid AND `account_id` = :acc LIMIT 1");
    $stmt->execute([':pid' => $paymentId, ':acc' => $accountId]);
    $tx = $stmt->fetch();

    if (!$tx) {
        echo json_encode(['approved' => false, 'error' => 'not_found']);
        exit;
    }

    if ((int)$tx['delivered'] === 1 || $tx['status'] === 'approved') {
        echo json_encode(['approved' => true, 'status' => 'approved', 'coins' => (int)$tx['coins_amount']]);
        exit;
    }

    // Fast check directly with Mercado Pago API
    try {
        $paymentData = MercadoPagoClient::getPayment($accessToken, $paymentId);
        $status = $paymentData['status'] ?? 'pending';

        if ($status === 'approved' && (int)$tx['delivered'] === 0) {
            $now = date('Y-m-d H:i:s');
            $lockStmt = $db->prepare("UPDATE `mercadopago_transactions` SET `delivered` = 1, `status` = 'approved', `updated_at` = :updated WHERE `id` = :id AND `delivered` = 0");
            $lockStmt->execute([
                ':updated' => $now,
                ':id' => (int)$tx['id']
            ]);

            if ($lockStmt->rowCount() > 0) {
                $coinsAmount = (int)$tx['coins_amount'];
                $field = (strtolower($config['mercadoPago']['donationType'] ?? '') === 'coins') ? 'coins' : 'coins_transferable';
                $db->exec("UPDATE `accounts` SET `{$field}` = `{$field}` + {$coinsAmount} WHERE `id` = {$accountId}");

                $db->prepare("INSERT INTO `coins_transactions` (`account_id`, `type`, `amount`, `description`, `timestamp`, `coin_type`) VALUES (:acc, 1, :amount, 'Donate Mercado Pago PIX', :tstamp, 3)")->execute([
                    ':acc' => $accountId,
                    ':amount' => $coinsAmount,
                    ':tstamp' => $now
                ]);

                $timestamp = strtotime($now);
                $db->prepare("INSERT INTO `store_history` (`account_id`, `mode`, `description`, `coin_type`, `coin_amount`, `time`, `timestamp`, `coins`) VALUES (:acc, 0, 'Donate Mercado Pago PIX', 3, :amount, :tstamp, 0, 0)")->execute([
                    ':acc' => $accountId,
                    ':amount' => $coinsAmount,
                    ':tstamp' => $timestamp
                ]);

                log_append('mercadopago_success.log', "{$now}: Account {$accountId} received {$coinsAmount} coins via poller check (Payment: {$paymentId})");
            }

            echo json_encode(['approved' => true, 'status' => 'approved', 'coins' => (int)$tx['coins_amount']]);
            exit;
        }
    } catch (\Exception $e) {
        // Silently continue
    }

    echo json_encode(['approved' => false, 'status' => $tx['status']]);
    exit;
}

// 4. Create PIX Payment
if ($action === 'create' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $code = $_POST['code'] ?? null;
    if (!$code || !isset($config['mercadoPago']['donates'][$code])) {
        error("Pacote de doação inválido.");
        return;
    }

    $package = $config['mercadoPago']['donates'][$code];
    $amount = (float)$package['value'];
    $bought = (int)$package['coins'];
    $extra = (int)($package['extra'] ?? 0);
    $isDoubled = ($config['mercadoPago']['doubleCoins'] && $bought >= (int)$config['mercadoPago']['doubleCoinsStart']);
    $coinsAmount = ($isDoubled ? $bought * 2 : $bought) + $extra;

    $desc = "{$coinsAmount} {$config['mercadoPago']['productName']} - {$account_logged->getName()}";
    $notificationUrl = !empty($config['mercadoPago']['notification_url']) 
        ? $config['mercadoPago']['notification_url'] 
        : rtrim(BASE_URL, '/') . '/payments/mercadopago.php';

    $externalRef = "coins_{$accountId}_{$code}_{$coinsAmount}";

    try {
        $payment = MercadoPagoClient::createPixPayment(
            $accessToken,
            $amount,
            $desc,
            $accountEmail,
            $accountId,
            $notificationUrl,
            $externalRef
        );

        $now = date('Y-m-d H:i:s');
        $stmtIns = $db->prepare("INSERT INTO `mercadopago_transactions` 
            (`payment_id`, `account_id`, `transaction_type`, `item_code`, `item_name`, `coins_amount`, `price`, `status`, `delivered`, `qr_code`, `qr_code_base64`, `ticket_url`, `created_at`) 
            VALUES (:pid, :acc, 'coins', :code, :name, :coins, :price, :st, 0, :qr, :qrb64, :ticket, :created)");
        $stmtIns->execute([
            ':pid'    => $payment['id'],
            ':acc'    => $accountId,
            ':code'   => $code,
            ':name'   => $desc,
            ':coins'  => $coinsAmount,
            ':price'  => $amount,
            ':st'     => $payment['status'],
            ':qr'     => $payment['qr_code'],
            ':qrb64'  => $payment['qr_code_base64'],
            ':ticket' => $payment['ticket_url'],
            ':created'=> $now
        ]);

        echo $twig->render('pix.html.twig', [
            'action'         => 'payment',
            'payment'        => [
                'id'             => $payment['id'],
                'amount'         => $amount,
                'coins'          => $coinsAmount,
                'qr_code'        => $payment['qr_code'],
                'qr_code_base64' => $payment['qr_code_base64'],
                'ticket_url'     => $payment['ticket_url']
            ],
            'account_logged' => $account_logged
        ]);
        return;
    } catch (\Exception $e) {
        log_append('mercadopago_errors.log', date('Y-m-d H:i:s') . ': ' . $e->getMessage());
        error("Erro ao gerar pagamento PIX: " . htmlspecialchars($e->getMessage()));
        return;
    }
}

// 5. Default view: List packages
echo $twig->render('pix.html.twig', [
    'action'       => '',
    'is_double'    => $config['mercadoPago']['doubleCoins'],
    'double_start' => $config['mercadoPago']['doubleCoinsStart'],
    'account_logged'=> $account_logged
]);
