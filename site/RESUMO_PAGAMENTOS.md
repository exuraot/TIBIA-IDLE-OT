# Resumo das Correções de Segurança e Integração Mercado Pago PIX

Este documento resume todas as correções de segurança aplicadas no sistema de pagamentos existente (PagSeguro) e detalha a nova integração do **PIX Automático Instantâneo com Mercado Pago** implementada no MyAAC.

---

## 1. Blindagem e Correções de Segurança (PagSeguro)

| Vulnerabilidade / Problema | Arquivo Afetado | Correção Aplicada |
| :--- | :--- | :--- |
| **SSL Desativado (Risco MitM)** | `system/libs/PagSeguroLibrary/utils/PagSeguroHttpConnection.class.php` | Ativados `CURLOPT_SSL_VERIFYPEER => true` e `CURLOPT_SSL_VERIFYHOST => 2` para impedir interceptações e manipulações de rede nas chamadas cURL. |
| **URL de Notificação Fictícia (`YOUR_SITE`)** | `system/pages/pagsegurodonate.php`<br>`system/pages/pagsegurobuybox.php` | Removido o placeholder `https://YOUR_SITE/payments/...` e substituído por URL gerada dinamicamente via `BASE_URL . 'payments/...'`. |
| **Falsificação de Referência (Spoofing)** | `system/pages/pagsegurodonate.php`<br>`system/pages/pagsegurobuybox.php` | Exigência obrigatória de autenticação e amarração estrita ao ID da conta logada (`$account_logged->getId()`). Qualquer valor enviado no POST é ignorado. |
| **Exploit de Auto-Ban de Inocentes** | `payments/donate.php`<br>`payments/buybox.php` | Removida a inserção automática em `account_bans` que bania contas de terceiros quando uma transação com ID forjado era cancelada. O evento agora é registrado apenas em logs de auditoria. |
| **Race Condition (Entrega Duplicada de Moedas)** | `payments/donate.php`<br>`payments/buybox.php` | Implementada trava atômica no banco de dados: `UPDATE ... SET delivered = '1' WHERE id = :id AND delivered = '0'`. O crédito das moedas só ocorre se a consulta alterar a linha com exclusividade. |
| **Bloqueio de Boleto, Débito e PIX** | `payments/donate.php` | Corrigida a condição de validação para aceitar qualquer pagamento com status `PAID` (3) ou `AVAILABLE` (4), destravando boletos e transferências que antes eram ignorados. |
| **Injeção de Caracteres em Notificações** | `payments/donate.php`<br>`payments/buybox.php` | Validação estrita por expressão regular `^[A-Za-z0-9\-]+$` sobre o `notificationCode` antes de consultar a API. |
| **Stored XSS no Painel Admin** | `admin/pages/pag_transactions.php` | Todas as variáveis de texto (`transaction_code`, `email`, `players`, `payment_status`) foram protegidas com `htmlspecialchars()`. |

---

## 2. Nova Integração: PIX Automático (Mercado Pago)

### Recursos Implementados:
- **QR Code e Copia e Cola na Tela:** Na rota `?subtopic=pix`, o jogador seleciona o pacote e recebe instantaneamente o QR Code dinâmico e o código Copia e Cola.
- **Botão de Cópia com 1 Clique:** Copia o código PIX para a área de transferência com feedback visual imediato.
- **Confirmação e Entrega em Tempo Real (Polling Assíncrono):** Um script Javascript consulta o status da transação a cada 3 segundos. Assim que o pagamento é aprovado no app do banco, as moedas são creditadas e a tela exibe a confirmação de sucesso sem recarregar a página.
- **Webhook e Validação com a API:** O endpoint `payments/mercadopago.php` consulta diretamente os servidores do Mercado Pago usando o Access Token para validar a transação antes de realizar qualquer entrega.
- **Prevenção de Concorrência:** Entrega protegida por trava atômica contra requisições simultâneas de webhook.
- **Painel Administrativo:** Criada a tela `admin/?p=mp_transactions` para visualizar todas as doações PIX, status, valores e contas beneficiadas.
- **Banner de Divulgação:** Adicionado destaque na página tradicional de doação (`?subtopic=donate`) convidando os jogadores a utilizarem o PIX instantâneo.

---

## 3. Estrutura de Arquivos Criados e Modificados

```
site/
├── admin/
│   ├── pages/
│   │   ├── mp_transactions.php          # [NOVO] Listagem de transações PIX no painel admin
│   │   └── pag_transactions.php         # [MODIFICADO] Proteção contra XSS
│   └── template/
│       └── template.php                 # [MODIFICADO] Adicionado menu "Donates PIX (MP)"
├── payments/
│   ├── buybox.php                       # [MODIFICADO] Blindagem e lock atômico
│   ├── donate.php                       # [MODIFICADO] Blindagem, destravamento de métodos e lock
│   └── mercadopago.php                  # [NOVO] Webhook oficial do Mercado Pago
├── plugins/
│   └── mercadopago/
│       ├── config.php                   # [NOVO] Configuração de tokens, pacotes e valores
│       └── install.sql                  # [NOVO] Esquema da tabela mercadopago_transactions
└── system/
    ├── libs/
    │   ├── MercadoPago/
    │   │   └── MercadoPagoClient.php    # [NOVO] Cliente de comunicação com a API do Mercado Pago
    │   └── PagSeguroLibrary/utils/
    │       └── PagSeguroHttpConnection.class.php  # [MODIFICADO] Ativação de SSL
    ├── pages/
    │   ├── donate.php                   # [MODIFICADO] Suporte a redirecionamento PIX
    │   ├── pagsegurobuybox.php          # [MODIFICADO] Blindagem de conta e URL dinâmica
    │   ├── pagsegurodonate.php          # [MODIFICADO] Blindagem de conta e URL dinâmica
    │   └── pix.php                      # [NOVO] Backend da página de doação PIX e poller
    └── templates/
        ├── donate.html.twig             # [MODIFICADO] Banner de destaque para doação PIX
        └── pix.html.twig                # [NOVO] Interface completa com QR Code e Copia e Cola
```

---

## 4. Passo a Passo para Ativar o PIX em Produção

1. Acesse o Painel de Desenvolvedores do Mercado Pago:  
   👉 [https://www.mercadopago.com.br/developers/panel/app](https://www.mercadopago.com.br/developers/panel/app)
2. Acesse sua aplicação e vá em **Credenciais de Produção**.
3. Copie o seu **Access Token** (inicia com `APP_USR-...`).
4. Abra o arquivo `plugins/mercadopago/config.php` e insira o seu token na linha 12:
   ```php
   'access_token' => 'APP_USR-SEU_ACCESS_TOKEN_AQUI',
   ```
5. Salve o arquivo. O sistema começará a processar pagamentos PIX instantaneamente.
