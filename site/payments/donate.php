<?php
/**
 * Automatic PagSeguro payment system gateway.
 *
 * @name      myaac-pagseguro
 * @author    Ivens Pontes <ivenscardoso@hotmail.com>
 * @author    Slawkens <slawkens@gmail.com>
 * @author    Elson <elsongabriel@hotmail.com>
 * @copyright 2023 MyAAC
 */

global $db;
require_once '../common.php';
require_once SYSTEM . 'functions.php';
require_once SYSTEM . 'init.php';
require_once PLUGINS . 'pagseguro/config.php';
require_once LIBS . 'PagSeguroLibrary/PagSeguroLibrary.php';

if (
  !isset($config['pagSeguro']) ||
  !count($config['pagSeguro']) ||
  !count($config['pagSeguro']['donates'])
) {
  echo "PagSeguro is disabled. If you're an admin please configure this script in config.local.php.";
  return;
}

header('access-control-allow-origin: https://pagseguro.uol.com.br');

$method = $_SERVER['REQUEST_METHOD'];
if ('post' == strtolower($method)) {
  $type = $_POST['notificationType'] ?? null;
  $notificationCode = $_POST['notificationCode'] ?? null;

  if ($type === 'transaction' && !empty($notificationCode)) {
    // Validate notification code pattern to prevent URL manipulation / SSRF
    if (!preg_match('/^[A-Za-z0-9\-]+$/', $notificationCode)) {
      log_append('pagseguro_donate_errors.log', date('Y-m-d H:i:s') . ': Invalid notificationCode format: ' . $notificationCode);
      die('Invalid notification code.');
    }

    try {
      $credentials = PagSeguroConfig::getAccountCredentials();
      $transaction = PagSeguroNotificationService::checkTransaction(
        $credentials,
        $notificationCode
      );

      if (!$transaction) {
        die('Transaction not found.');
      }

      $transaction_code = $transaction->getCode();
      $account_id = (int) $transaction->getReference();
      if ($account_id <= 0) {
        die('Invalid account reference.');
      }

      $payment_method = $transaction->getPaymentMethod() ? $transaction->getPaymentMethod()->getType()->getTypeFromValue() : 'UNKNOWN';
      $payment_status = $transaction->getStatus() ? $transaction->getStatus()->getTypeFromValue() : 'UNKNOWN';
      $status_value = $transaction->getStatus() ? (int)$transaction->getStatus()->getValue() : 0;
      $request = json_encode($_POST);

      $items = $transaction->getItems();
      $itemId = (!empty($items) && isset($items[0])) ? $items[0]->getId() : null;
      if (!$itemId || !isset($config['pagSeguro']['donates'][$itemId])) {
        log_append('pagseguro_donate_errors.log', date('Y-m-d H:i:s') . ": Unknown item id {$itemId} for tx {$transaction_code}");
        return false;
      }
      $donateSelected = $config['pagSeguro']['donates'][$itemId];

      $stmt = $db->prepare("SELECT * FROM `pagseguro_transactions` WHERE `transaction_code` = :code AND `account_id` = :acc LIMIT 1");
      $stmt->execute([':code' => $transaction_code, ':acc' => $account_id]);
      $transactionDB = $stmt->fetch();

      $createdAt = date('Y-m-d H:i:s');
      $updateAt = date('Y-m-d H:i:s');

      if (!$transactionDB) {
        $bought = (int) $donateSelected['coins'];
        $extra = (int) ($donateSelected['extra'] ?? 0);
        $is_doubled = (int) ($config['pagSeguro']['doubleCoins'] && $bought >= (int) $config['pagSeguro']['doubleCoinsStart']);
        $coins_amount = ($is_doubled === 1 ? $bought * 2 : $bought) + $extra;

        $ins = $db->prepare("INSERT INTO `pagseguro_transactions` (`transaction_code`, `account_id`, `payment_method`, `payment_status`, `code`, `coins_amount`, `bought`, `in_double`, `request`, `created_at`) VALUES (:tcode, :acc, :pmethod, :pstatus, :code, :coins, :bought, :indouble, :req, :created)");
        $ins->execute([
          ':tcode' => $transaction_code,
          ':acc' => $account_id,
          ':pmethod' => $payment_method,
          ':pstatus' => $payment_status,
          ':code' => $donateSelected['id'],
          ':coins' => $coins_amount,
          ':bought' => $bought,
          ':indouble' => $is_doubled,
          ':req' => $request,
          ':created' => $createdAt
        ]);
        $id = (int)$db->lastInsertId();
        $isDelivered = 0;
      } else {
        $id = (int)$transactionDB['id'];
        $coins_amount = (int)$transactionDB['coins_amount'];
        $isDelivered = (int)$transactionDB['delivered'];
      }

      // Check if payment is confirmed: Status 3 (PAID) or Status 4 (AVAILABLE)
      $isPaid = ($payment_status === 'PAID' || $payment_status === 'AVAILABLE' || $status_value === 3 || $status_value === 4);

      if ($isPaid && $isDelivered === 0) {
        // Atomic lock against race conditions: only the request that updates delivered from 0 to 1 will credit the coins
        $lockStmt = $db->prepare("UPDATE `pagseguro_transactions` SET `delivered` = '1', `payment_status` = :pstatus, `payment_method` = :pmethod, `updated_at` = :updated WHERE `id` = :id AND `delivered` = '0'");
        $lockStmt->execute([
          ':pstatus' => $payment_status,
          ':pmethod' => $payment_method,
          ':updated' => $updateAt,
          ':id' => $id
        ]);

        if ($lockStmt->rowCount() > 0) {
          $field = (strtolower($config['pagSeguro']['donationType'] ?? '') === 'coins') ? 'coins' : 'coins_transferable';
          $db->exec("UPDATE `accounts` SET `{$field}` = `{$field}` + {$coins_amount} WHERE `id` = {$account_id}");

          $stmtLog = $db->prepare("INSERT INTO `coins_transactions` (`account_id`, `type`, `amount`, `description`, `timestamp`, `coin_type`) VALUES (:acc, 1, :amount, 'Donate PagSeguro', :tstamp, 3)");
          $stmtLog->execute([
            ':acc' => $account_id,
            ':amount' => $coins_amount,
            ':tstamp' => $updateAt
          ]);

          $timestamp = strtotime($updateAt);
          $stmtStore = $db->prepare("INSERT INTO `store_history` (`account_id`, `mode`, `description`, `coin_type`, `coin_amount`, `time`, `timestamp`, `coins`) VALUES (:acc, 0, 'Donate PagSeguro', 3, :amount, :tstamp, 0, 0)");
          $stmtStore->execute([
            ':acc' => $account_id,
            ':amount' => $coins_amount,
            ':tstamp' => $timestamp
          ]);

          log_append('pagseguro_donate_success.log', date('Y-m-d H:i:s') . ": Account {$account_id} received {$coins_amount} coins (tx: {$transaction_code})");
        }
      } else {
        $upd = $db->prepare("UPDATE `pagseguro_transactions` SET `payment_status` = :pstatus, `payment_method` = :pmethod, `updated_at` = :updated WHERE `id` = :id");
        $upd->execute([
          ':pstatus' => $payment_status,
          ':pmethod' => $payment_method,
          ':updated' => $updateAt,
          ':id' => $id
        ]);

        if ($payment_status === 'CANCELLED' || $status_value === 7) {
          log_append('pagseguro_cancellations.log', date('Y-m-d H:i:s') . ": Transaction {$transaction_code} for Account {$account_id} was cancelled. Status: {$payment_status}");
        }
      }

      echo "OK";
    } catch (PagSeguroServiceException | \Exception $e) {
      log_append('pagseguro_donate_errors.log', date('Y-m-d H:i:s') . ': ' . $e->getMessage());
      http_response_code(500);
      die($e->getMessage());
    }
  }
}
