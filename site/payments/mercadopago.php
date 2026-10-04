<?php
/**
 * Mercado Pago Webhook / IPN Notification Handler.
 *
 * @name      myaac-mercadopago-webhook
 * @copyright 2026 MyAAC
 */

global $db;
require_once '../common.php';
require_once SYSTEM . 'functions.php';
require_once SYSTEM . 'init.php';
require_once PLUGINS . 'mercadopago/config.php';
require_once LIBS . 'MercadoPago/MercadoPagoClient.php';

header("Content-Type: application/json; charset=UTF-8");

$accessToken = $config['mercadoPago']['access_token'] ?? '';
if (empty($accessToken)) {
    http_response_code(500);
    echo json_encode(['error' => 'Mercado Pago access token not configured.']);
    exit;
}

// 1. Capture payment ID from JSON body or Query Params
$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?: [];

$paymentId = null;
if (isset($body['data']['id'])) {
    $paymentId = $body['data']['id'];
} elseif (isset($body['id'])) {
    $paymentId = $body['id'];
} elseif (isset($_GET['data_id'])) {
    $paymentId = $_GET['data_id'];
} elseif (isset($_GET['id'])) {
    $paymentId = $_GET['id'];
} elseif (isset($_POST['data_id'])) {
    $paymentId = $_POST['data_id'];
} elseif (isset($_POST['id'])) {
    $paymentId = $_POST['id'];
}

$paymentId = preg_replace('/[^0-9]/', '', (string)$paymentId);
if (empty($paymentId)) {
    // Return 200 to acknowledge test notifications or non-payment webhooks
    http_response_code(200);
    echo json_encode(['status' => 'ignored', 'message' => 'No valid payment id found.']);
    exit;
}

try {
    // 2. Fetch authoritative payment status directly from Mercado Pago API
    $payment = MercadoPagoClient::getPayment($accessToken, $paymentId);
    $status = $payment['status'] ?? '';
    $paymentMethod = $payment['payment_method_id'] ?? 'pix';
    $amount = (float)($payment['transaction_amount'] ?? 0);
    $externalRef = $payment['external_reference'] ?? '';

    // Check if table exists
    if (!$db->hasTable('mercadopago_transactions')) {
        http_response_code(500);
        echo json_encode(['error' => 'mercadopago_transactions table missing.']);
        exit;
    }

    // 3. Query local transaction
    $stmt = $db->prepare("SELECT * FROM `mercadopago_transactions` WHERE `payment_id` = :pid LIMIT 1");
    $stmt->execute([':pid' => $paymentId]);
    $tx = $stmt->fetch();

    $now = date('Y-m-d H:i:s');

    if (!$tx) {
        // If not in database, attempt to parse external_reference (format: TYPE_ACCID_ITEMCODE_COINS)
        $parts = explode('_', (string)$externalRef);
        if (count($parts) >= 3) {
            $txType = $parts[0];
            $accId = (int)$parts[1];
            $itemCode = $parts[2];
            $coins = (int)($parts[3] ?? 0);

            $ins = $db->prepare("INSERT INTO `mercadopago_transactions` (`payment_id`, `account_id`, `transaction_type`, `item_code`, `item_name`, `coins_amount`, `price`, `status`, `delivered`, `request`, `created_at`) VALUES (:pid, :acc, :type, :code, :name, :coins, :price, :status, 0, :req, :created)");
            $ins->execute([
                ':pid' => $paymentId,
                ':acc' => $accId,
                ':type' => $txType,
                ':code' => $itemCode,
                ':name' => 'Mercado Pago Item',
                ':coins' => $coins,
                ':price' => $amount,
                ':status' => $status,
                ':req' => $rawBody,
                ':created' => $now
            ]);
            $txId = (int)$db->lastInsertId();
            $delivered = 0;
            $accountId = $accId;
            $coinsAmount = $coins;
            $transactionType = $txType;
        } else {
            http_response_code(200);
            echo json_encode(['status' => 'ignored', 'message' => 'Transaction not recognized.']);
            exit;
        }
    } else {
        $txId = (int)$tx['id'];
        $delivered = (int)$tx['delivered'];
        $accountId = (int)$tx['account_id'];
        $coinsAmount = (int)$tx['coins_amount'];
        $transactionType = (string)$tx['transaction_type'];
    }

    // 4. Handle approved payment with atomic lock
    if ($status === 'approved' && $delivered === 0) {
        $lockStmt = $db->prepare("UPDATE `mercadopago_transactions` SET `delivered` = 1, `status` = 'approved', `updated_at` = :updated WHERE `id` = :id AND `delivered` = 0");
        $lockStmt->execute([
            ':updated' => $now,
            ':id' => $txId
        ]);

        if ($lockStmt->rowCount() > 0) {
            if ($transactionType === 'box') {
                // Deliver Box to myaac_send_items
                $boxId = $tx['item_code'];
                $boxName = $tx['item_name'];
                $db->prepare("INSERT INTO `myaac_send_items` (`transaction_code`, `item_id`, `item_name`, `item_count`, `account_id`, `payment_method`, `payment_status`, `status`, `request`, `created_at`) VALUES (:tcode, :item_id, :item_name, 1, :acc, 'PIX_MP', 'PAID', '1', :req, :created)")->execute([
                    ':tcode' => $paymentId,
                    ':item_id' => $boxId,
                    ':item_name' => $boxName,
                    ':acc' => $accountId,
                    ':req' => $rawBody,
                    ':created' => $now
                ]);
                log_append('mercadopago_success.log', "{$now}: Box {$boxName} delivered to Account {$accountId} (Payment: {$paymentId})");
            } else {
                // Deliver Coins
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

                log_append('mercadopago_success.log', "{$now}: Account {$accountId} received {$coinsAmount} coins (Payment: {$paymentId})");
            }
        }
    } else {
        $db->prepare("UPDATE `mercadopago_transactions` SET `status` = :st, `updated_at` = :updated WHERE `id` = :id")->execute([
            ':st' => $status,
            ':updated' => $now,
            ':id' => $txId
        ]);

        if (in_array($status, ['cancelled', 'refunded', 'charged_back'])) {
            log_append('mercadopago_cancellations.log', "{$now}: Payment {$paymentId} for Account {$accountId} changed status to {$status}");
        }
    }

    http_response_code(200);
    echo json_encode(['status' => 'success', 'payment_status' => $status]);
} catch (\Exception $e) {
    log_append('mercadopago_errors.log', date('Y-m-d H:i:s') . ': ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
