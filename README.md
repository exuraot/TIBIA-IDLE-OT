# Exura OT - TIBIA IDLE OT

Repositório unificado de desenvolvimento do ecossistema **Exura OT**, englobando Servidor (Crystal Server C++23), Website (MyAAC) e Cliente (OTClient Redemption).

---

## 📁 Estrutura do Repositório

```text
TIBIA-IDLE-OT/
├── server/           # Servidor de Jogo (Crystal Server C++23 / Lua RevScript)
│   ├── config.lua    # Configurações do servidor (rates, conexão, portas)
│   ├── data/         # Core data (XMLs, talkactions, spells base)
│   ├── data-global/  # Datapack global (monstros, npcs, quests, world.otbm)
│   └── src/          # Código-fonte C++23 completo do servidor
│
├── site/             # Website Oficial e AAC (MyAAC)
│   ├── config.local.php # Configurações locais do MyAAC
│   ├── system/       # Sistema central e páginas customizadas
│   └── templates/    # Templates visuais (tibiacom)
│
└── client/           # Cliente Oficial Customizado (OTClient Redemption 4.1)
    ├── Exura Client.exe # Executável nativo DirectX x64
    ├── data/         # UI Styles, fontes, shaders e assets
    ├── modules/      # Módulos Lua e interfaces (login, HUD, inventory)
    └── src/          # Código-fonte C++20 do cliente
```

---

## ⚙️ Tecnologias & Requisitos

* **Game Server:** Crystal Server (Canary fork) C++23, vcpkg, Protobuf 15.24, MariaDB 10.11 / MySQL.
* **Website:** MyAAC 0.8.25, PHP 8.x, Apache/Nginx.
* **Client:** OTClient Redemption 4.1 (DirectX x64, Lua 5.1, Protobuf 15.24).
* **Git LFS:** O arquivo de mapa `server/data-global/world/world.otbm` utiliza Git LFS. Certifique-se de executar `git lfs install` ao clonar.

---

## 🚀 Como Executar

### 1. Clonando o Repositório
```bash
git clone https://github.com/exuraot/TIBIA-IDLE-OT.git
cd TIBIA-IDLE-OT
git lfs pull
```

### 2. Iniciando o Servidor
* No Windows: Execute `server/crystalserver.exe`.
* No Linux VPS: O serviço é gerenciado via `systemd` (`systemctl status crystalserver`).

### 3. Iniciando o Cliente
* Execute `client/Exura Client.exe`. O cliente já vem configurado e apontando para o servidor e webservice ativos.

---

## 📖 Wiki
Documentação do monorepo: [wiki/Home.md](wiki/Home.md).

## 🔒 Regras de Branch e Desenvolvimento
* Todos os novos módulos (Caçadas IDLE, Treiners Livres, Modais) devem ser desenvolvidos em branches de feature e submetidos via Pull Request.
