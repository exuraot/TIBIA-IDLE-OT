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

## Subir

PHP 8 + Apache/Nginx + PDO/MySQL. Instalação MyAAC: `/install` (não versionar `site/install/`).

Client protocol no site: `'client' => 1500` (Tibia 15).
