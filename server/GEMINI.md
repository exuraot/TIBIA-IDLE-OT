# Tibia 15 - Ecossistema & Mapa de Arquivos (Memória Permanente da IA)

> Este arquivo é a fonte da verdade operacional para o ecossistema Tibia 15. Sempre consulte as rotas e convenções abaixo antes de propor alterações.

---

## 1. Visão Geral das Pastas & Componentes

| Componente | Localização Real (Ativa / Em Execução) | Localização Secundária / Backup | Descrição |
|---|---|---|---|
| **Servidor (OTServ)** | `C:\otserv` | `C:\Users\desig\OneDrive\Documentos\Tibia 15\otserv` | **Crystal Server** (Canary fork) em C++ e Lua (RevScript). Executável: `crystalserver.exe`. |
| **Website (AAC)** | `C:\xampp\htdocs` | `C:\Users\desig\OneDrive\Documentos\Tibia 15\site` | **MyAAC 0.8.25** integrado ao MySQL e ao client web login. |
| **Web Server & Banco** | `C:\xampp` | - | Apache (`httpd.exe`), MySQL/MariaDB (`mysqld.exe`), phpMyAdmin. |
| **Cliente Oficial** | `C:\Users\desig\OneDrive\Documentos\Tibia 15\client` | - | **Tibia 15.24** (`client.exe` + Qt6 / WebEngine + Protobuf assets). |
| **OTClient Redemption** | `C:\Users\desig\OneDrive\Documentos\Tibia 15\ot client redemption` | - | **OTClient Redemption 4.1** (DirectX x64, Lua, OTUI, 15.24 Protobuf). |
| **Editor de Mapa** | `C:\Users\desig\OneDrive\Documentos\Tibia 15\Mapa Editor` | - | **Canary Map Editor** (`canary-map-editor.exe`) com `datspr` compatível. |
| **Editor de Sprites** | `C:\Users\desig\OneDrive\Documentos\Tibia 15\sprite editor` | - | **Assets Editor** (`Assets Editor.exe` Protobuf) para `appearances.dat` e `assets.json`. |
| **Repositório GitHub (Monorepo)** | `C:\Users\desig\OneDrive\Documentos\Tibia 15\TIBIA-IDLE-OT` | `https://github.com/exuraot/TIBIA-IDLE-OT` | **TIBIA-IDLE-OT** contendo `/server`, `/site` e `/client` versionados com Git LFS (`world.otbm`). |

> [!WARNING]
> **REGRA DE OURO DAS PASTAS:**
> Sempre edite os arquivos em `C:\otserv` e `C:\xampp\htdocs` para alterar o servidor e site ativos.
> As pastas dentro de `OneDrive\Documentos\Tibia 15\otserv` e `\site` são cópias secundárias.

---

## 2. Configurações de Conexão & Banco de Dados

* **Banco de Dados:** MySQL / MariaDB (Porta 3306)
  * **Database:** `otserv`
  * **Usuário:** `root`
  * **Senha:** *(sem senha / vazia)*
  * **Host:** `127.0.0.1` / `localhost`
* **Configuração Central do Servidor:** `C:\otserv\config.lua`
  * `dataPackDirectory = "data-global"`
  * `coreDirectory = "data"`
  * `mapName = "world"` (Lê `C:\otserv\data-global\world\world.otbm`)
  * `ip = "127.0.0.1"`
* **Configuração Central do Site:** `C:\xampp\htdocs\config.local.php`
  * `$config['server_path'] = 'C:/otserv/';`
  * `$config['client'] = '1500';`
  * `$config['date_timezone'] = 'America/Sao_Paulo';`
* **Painel Administrativo Web (MyAAC Admin Panel):** `http://187.7.16.210/admin/`
  * Contas liberadas com Super Admin (`web_flags = 3`): `god`, `gilrosa`, `DaleteBitz`.
  * Recursos: Gerenciamento de contas, promoção de players a GM/GOD, adição de Tibia Coins, bans e notícias.
* **Gerenciador de Banco de Dados Web (Adminer / MySQL):** `http://187.7.16.210/admin/adminer.php`
  * **Sistema:** `MySQL` | **Servidor:** `localhost` | **Database:** `otserv`
  * **Usuário:** `otserv` | **Senha:** `tibia15_secure_db_pass`
* **Login do Cliente Web:** `C:\xampp\htdocs\login.php`

---

## 3. Mapa Rápido de Onde Alterar Cada Coisa

### Servidor (`C:\otserv`)
* **Monstros (1.783 arquivos):** `C:\otserv\data-global\monster\`
  * Subpastas: `bosses`, `demons`, `dragons`, `undeads`, etc.
  * Formato: RevScript Lua (ex: `monster = MonsterType("Demon") ... monster:register()`).
* **NPCs (1.103 arquivos):** `C:\otserv\data-global\npc\`
  * Formato: RevScript Lua.
* **Magias e Runas (632 arquivos):** `C:\otserv\data-global\scripts\spells\` e `C:\otserv\data\scripts\spells\`
  * Runas: `data\scripts\spells\runes\`
  * Magias de cura, ataque, suporte: `data-global\scripts\spells\`
* **Quests e Missões (1.025 scripts):** `C:\otserv\data-global\scripts\quests\`
* **Ações e Alavancas (Actions):** `C:\otserv\data-global\scripts\actions\`
* **Movimentos (Pisos, Portas, Portais):** `C:\otserv\data-global\scripts\movements\`
* **Scripts Customizados:** `C:\otserv\data-global\scripts\custom\`
* **Comandos de Jogadores e GOD / GM:** `C:\otserv\data\scripts\talkactions\`
  * Comandos de GOD: `data\scripts\talkactions\god\` (`/reload`, `/i`, `/s`, etc.)
  * Comandos de Jogador: `data\scripts\talkactions\player\` (`!bless`, `!autoloot`, `!house`, etc.)
* **Mapa do Mundo:** `C:\otserv\data-global\world\`
  * Arquivo `.otbm`: `world.otbm`
  * Spawns de Monstros: `world-monster.xml`
  * Spawns de NPCs: `world-npc.xml`
  * Casas: `world-house.xml`
* **Itens e Atributos:**
  * Definições XML de Itens: `C:\otserv\data\items\items.xml`
  * Protobuf Appearances: `C:\otserv\data\items\appearances.dat`
* **Vocations, Outfits, Mounts:** `C:\otserv\data\XML\`
  * `vocations.xml`, `outfits.xml`, `mounts.xml`, `familiars.xml`, `events.xml`.

---

### Site (`C:\xampp\htdocs`)
* **Configurações Gerais:** `C:\xampp\htdocs\config.local.php`
* **Templates / Visual:** `C:\xampp\htdocs\templates\tibiacom\`
* **Páginas Customizadas:** `C:\xampp\htdocs\system\pages\`
* **Plugins do Site:** `C:\xampp\htdocs\plugins\`
* **Painel Administrativo:** `C:\xampp\htdocs\admin\`

---

### Cliente & Editores
* **Cliente Tibia 15.24:** `C:\Users\desig\OneDrive\Documentos\Tibia 15\client`
  * Executável: `bin\client.exe`
  * Configurações de Opções: `conf\clientoptions.json`
  * Assets & Sprites: `assets\` e `assets.json`
* **Canary Map Editor:** `C:\Users\desig\OneDrive\Documentos\Tibia 15\Mapa Editor`
  * Executável: `canary-map-editor.exe`
  * Base de sprites: `datspr\datspr\Tibia.dat` e `Tibia.spr`
* **Assets / Sprite Editor:** `C:\Users\desig\OneDrive\Documentos\Tibia 15\sprite editor`
  * Executável: `Assets Editor.exe`

---

## 4. Convenções e Boas Práticas de Desenvolvimento

1. **Recarregamento sem reiniciar o servidor (`/reload`):**
   * Com o personagem GOD no jogo, utilize comandos como `/reload scripts`, `/reload monsters`, `/reload spells`, `/reload quests`, `/reload npcs`.
2. **RevScript Moderno:**
   * Novos scripts devem usar a sintaxe moderna de RevScript (`local spell = Spell("instant")`, `local action = Action()`, etc.) e chamar `:register()` ao final, sem necessidade de editar arquivos XML centrais.
3. **Persistência de Dados:**
   * Sempre garanta transações limpas ou queries com prepared statements no MySQL.
4. **Validação e Diagnóstico Rigoroso Antes da Conclusão (Regra de Ouro):**
   * Nunca declarar uma tarefa ou fase como concluída sem antes testar a execução real ponta a ponta, inspecionar minuciosamente os arquivos de log (`otclient.log`, `crystalserver.log`, queries do banco) e verificar que não há avisos ou erros em tempo de execução.

---

## 5. Skill Especializada Ativa: `opentibia-expert`

Toda a lógica e runbooks avançados para desenvolvimento no servidor, cliente Qt6 / OTClient, website MyAAC e assets estão consolidados na skill:
* **Arquivo da Skill:** `C:\Users\desig\.gemini\config\skills\opentibia-expert\SKILL.md`
* **Módulos de Referência:**
  * `references\revscript_cheatsheet.md` (APIs RevScript completas: MonsterType, NpcType, Spell, Action, MoveEvent, CreatureEvent, GlobalEvent)
  * `references\client_and_assets.md` (Tibia 15 Qt6, Protobuf appearances.dat, assets.json, OTClient OTUI)
  * `references\server_and_database.md` (Configurações do servidor e schema MySQL)
  * `references\troubleshooting_and_reload.md` (Guia de hot-reload e solução de erros)

---

## 6. Roadmap Pós-Ativação (Próximos Passos & Tarefas)

| Prioridade | Meta / Tarefa | Descrição & Ação Técnica | Status |
|---|---|---|---|
| 🟢 **Alta** | **Correção de Menus Duplicados no Site** | Investigação comprovou duplicação de registros na tabela `myaac_menu` no MariaDB da VPS (`count(*) = 2`). Executada deduplicação SQL direta. | ✅ **Resolvido** |
| 🚀 **Alta** | **Game Server 24/7 Compilado e Ativo** | Compilação nativa Linux (C++23/GCC 13, vcpkg, Unity Build, LTO) do Crystal Server finalizada. Serviço `systemd` ativo nas portas `7171` e `7172` com auto-restart. | ✅ **Online 24/7** |
| 🚀 **Alta** | **Cliente 100% Nativo no "Downloads"** | Modificação binária definitiva no `client.exe` trocando `127.0.0.1` por `187.7.16.210`. Cliente zipado e limpo (388 MB) hospedado em `/var/www/myaac/downloads/Exura_Client.zip` com aceleração `sendfile`. Integrado na página oficial `/?downloadclient`, barra superior e em todos os links (ícone, botão e link "here") dentro de `/?account/manage`. | ✅ **Disponível no Site** |
| ⚡ **Alta** | **Otimização de Desempenho (Site & Client Login)** | Diagnóstico do `client.log` revelou loop de retries na rota `news` por ausência de `compendium.json`. Criado arquivo e ajustado `login.php`. No Nginx, ativado cache estático de 30 dias (eliminando ~60 requests 304 por clique), compressão Gzip (redução de 91% no payload de 102KB para 8.9KB), `skip-name-resolve` no MariaDB e fallbacks para imagens 404. | ✅ **Otimizado** |
| 🎨 **Alta** | **Rebranding Oficial & Nova Identidade Visual (Exura)** | Nome do servidor alterado para **Exura** em `config.lua`, MariaDB (`status_motd`), título das páginas (`Exura`), rodapé (`EXURA - All rights reserved`), atalho do cliente (`Jogar Exura.bat`) e link de download oficial (`Exura_Client.zip`). Novo logo 3D dourado **EXURA OT SERVER** instalado no header com dimensões calibradas, link CipSoft ocultado, novo favicon multi-resolução gerado a partir do brasão 3D **EX** com fundo transparente anti-aliasing e textos legados de "Tibia/CipSoft" substituídos em termos, criação de contas e leilão. | ✅ **Concluído** |
| ⚡ **Alta** | **Calibração de Rates & Stages (Padrão RubiniOT)** | Configuração de 16 faixas de EXP (50x a 1.2x), Skills (10x a 2x), Magic Level (10x a 2x) em `data/stages.lua`, bônus/penalidade de Stamina (+50% em 42h-39h, 100% em 38:59h-14h, -50% abaixo de 14h), `lowLevelBonusExp = 0`, suporte a float no MyAAC (`serverinfo`) e sincronização ativa no servidor Linux. | ✅ **Concluído** |
| 🔒 **Média** | **Domínio Próprio & Certificado SSL (HTTPS)** | Apontamento de DNS de domínio customizado para o IP `187.7.16.210` e emissão de certificado Let's Encrypt com Nginx. | 📋 **A Planejar** |
| ⚔️ **Alta** | **Ativação do OTClient Redemption** | Executável nativo DirectX x64 integrado como `Exura Client.exe`, assets 15.24 vinculados em `data/things/1524`, métodos incompatíveis com a engine 4.1 protegidos (`setClickSound`/`addSound`), inicialização validada ponta a ponta (`loadModules` 100% limpo), apontando para `http://187.7.16.210/login.php` na porta 80 e protocolo 1524. | ✅ **Validado & Funcional** |
| 🎮 **Alta** | **Build Dedicado de Jogador (Exura Client)** | Interface de login simplificada e limpa (removidos Servidor, Versão e HTTP Login), mantendo apenas Acc Name/Email, Senha, Lembrar e Auto-login. Adicionado botão direto "Create Account" para registro no site, ativação funcional do contador ao vivo de Players Online no topo, ativação dos painéis de Criatura e Boss Boosted diários no rodapé, e isolamento de ferramentas de desenvolvedor (Terminal, Debug Info, OTUI Editor, Sound Debug) com chave `DEV_MODE`. | ✅ **Concluído & Validado** |
| 🌐 **Alta** | **Repositório Unificado GitHub (TIBIA-IDLE-OT)** | Repositório oficial monorepo criado em `https://github.com/exuraot/TIBIA-IDLE-OT` sincronizando `/server`, `/site` e `/client` com Git LFS configurado para arquivos grandes (`world.otbm` 185 MB) e `.gitignore` para descartar binários temporários/debug e zips. | ✅ **Publicado no GitHub** |
| ⚔️ **Alta** | **Treiners Clássicos Livres no Dummy** | Ação de clique direito em qualquer dummy (`trainer_dummy_free.lua`) para treino contínuo na taxa padrão de monstro com a arma e escudo equipados, sem gastar exercise weapons. Limpeza limpa no logout/movimentação. | ✅ **Concluído & Online** |
| 💰 **Alta** | **HUD de Saldo Bancário em Tempo Real** | Módulo `game_bankbalance` integrado ao client abaixo de equips/store, comunicando via opcode estendido `105` e sincronizado reativamente a depósitos, saques, transferências e caçadas. | ✅ **Concluído & Online** |
| 🏹 **Alta** | **Sistema de Caçadas IDLE Instanciadas** | Engine completa (`idle_hunt_system.lua` + `game_idlehunt`) com 14 hunts em 7 faixas (1 a 300+), Stamina IDLE (dreno 3x mais lento), débito de suprimentos direto do banco, comparador de requisitos e ejeção de emergência aos 10% de HP para jogadores equipados. | ✅ **Concluído & Online** |
| 🛠️ **Alta** | **Correção de Inicialização do Cliente (Crash ao Abrir)** | Diagnóstico identificou crash nativo C++ provocado por dupla descriptografia em `EnterGame.setUniqueServer` repassando string plaintext (`god@exura.com`) para `g_crypt.decrypt` e dependência circular de âncora no scrollbar em `idlehunt.otui`. Implementada validação base64 em `safeDecrypt`, desacoplamento de decrypt redundante e recalibração de âncoras. Ambos os clients (`prod` e `dev`) validados abrindo perfeitamente com 0 erros. | ✅ **Resolvido & Sincronizado** |
| 🛡️ **Média** | **Rotina de Backup Automatizada** | Script cron diário no Linux para backup compactado do banco de dados MariaDB (`mysqldump`) e arquivos de casas/jogadores com retenção de 7 dias. | 📋 **A Planejar** |

