# Servidor (Crystal Server)

Fork Canary / Forgotten Server. C++23 em `server/src/`. Entrada: `src/main.cpp` → `CrystalServer().run()`.

## Pastas

| Path | Papel |
|---|---|
| `src/` | Engine C++ |
| `data/` | Core: items, vocations XML, talkactions, stages, spells base |
| `data-global/` | **Datapack ativo**: monstros, NPCs, quests, mapa |
| `data-crystal/` | Datapack alternativo — o servidor **não** usa se `dataPackDirectory = "data-global"` |
| `schema.sql` / `otserv.sql` | Schema MariaDB |
| `start.sh` | Loop Linux; copia `config.lua.dist` → `config.lua` se faltar |
| `crystal_windows_installer.ps1` | Compile no Windows |

`config.lua` é gerado, não versionado. Campos que importam:

- `coreDirectory = "data"`
- `dataPackDirectory = "data-global"`
- `mapName = "world"` → `data-global/world/world.otbm` (Git LFS)
- portas típicas 7171 (login protocol) / 7172 (game)

## Custom Exura (`data-global/scripts/custom/`)

- `idle_hunt_system.lua` — hunts instanciadas
- `trainer_dummy_free.lua` — treino no dummy sem exercise weapon
- `movement_trainer_entrance.lua` / `movement_trainer_exit.lua`
- `ambient_sounds.lua`
- `newhaven/`

Mapas extra: `data-global/world/custom/idle_rooms.otbm` (salas idle).

## Reload (char GOD, sem recompilar)

`/reload scripts` · `/reload monsters` · `/reload spells` · `/reload quests` · `/reload npcs`

Lua nova = RevScript (`local action = Action()` … `:register()`). Não editar XML central pra script novo.

## Subir

- Windows: `server/crystalserver.exe` (não está no git)
- Linux: `./start.sh` ou `systemctl status crystalserver`
- Precisa MariaDB `otserv` no ar
