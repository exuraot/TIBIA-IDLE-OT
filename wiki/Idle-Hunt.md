# Idle Hunt

Caçadas instanciadas. O **servidor** spawna sala e ondas; o **client** escolhe hunt, anda, gasta hotkey IDLE e mostra loot.

## Arquivos

| Lado | Path |
|---|---|
| Server | `server/data-global/scripts/custom/idle_hunt_system.lua` |
| Salas | `server/data-global/world/custom/idle_rooms.otbm` |
| Client UI | `client/modules/game_idlehunt/` |
| Hotkeys IDLE | `client/modules/game_actionbar/logics/IdleActionBar.lua` |

Opcode **106** (JSON). Ações: `get_hunts`, `get_requirements`, `start_hunt`, `stop_hunt`, `get_hunt_loot`, `set_loot_rule`, `quick_sell`, `use_idle_supply`, `teleport_temple`, `teleport_house`.

## Salas modelo

| Dificuldade | Coordenada |
|---|---|
| Fácil | `(385, 754, 8)` |
| Médio | `(421, 301, 11)` |
| Difícil | `(440, 785, 11)` |

Hunts definidas na tabela `IDLE_HUNTS` no Lua do servidor (waves, loot, requisitos). Client tem catálogo fallback; o server manda a lista real.

## Regras atuais

- Respawn por ondas na sala instanciada (não spawn artificial no mapa aberto)
- Combate/poções/magias pelas **hotkeys IDLE** (botão `[IDLE]` na action bar)
- Encerrar: 5s, limpa infight, templo
- Gold vai pro banco; itens na backpack
- Loot: Lock = manter / Unlock = vender; persistido em `player_storage` (`STORAGE_IDLE_LOOT_BASE + itemId`)
- Stamina IDLE: storage `95000`, dreno mais lento que hunt normal
- Ejeção ~10% HP
- Suprimento: BP primeiro, senão debita GP do banco (`use_idle_supply`)

Banco no HUD: opcode **105**, módulo `game_bankbalance`.
