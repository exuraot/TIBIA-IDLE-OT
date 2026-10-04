<?php
global $config, $account_logged, $logged;
/**
 * Automatic PagSeguro payment system gateway.
 *
 * @name      myaac-pagseguro
 * @author    Elson <elsongabriel@hotmail.com>
 * @copyright 2023 MyAAC
 */
defined('MYAAC') or die('Direct access not allowed!');
$title = 'Buy Box with Pagseguro';

if (!$logged || !$account_logged) {
    echo 'To buy a surprise box, you must be logged in. ' . generateLink(getLink('?subtopic=accountmanagement') . '&redirect=' . urlencode(BASE_URL . '?subtopic=boxes'), 'Login') . ' first.';
    return;
}

require_once(PLUGINS . 'pagseguro/config.php');
require_once(LIBS . 'PagSeguroLibrary/PagSeguroLibrary.php');

$code = $_POST['code'] ?? null;
if (!$code || !isset($config['pagSeguro']['boxes'][$code])) {
    echo 'Please select a valid box.';
    return;
}

$boxSelected = $config['pagSeguro']['boxes'][$code];
$paymentRequest = new PagSeguroPaymentRequest();
$paymentRequest->addItem($code, $boxSelected['name'], 1, (float)$boxSelected['value']);
$paymentRequest->setCurrency("BRL");
// Security: Always bind transaction reference to authenticated account ID, never trust client input
$paymentRequest->setReference((string)$account_logged->getId());
$paymentRequest->setRedirectUrl(BASE_URL . $config['pagSeguro']['urlRedirect']);

$notificationUrl = !empty($config['pagSeguro']['notificationUrl']) 
    ? $config['pagSeguro']['notificationUrl'] 
    : rtrim(BASE_URL, '/') . '/payments/buybox.php';
$paymentRequest->addParameter('notificationURL', $notificationUrl);

try {
    $credentials = PagSeguroConfig::getAccountCredentials();
    $checkoutUrl = $paymentRequest->register($credentials);
    header('Location:' . $checkoutUrl);
    exit;
} catch (PagSeguroServiceException $e) {
    log_append('pagseguro_buybox_errors.log', date('Y-m-d H:i:s') . ': ' . $e->getMessage());
    echo 'Error processing request with PagSeguro: ' . htmlspecialchars($e->getMessage());
} catch (\Exception $e) {
    log_append('pagseguro_buybox_errors.log', date('Y-m-d H:i:s') . ': ' . $e->getMessage());
    echo 'Unexpected error: ' . htmlspecialchars($e->getMessage());
}
