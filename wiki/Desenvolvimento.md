# Desenvolvimento

Feature nova (idle, trainer, modal) → branch → **Pull Request**. Não commit direto na `main` com módulo novo.

## O que entra no git

- Lua/PHP/C++/OTUI
- `world.otbm` via **Git LFS** (`git lfs install` + `git lfs pull`)

## O que não entra

- `*.exe`, `.pdb`, build/
- `server/config.lua` (gerar de `config.lua.dist`)
- `site/cache/`, `site/install/`
- logs

## Sync do live → repo

`sync_repo.ps1` (paths do PC original): `c:\otserv` → `server/`, `c:\xampp\htdocs` → `site/`, pasta OTClient → `client/`.

Editar o **live** se o servidor estiver rodando de `C:\otserv`. Este clone é o versionado.

## Reload vs compile

| Mudança | Precisa |
|---|---|
| Lua RevScript / XML datapack | `/reload …` in-game |
| PHP do site | refresh / restart php-fpm |
| Lua do client (`modules/`) | relogar ou reload de módulo |
| C++ `server/src` ou `client/src` | recompilar o `.exe` |

## Wiki

Fonte: pasta `wiki/` neste repo (Home + sidebar). O GitHub Wiki (`.wiki.git`) deste org ainda não foi inicializado — até lá a documentação é esses arquivos no git.
