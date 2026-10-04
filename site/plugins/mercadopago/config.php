<?php
/**
 * Mercado Pago PIX Payment Gateway for MyAAC.
 *
 * @name      myaac-mercadopago-pix
 * @copyright 2026 MyAAC
 */

$config['mercadoPago'] = [
    // Seu Access Token do Mercado Pago (inicia com APP_USR-...)
    // Obtenha em: https://www.mercadopago.com.br/developers/panel/app
    'access_token'      => '',

    // URL de notificação (webhook). Deixe vazio para usar a detecção automática via BASE_URL.
    'notification_url'  => '',

    // Configurações das moedas
    'productName'       => 'Tibia Coins',
    'donationType'      => 'coins_transferable', // coins_transferable ou coins
    'doubleCoins'       => false,
    'doubleCoinsStart'  => 300,

    // Pacotes de Doação (valor em R$ / moedas entregues / bônus extra)
    'donates'           => [
        '10'   => ['id' => '10',   'value' => 10.00,  'coins' => 100,  'extra' => 0],
        '20'   => ['id' => '20',   'value' => 20.00,  'coins' => 200,  'extra' => 0],
        '30'   => ['id' => '30',   'value' => 30.00,  'coins' => 300,  'extra' => 30],
        '40'   => ['id' => '40',   'value' => 40.00,  'coins' => 400,  'extra' => 40],
        '50'   => ['id' => '50',   'value' => 50.00,  'coins' => 500,  'extra' => 50],
        '100'  => ['id' => '100',  'value' => 100.00, 'coins' => 1000, 'extra' => 150],
    ],

    // Caixas surpresa (Boxes)
    'boxes' => [
        'box_basic' => [
            'id'          => 'box_basic',
            'name'        => 'My Basic Box',
            'value'       => 5.00,
            'image'       => 'box_basic.png',
            'border'      => '#1fc939',
            'description' => 'Box com itens surpresa!',
        ],
    ]
];
