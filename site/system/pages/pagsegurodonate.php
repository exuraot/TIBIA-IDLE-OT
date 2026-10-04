<?php
global $config, $account_logged, $logged;
/**
 * Automatic PagSeguro payment system gateway.
 *
 * @name      myaac-pagseguro
 * @author    Ivens Pontes <ivenscardoso@hotmail.com>
 * @author    Slawkens <slawkens@gmail.com>
 * @author    Elson <elsongabriel@hotmail.com>
 * @copyright 2023 MyAAC
 */
defined('MYAAC') or die('Direct access not allowed!');
$title = 'Donate with Pagseguro';

if (!$logged || !$account_logged) {
    echo 'To make a donation, you must be logged in. ' . generateLink(getLink('?subtopic=accountmanagement') . '&redirect=' . urlencode(BASE_URL . '?subtopic=donate'), 'Login') . ' first.';
    return;
}

require_once(PLUGINS . 'pagseguro/config.php');
require_once(LIBS . 'PagSeguroLibrary/PagSeguroLibrary.php');

$code = $_POST['code'] ?? null;
if (!$code || !isset($config['pagSeguro']['donates'][$code])) {
    echo 'Please select a valid donation option.';
    return;
}

$paymentRequest = new PagSeguroPaymentRequest();
$donateSelected = $config['pagSeguro']['donates'][$code];
$value = $donateSelected['value'];
$qtd = $donateSelected['coins'];
$double = $config['pagSeguro']['doubleCoins'] && $qtd >= (int)$config['pagSeguro']['doubleCoinsStart'];
$desc = ($double ? $qtd * 2 : $qtd) . " {$config['pagSeguro']['productName']}" . ($double ? "\r\n DOUBLE COINS" : '');

$paymentRequest->addItem($code, $desc, 1, (float)$value);
$paymentRequest->setCurrency("BRL");
// Security: Always bind transaction reference to authenticated account ID, never trust client input
$paymentRequest->setReference((string)$account_logged->getId());
$paymentRequest->setRedirectUrl(BASE_URL . $config['pagSeguro']['urlRedirect']);

$notificationUrl = !empty($config['pagSeguro']['notificationUrl']) 
    ? $config['pagSeguro']['notificationUrl'] 
    : rtrim(BASE_URL, '/') . '/payments/donate.php';
$paymentRequest->addParameter('notificationURL', $notificationUrl);

try {
    $credentials = PagSeguroConfig::getAccountCredentials();
    $checkoutUrl = $paymentRequest->register($credentials);
    header('Location:' . $checkoutUrl);
    exit;
} catch (PagSeguroServiceException $e) {
    log_append('pagseguro_donate_errors.log', date('Y-m-d H:i:s') . ': ' . $e->getMessage());
    echo 'Error processing request with PagSeguro: ' . htmlspecialchars($e->getMessage());
} catch (\Exception $e) {
    log_append('pagseguro_donate_errors.log', date('Y-m-d H:i:s') . ': ' . $e->getMessage());
    echo 'Unexpected error: ' . htmlspecialchars($e->getMessage());
}
