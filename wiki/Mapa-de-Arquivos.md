# Mapa de arquivos

Onde mexer. Datapack ativo = `data-global`.

## Servidor

| Quero mudar | Path |
|---|---|
| Rates / stages | `server/data/stages.lua` + `config.lua` (não versionado) |
| Monstros | `server/data-global/monster/` |
| NPCs | `server/data-global/npc/` |
| Magias / runas | `server/data-global/scripts/spells/` e `server/data/scripts/spells/` |
| Quests | `server/data-global/scripts/quests/` |
| Actions / alavancas | `server/data-global/scripts/actions/` |
| Pisos / portas / portais | `server/data-global/scripts/movements/` |
| Custom Exura | `server/data-global/scripts/custom/` |
| Comandos GOD | `server/data/scripts/talkactions/god/` |
| Comandos player | `server/data/scripts/talkactions/player/` |
| Mapa | `server/data-global/world/world.otbm` (LFS) |
| Spawns | `world-monster.xml` / `world-npc.xml` / `world-house.xml` |
| Itens | `server/data/items/items.xml` + `appearances.dat` |
| Vocations / outfits / mounts | `server/data/XML/` |

## Site

| Quero mudar | Path |
|---|---|
| Config local | `site/config.local.php` |
| Visual | `site/templates/tibiacom/` |
| Páginas | `site/system/pages/` |
| Login do client | `site/login.php` |
| Admin | `site/admin/` |

## Client

| Quero mudar | Path |
|---|---|
| URL/protocolo de login | `client/init.lua` |
| Idle hunt UI | `client/modules/game_idlehunt/` |
| Hotkeys IDLE | `client/modules/game_actionbar/logics/IdleActionBar.lua` |
| HUD banco | `client/modules/game_bankbalance/` |
| Tela de login | `client/modules/client_entergame/` |
| Sprites 15.24 | `client/data/things/1524/` |
