<?php
global $db, $config;
require_once(PLUGINS . 'mercadopago/config.php');

/**
 * Lista de Donates PIX Mercado Pago
 *
 * @package   MyAAC
 * @copyright 2026 MyAAC
 */
defined('MYAAC') or die('Direct access not allowed!');

if (!$db->hasTable('mercadopago_transactions')) {
    echo '<div class="alert alert-info">A tabela <code>mercadopago_transactions</code> ainda não foi criada. Ela será criada automaticamente assim que o primeiro jogador abrir a página de doação via PIX.</div>';
    return;
}

$count = $db->query("SELECT `id` FROM `mercadopago_transactions` WHERE `status` = 'approved'")->rowCount();
$title = "$count doações PIX aprovadas";
$donates = $db->query("SELECT * FROM `mercadopago_transactions` ORDER BY `id` DESC")->fetchAll();
?>
<div class="row">
    <div class="col-md-12">
        <div class="box">
            <div class="box-header">
                <h3 class="box-title">Transações PIX - Mercado Pago</h3>
            </div>
            <div class="box-body no-padding">
                <table id="tb_mp_donates" class="table table-striped">
                    <thead>
                    <tr>
                        <th style="width: 40px">#</th>
                        <th style="width: 60px">ID</th>
                        <th style="width: 140px;">Payment ID</th>
                        <th>Account & Players</th>
                        <th style="width: 80px; text-align: center">Tipo</th>
                        <th style="width: 160px; text-align: center">Valor / Moedas</th>
                        <th style="width: 90px; text-align: center">Status</th>
                        <th style="width: 70px; text-align: center">Entregue</th>
                        <th style="width: 160px;">Criado em</th>
                    </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($donates as $k => $donate) {
                        $accId = (int)$donate['account_id'];
                        $account = $db->query("SELECT `id`, `email` FROM `accounts` WHERE `id` = {$accId} LIMIT 1;")->fetch();
                        $players = function_exists('getPlayerByAccountId') ? getPlayerByAccountId($accId) : '';
                        $isApproved = ($donate['status'] === 'approved');
                        $bg = $isApproved ? 'style="background-color: #e8f5e9"' : (($donate['status'] === 'cancelled' || $donate['status'] === 'refunded') ? 'style="background-color: #ffebee"' : '');
                        ?>
                        <tr <?= $bg ?>>
                            <td><?= $k + 1 ?></td>
                            <td><?= (int)$donate['id'] ?></td>
                            <td><small><?= htmlspecialchars($donate['payment_id'] ?? '', ENT_QUOTES, 'UTF-8') ?></small></td>
                            <td><?= htmlspecialchars($account['email'] ?? 'Unknown', ENT_QUOTES, 'UTF-8') ?> (<?= htmlspecialchars($players ?? '', ENT_QUOTES, 'UTF-8') ?>)</td>
                            <td style="text-align: center"><?= htmlspecialchars(ucfirst($donate['transaction_type'] ?? 'coins'), ENT_QUOTES, 'UTF-8') ?></td>
                            <td style="text-align: center">
                                R$ <?= number_format((float)$donate['price'], 2, ',', '.') ?>
                                <?php if ($donate['transaction_type'] === 'coins'): ?>
                                    (<?= (int)$donate['coins_amount'] ?> TC)
                                <?php else: ?>
                                    (Box: <?= htmlspecialchars($donate['item_code'] ?? '', ENT_QUOTES, 'UTF-8') ?>)
                                <?php endif; ?>
                            </td>
                            <td style="text-align: center">
                                <span class="label <?= $isApproved ? 'label-success' : 'label-warning' ?>">
                                    <?= htmlspecialchars($donate['status'] ?? 'pending', ENT_QUOTES, 'UTF-8') ?>
                                </span>
                            </td>
                            <td style="text-align: center">
                                <?= $donate['delivered'] ? '<span class="label label-success">Sim</span>' : '<span class="label label-danger">Não</span>' ?>
                            </td>
                            <td><?= htmlspecialchars(date("d/m/Y H:i:s", strtotime($donate['created_at'])), ENT_QUOTES, 'UTF-8') ?></td>
                        </tr>
                    <?php } ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script>
    $(function () {
        if ($.fn.DataTable) {
            $('#tb_mp_donates').DataTable();
        }
    });
</script>
