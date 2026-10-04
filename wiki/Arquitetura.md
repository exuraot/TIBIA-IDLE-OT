# Arquitetura

Quatro peças. O PHP **não** simula o jogo.

```
MariaDB (otserv)
    ↑         ↑
site/login.php     crystalserver  :7171 / :7172
    ↑                     ↑
    └──── OTClient ───────┘
         HTTP login          TCP game
```

## Login

1. Client abre. `client/init.lua` POSTa JSON em `login.php` (`type: login`).
2. PHP valida email/senha em `accounts`, lista `players`, lê `ip` + `gameProtocolPort` do `config.lua` do servidor.
3. Devolve `session` + chars + mundo.
4. Player escolhe o char. Client abre **TCP** no game server.
5. Servidor carrega o player do MySQL e coloca no mapa `data-global/world/world.otbm`.

Outros `type` do mesmo `login.php`: `news`, `cacheinfo` (players online), `eventschedule`, `boostedcreature`.

## Opcodes custom (client ↔ servidor)

| Opcode | Uso | Server | Client |
|---|---|---|---|
| 105 | Saldo bancário | `data/libs/functions/player.lua` | `modules/game_bankbalance` |
| 106 | Idle hunt | `data-global/scripts/custom/idle_hunt_system.lua` | `modules/game_idlehunt` |
| 215 | Tasks (mod OTC, JSON) | exemplo em `mods/game_tasks/serverSIDE/` | `mods/game_tasks` — **não** é o idle da Exura |

## Runtime vs git

| Git (este repo) | Processo vivo (setup original) |
|---|---|
| `server/` | `C:\otserv\crystalserver.exe` ou `systemd` na VPS |
| `site/` | `C:\xampp\htdocs` ou Nginx |
| `client/` (sem `.exe`) | pasta OTClient com `Exura Client.exe` |

`sync_repo.ps1` só copia o live → este repo. Não é o jeito de subir o jogo.
