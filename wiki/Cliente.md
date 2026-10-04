# Cliente (OTClient Redemption)

Protocolo **1524**. Fonte C++ em `client/src/`. UI em Lua/OTUI.

O `.exe` **não** está neste git. A pasta jogável (com binário) no setup local é `ot client redemption (dev)` — `modules/` é o mesmo snapshot.

## Boot

`Exura Client.exe` → `init.lua`:

1. `Services.status` = URL do `login.php`
2. `Servers_init` — protocol 1524, `httpLogin = true`
3. Search path: `data/` → `modules/` → `mods/`
4. `g_modules.autoLoadModules` por prioridade
5. `otclientrc.lua` no fim

`DEV_MODE` em `init.lua`: `false` = sem terminal/OTUI editor/debug. `true` liga as ferramentas.

## Pastas

| Path | Papel |
|---|---|
| `init.lua` | Login HTTP, protocol, load order |
| `modules/` | HUD do jogo (sempre carregado) |
| `mods/` | Plugins OTC (bot, tasks, profiles) — [página](Mods-do-Cliente) |
| `data/things/1524/` | Assets 15.24 |
| `src/` | Engine; muda só no próximo compile |

Módulos Exura em `modules/`:

- `game_idlehunt` — UI das hunts
- `game_bankbalance` — saldo
- `game_actionbar/logics/IdleActionBar.lua` — hotkeys IDLE

Lua em `modules/` muda **sem** recompilar o `.exe`.

## Assets

Contrato (ver `client/AGENTS.md`): runtime em `data/things/<version>/`, não mover a fonte da verdade para `client-assets/`.
