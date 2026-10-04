<?php
/**
 * Automatic PagSeguro payment system gateway.
 *
 * @name      myaac-pagseguro
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
  !count($config['pagSeguro']['boxes'])
) {
  echo "PagSeguro is disabled. If you're an admin please configure this script in config.local.php.";
  return;
}

header('access-control-allow-origin: https://pagseguro.uol.com.br');

$table = 'myaac_send_items';
$method = $_SERVER['REQUEST_METHOD'];
if ('post' == strtolower($method)) {
  $type = $_POST['notificationType'] ?? null;
  $notificationCode = $_POST['notificationCode'] ?? null;

  if ($type === 'transaction' && !empty($notificationCode)) {
    // Validate notification code pattern to prevent URL manipulation / SSRF
    if (!preg_match('/^[A-Za-z0-9\-]+$/', $notificationCode)) {
      log_append('pagseguro_buybox_errors.log', date('Y-m-d H:i:s') . ': Invalid notificationCode format: ' . $notificationCode);
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
      if (!$itemId || !isset($config['pagSeguro']['boxes'][$itemId])) {
        log_append('pagseguro_buybox_errors.log', date('Y-m-d H:i:s') . ": Unknown box id {$itemId} for tx {$transaction_code}");
        return false;
      }
      $boxSelected = $config['pagSeguro']['boxes'][$itemId];

      $stmt = $db->prepare("SELECT * FROM `{$table}` WHERE `transaction_code` = :code AND `account_id` = :acc LIMIT 1");
      $stmt->execute([':code' => $transaction_code, ':acc' => $account_id]);
      $transactionDB = $stmt->fetch();

      $createdAt = date('Y-m-d H:i:s');
      $updateAt = date('Y-m-d H:i:s');

      if (!$transactionDB) {
        $ins = $db->prepare("INSERT INTO `{$table}` (`transaction_code`, `item_id`, `item_name`, `item_count`, `account_id`, `payment_method`, `payment_status`, `status`, `request`, `created_at`) VALUES (:tcode, :item_id, :item_name, 1, :acc, :pmethod, :pstatus, '0', :req, :created)");
        $ins->execute([
          ':tcode' => $transaction_code,
          ':item_id' => $boxSelected['id'],
          ':item_name' => $boxSelected['name'],
          ':acc' => $account_id,
          ':pmethod' => $payment_method,
          ':pstatus' => $payment_status,
          ':req' => $request,
          ':created' => $createdAt
        ]);
        $id = (int)$db->lastInsertId();
        $currentStatus = '0';
      } else {
        $id = (int)$transactionDB['id'];
        $currentStatus = (string)$transactionDB['status'];
      }

      // Check if payment is confirmed: Status 3 (PAID) or Status 4 (AVAILABLE)
      $isPaid = ($payment_status === 'PAID' || $payment_status === 'AVAILABLE' || $status_value === 3 || $status_value === 4);

      if ($isPaid && $currentStatus === '0') {
        // Atomic lock against race conditions: only update if status is '0'
        $lockStmt = $db->prepare("UPDATE `{$table}` SET `status` = '1', `payment_status` = :pstatus, `payment_method` = :pmethod, `updated_at` = :updated WHERE `id` = :id AND `status` = '0'");
        $lockStmt->execute([
          ':pstatus' => $payment_status,
          ':pmethod' => $payment_method,
          ':updated' => $updateAt,
          ':id' => $id
        ]);

        if ($lockStmt->rowCount() > 0) {
          log_append('pagseguro_buybox_success.log', date('Y-m-d H:i:s') . ": Box {$boxSelected['name']} approved for Account {$account_id} (tx: {$transaction_code})");
        }
      } else {
        $upd = $db->prepare("UPDATE `{$table}` SET `payment_status` = :pstatus, `payment_method` = :pmethod, `updated_at` = :updated WHERE `id` = :id");
        $upd->execute([
          ':pstatus' => $payment_status,
          ':pmethod' => $payment_method,
          ':updated' => $updateAt,
          ':id' => $id
        ]);

        if ($payment_status === 'CANCELLED' || $status_value === 7) {
          log_append('pagseguro_cancellations.log', date('Y-m-d H:i:s') . ": Box transaction {$transaction_code} for Account {$account_id} was cancelled. Status: {$payment_status}");
        }
      }

      echo "OK";
    } catch (PagSeguroServiceException | \Exception $e) {
      log_append('pagseguro_buybox_errors.log', date('Y-m-d H:i:s') . ': ' . $e->getMessage());
      http_response_code(500);
      die($e->getMessage());
    }
  }
}
