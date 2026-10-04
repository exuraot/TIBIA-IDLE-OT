<?php
/**
 * Mercado Pago API Client for PIX Payments.
 *
 * @name      MercadoPagoClient
 * @copyright 2026 MyAAC
 */

class MercadoPagoClient
{
    const API_BASE_URL = 'https://api.mercadopago.com';

    /**
     * Create a PIX payment on Mercado Pago.
     *
     * @param string $accessToken
     * @param float $amount
     * @param string $description
     * @param string $email
     * @param int $accountId
     * @param string $notificationUrl
     * @param string $externalReference
     * @return array
     * @throws Exception
     */
    public static function createPixPayment(
        $accessToken,
        $amount,
        $description,
        $email,
        $accountId,
        $notificationUrl,
        $externalReference
    ) {
        if (empty($accessToken)) {
            throw new Exception("Mercado Pago Access Token não está configurado.");
        }

        $url = self::API_BASE_URL . '/v1/payments';

        $payerEmail = filter_var($email, FILTER_VALIDATE_EMAIL) ? $email : 'player_' . $accountId . '@tibia-idle.com';

        $payload = [
            'transaction_amount' => (float)number_format((float)$amount, 2, '.', ''),
            'description'        => mb_substr($description, 0, 100),
            'payment_method_id'  => 'pix',
            'payer'              => [
                'email'      => $payerEmail,
                'first_name' => 'Account',
                'last_name'  => (string)$accountId,
            ],
            'external_reference' => (string)$externalReference,
        ];

        if (!empty($notificationUrl)) {
            $payload['notification_url'] = $notificationUrl;
        }

        $idempotencyKey = self::generateUuid();

        $headers = [
            'Authorization: Bearer ' . trim($accessToken),
            'Content-Type: application/json',
            'X-Idempotency-Key: ' . $idempotencyKey,
            'User-Agent: MyAAC-MercadoPago-Pix/1.0'
        ];

        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL            => $url,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_HTTPHEADER     => $headers,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_TIMEOUT        => 30,
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($curlError) {
            throw new Exception("Erro de conexão cURL com Mercado Pago: " . $curlError);
        }

        $data = json_decode($response, true);
        if (!$data || !is_array($data)) {
            throw new Exception("Resposta inválida do Mercado Pago: HTTP {$httpCode}");
        }

        if ($httpCode !== 200 && $httpCode !== 201) {
            $msg = $data['message'] ?? ($data['error'] ?? 'Erro desconhecido');
            if (!empty($data['cause']) && is_array($data['cause'])) {
                $causes = [];
                foreach ($data['cause'] as $c) {
                    $causes[] = ($c['description'] ?? json_encode($c));
                }
                $msg .= ' (' . implode(', ', $causes) . ')';
            }
            throw new Exception("Falha ao gerar PIX no Mercado Pago (HTTP {$httpCode}): " . $msg);
        }

        $txData = $data['point_of_interaction']['transaction_data'] ?? [];

        return [
            'id'             => (string)$data['id'],
            'status'         => (string)($data['status'] ?? 'pending'),
            'status_detail'  => (string)($data['status_detail'] ?? ''),
            'amount'         => (float)$data['transaction_amount'],
            'qr_code'        => (string)($txData['qr_code'] ?? ''),
            'qr_code_base64' => (string)($txData['qr_code_base64'] ?? ''),
            'ticket_url'     => (string)($txData['ticket_url'] ?? ''),
            'raw'            => $data,
        ];
    }

    /**
     * Retrieve payment information from Mercado Pago API.
     *
     * @param string $accessToken
     * @param string|int $paymentId
     * @return array
     * @throws Exception
     */
    public static function getPayment($accessToken, $paymentId)
    {
        if (empty($accessToken)) {
            throw new Exception("Mercado Pago Access Token não está configurado.");
        }

        $paymentId = preg_replace('/[^0-9]/', '', (string)$paymentId);
        if (empty($paymentId)) {
            throw new Exception("ID de pagamento inválido.");
        }

        $url = self::API_BASE_URL . '/v1/payments/' . $paymentId;
        $headers = [
            'Authorization: Bearer ' . trim($accessToken),
            'Content-Type: application/json',
            'User-Agent: MyAAC-MercadoPago-Pix/1.0'
        ];

        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL            => $url,
            CURLOPT_HTTPGET        => true,
            CURLOPT_HTTPHEADER     => $headers,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_TIMEOUT        => 20,
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($curlError) {
            throw new Exception("Erro de conexão cURL com Mercado Pago: " . $curlError);
        }

        $data = json_decode($response, true);
        if (!$data || !is_array($data)) {
            throw new Exception("Resposta inválida do Mercado Pago: HTTP {$httpCode}");
        }

        return $data;
    }

    /**
     * Generate standard UUID v4.
     *
     * @return string
     */
    private static function generateUuid()
    {
        $data = random_bytes(16);
        $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
        $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
    }
}
