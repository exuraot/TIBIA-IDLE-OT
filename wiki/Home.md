# Exura OT — Wiki

Monorepo do **Exura OT** (Tibia 15.24 idle): servidor Crystal, site MyAAC e OTClient Redemption.

| Pasta | Peça | Stack |
|---|---|---|
| [`server/`](Servidor) | Mundo, combate, Lua | Crystal Server C++23, RevScript, MariaDB |
| [`site/`](Website) | Contas, login web, AAC | MyAAC 0.8.25, PHP 8 |
| [`client/`](Cliente) | O que o player abre | OTClient Redemption 4.1, protocol 1524 |

**Clone**

```bash
git clone https://github.com/exuraot/TIBIA-IDLE-OT.git
cd TIBIA-IDLE-OT
git lfs pull   # mapa world.otbm
```

Binários (`.exe`) e `server/config.lua` **não** vão no git. Sem eles esta pasta é código, não o processo vivo.

## Páginas

- [Arquitetura](Arquitetura) — 3 processos e o fluxo de login
- [Servidor](Servidor) — datapack, reload, custom
- [Website](Website) — MyAAC e `login.php`
- [Cliente](Cliente) — boot, modules, DEV_MODE
- [Idle Hunt](Idle-Hunt) — caçadas instanciadas
- [Mods do cliente](Mods-do-Cliente) — pasta `mods/`
- [Mapa de arquivos](Mapa-de-Arquivos) — onde mudar cada coisa
- [Desenvolvimento](Desenvolvimento) — branch, PR, sync

## O que este OT adiciona em cima do Crystal

- Caçadas IDLE instanciadas (opcode 106)
- HUD de banco em tempo real (opcode 105)
- Dummy de treino livre (`trainer_dummy_free.lua`)
