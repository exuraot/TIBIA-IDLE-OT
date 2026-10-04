# Website (MyAAC)

AAC em PHP. Não é o game loop — é conta, char, notícia e **webservice de login do client**.

## Pastas

| Path | Papel |
|---|---|
| `index.php` | Site (template `tibiacom`) |
| `login.php` | JSON do OTClient (`type`: login, news, cacheinfo, …) |
| `account.php` / `clientcreateaccount.php` | Conta |
| `admin/` | Painel |
| `templates/tibiacom/` | Visual Tibia |
| `system/pages/` | Páginas custom |
| `plugins/` | Plugins (ex. PagSeguro) |
| `config.php` | Defaults — **não** editar |
| `config.local.php` | Overrides locais (`server_path`, client 1500) |

`config.local.php` aponta `server_path` para o diretório do Crystal (onde está o `config.lua`). Sem isso o `login.php` não acha IP/porta/compendium.

Banco: se os campos `database_*` em config estiverem vazios, o MyAAC lê o MySQL do `config.lua` do servidor. **Mesmo banco** que o game server.

## Sistema de Doações e Pagamentos

O MyAAC possui suporte a doações com entrega automática de Tibia Coins e Boxes:
- **PIX Automático (Mercado Pago):** Processamento instantâneo via API v1 com QR Code dinâmico e chave Copia e Cola na página (`?subtopic=pix`). Confirmação em tempo real com polling assíncrono e webhook em `payments/mercadopago.php`.
- **PagSeguro Legado:** Módulo blindado com SSL ativo (`CURLOPT_SSL_VERIFYPEER => true`), proteção contra manipulação de referência e entrega com trava atômica em `payments/donate.php` e `payments/buybox.php`.
- **Configuração:**
  - Token Mercado Pago: `site/plugins/mercadopago/config.php`
  - Token PagSeguro: `site/plugins/pagseguro/config.php`
- **Painel Admin:** Acompanhamento de transações em `admin/?p=mp_transactions` (PIX) e `admin/?p=pag_transactions` (PagSeguro).

## Subir

PHP 8 + Apache/Nginx + PDO/MySQL. Instalação MyAAC: `/install` (não versionar `site/install/`).

Client protocol no site: `'client' => 1500` (Tibia 15).

