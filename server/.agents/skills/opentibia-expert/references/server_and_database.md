# Arquitetura do Servidor & Banco de Dados

## 1. Configurações de Performance no `config.lua`

* `maxPlayers = 1000`: Limite de jogadores simultâneos.
* `pushDelay = 1000`: Intervalo de empurrões de itens/jogadores para mitigar lag.
* `stairJumpExhaustion = 2000`: Evita abusos em escadas/buracos.
* `startupDatabaseOptimization = true`: Executa `OPTIMIZE TABLE` na inicialização do MySQL.
* `logLevel = "info"`: Deixar em `info` para produção. Usar `debug` ou `trace` apenas quando investigando bugs complexos.

## 2. Estrutura do Banco de Dados MySQL (`otserv`)

### Tabelas Críticas:
1. `accounts`:
   * `id`: ID da conta
   * `name`: Nome da conta / email
   * `password`: Hash SHA1 da senha
   * `type`: 1 (Player), 2 (Tutor), 3 (Senior Tutor), 4 (Gamemaster), 5 (God)
   * `coins`: Saldo de Tibia Coins da conta
2. `players`:
   * `id`, `name`, `group_id`, `account_id`, `level`, `vocation`, `health`, `mana`, `looktype`, `town_id`, `posx`, `posy`, `posz`
3. `player_storage`:
   * Armazena missões, flags e variáveis de cada jogador (`player_id`, `key`, `value`).
4. `player_items`:
   * Equipamentos do inventário salvos por slot (`pid`), `sid`, `itemtype`, `count`, `attributes`.
5. `houses` & `tile_store`:
   * Casas compradas, donos, aluguel e itens dentro das casas.

## 3. Integração com MyAAC

* O MyAAC lê as tabelas do servidor em tempo real para exibir o Highscores, quem está online (`players_online`), guildas e status do mundo.
* Ao criar uma conta ou personagem pelo MyAAC, ele insere diretamente em `accounts` e `players`, aplicando o `town_id` e itens iniciais (definidos em `system/pages/createcharacter.php` ou plugins).
