# Mods do cliente

Pasta `mods/` no OTClient (no git: `client/` não inclui `mods/` neste snapshot; a pasta jogável `ot client redemption (dev)/mods` sim).

Carrega **depois** de `modules/` (`autoLoadModules(9999)`). README: igual modules, só pra plugin.

| Pasta | Função |
|---|---|
| `client_mods` | Loader; ordem: profiles → buttons → itemselector → textedit → game_bot |
| `client_profiles` | 10 perfis `/settings/profile_N` |
| `client_textedit` | Janela de editar texto |
| `game_buttons` | Miniwindow de botões (host de ícones) |
| `game_itemselector` | Picker de item |
| `game_bot` | Bot OTCv8 (cavebot / vBot). **Não** é o idle hunt da Exura |
| `game_tasks` | UI de tasks, opcode JSON **215**, atalho Ctrl+A. Lua server de exemplo em `serverSIDE/` |

Idle Hunt **não** mora aqui — está em `modules/game_idlehunt`.

Todos `sandboxed: true`.
