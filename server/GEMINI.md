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
| **OTClient Redemption (Prod)** | `C:\Users\desig\OneDrive\Documentos\Tibia 15\ot client redemption` | - | **Build Estável de Jogador** (DirectX x64, Lua, OTUI, 15.24 Protobuf). |
| **OTClient Redemption (DEV)** | `C:\Users\desig\OneDrive\Documentos\Tibia 15\ot client redemption (dev)` | - | **Ambiente DEV / Testes** com novos módulos (Caçadas IDLE, HUD Banco) para validação. |
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
| 🏹 **Alta** | **Reformulação IDLE HUNT: Respawn Natural, Hotkeys & UI** | 1) Respawn 100% natural do mapa (removido spawn artificial ao redor). 2) Patrulha e aproximação fluida no respawn. 3) Combate, magias (`exura`, `exori`, etc.), poções e runas acionados **estritamente pelas hotkeys ativas do jogador**. 4) Encerramento seguro ("Encerrar Caçada"): contagem de 5s, limpa aggro e battle (`CONDITION_INFIGHT`/`HUNTING`) e teleporta para o templo. 5) Drops reais inseridos diretamente na backpack do jogador e dinheiro creditado diretamente no banco. 6) Seleção de drops: botão `[Lock] Manter` (padrão seguro) vs `[$] Vender` (auto-venda 10m e venda rápida). 7) Eliminação total de mojibake, fontes calibradas em `verdana-11px-rounded` e textos nítidos. | ✅ **Concluído & Online** |
| 📦 **Alta** | **Distribuição Exclusiva do Client DEV no Site (GODs)** | Pacote `Exura_Client_DEV.zip` (260 MB) compilado e hospedado em `/var/www/myaac/downloads/Exura_Client_DEV.zip` com aceleração Nginx. Seção exclusiva de download com badge dourado `[GOD / STAFF ACCESS]` ativada nas páginas `/?account/manage` e `/?downloadclient`, visível unicamente para as contas GOD (`god` / Wolfy, `tarnaph` e contas staff `type >= 4`). Conta `tarnaph` elevada a `type = 5` e `web_flags = 3`. | ✅ **Online & Liberado** |
| 🏹 **Alta** | **Hotkeys IDLE (Gambit Tático), Look no Drops Preview, Target Lock & Padlock UI** | 1) Botão `[IDLE]` no início da action bar para alternar entre Hotkeys Normais e Hotkeys IDLE com glow verde neon `#00ff88`. 2) Menu de contexto com `Assign Spell (IDLE)` e `Assign Object (IDLE)` trazendo gatilhos de condição (`HP <= X%`, `MP <= X%`, `In Combat`) e exibição de custo em GP por uso para poções e runas. 3) Execução tática no loop de combate IDLE com tempos de cooldown respeitados. 4) Look completo dos itens no `Hunt Drops Preview` com atributos reais (Arm, Atk, Def, Peso em oz). 5) Resolução definitiva da sobreposição de botões de nível com larguras fixas calibradas. 6) Target Lock sem troca involuntária de alvo. 7) Remoção de Gold Coin do Loot & Sell (já cai direto no banco). 8) Botão toggle de cadeado `[🔒 LOCKED] Keep` vs `[🔓 UNLOCKED] Sell`. 9) Quick Sell debitando itens reais da backpack e creditando saldo no banco instantaneamente. | ✅ **Concluído & Online** |
| 🧪 **Alta** | **Correção de Sprites de Potions & Suprimento Híbrido IDLE (BP + Banco)** | 1) IDs de itens corrigidos em `IdleActionBar.lua` para os IDs oficiais de `items.xml` (Strong Health `236`, Great Health `239`, Ultimate Health `7643`, Supreme Health `23375`, Mana Potion `268`, Strong Mana `237`, Great Mana `238`, Ultimate Mana `23373`, Great Spirit `7642`, Ultimate Spirit `23374`, Explosion Rune `3200`), exibindo os frascos reais no catálogo e action bar. 2) Desacoplamento da fila de execução no `combatLoop` (`idlehunt.lua`): poções e magias rodam em trilhas independentes e não se canibalizam. 3) Opcode `use_idle_supply` implementado em `idle_hunt_system.lua`: consome da backpack se houver, ou debita o custo em GP diretamente do banco, curando HP/MP com animação `CONST_ME_MAGIC_BLUE`, som e "Aaaah...". 4) Calibração visual dos operadores de gatilho (`>=` para magias ofensivas e `<=` para cura e poções). | ✅ **Concluído & Online** |
| 💰 **Alta** | **Correção Crítica: Quick Sell & Auto-Sell Global e Persistente** | 1) Criação da Tabela Mestre Global `ALL_IDLE_LOOT_ITEMS` varrendo todo o ecossistema IDLE na backpack do player. 2) Persistência de regras (`sell`/`keep`) no banco MariaDB via `player_storage` (`STORAGE_IDLE_LOOT_BASE + itemId`). 3) Eliminação de cooldown quando 0 itens são vendidos (`cooldown: 0`), permitindo destravar itens e tentar novamente de imediato. Cooldown de venda real reduzido para 5 segundos. 4) Alternância visual otimista instantânea (0ms) no botão de cadeado (`[LOCKED] Keep` vs `[UNLOCKED] Sell`). 5) Consulta de Loot & Sell varre a mochila do player mesmo fora de caçadas. | ✅ **Concluído & Online** |
| 🏛️ **Alta** | **Hunts IDLE Instanciadas em 3 Dificuldades & Respawn por Ondas** | 1) Salas instanciadas carregadas nativamente via `idle_rooms.otbm` nas coordenadas modelo: Fácil `(385, 754, 8)`, Médio `(421, 301, 11)`, Difícil `(440, 785, 11)` com ground tiles válidos e sem spawns artificiais sobrepostos. 2) 21 hunts organizadas nas 3 dificuldades com composição exata de ondas (Fácil: 3 monstros, Médio: 4-5 monstros, Difícil: 6-7 monstros) e progressão de criaturas (ex: Dragons -> DLs, Rotworms -> Carrions -> Queens). 3) Respawn contínuo e automático da próxima onda ao limpar a arena com efeitos de teleporte. 4) Limpeza imediata de monstros ativos no encerramento da caçada (`CONST_ME_POFF`), remoção de battle e teleporte ao templo. 5) Interface do client atualizada com abas `Todas`, `🟢 Fácil`, `🟡 Médio`, `🔴 Difícil` e descrição das ondas no card. | ✅ **Concluído & Online** |
| 🏹 **Alta** | **Fase 12: Reformulação Total UI/UX Idle Hunt (Etapas, Recorde XP/h, Tooltip & Instâncias)** | 1) Foco estrito em Caçadas (sem abas extras de treino/quest). 2) Fluxo em 3 telas estilo Tibia Stone: Modo (Organizar Caçada) -> Catálogo (Grid de cards com busca, sprites animados `UICreature` e Recorde) -> Detalhes da Hunt (Pulls Cauteloso/Ousado/Agressivo, Tooltip de Fraquezas/Resistências com 7 elementos, Checkboxes Pegar/Vender). 3) Registro e persistência formal de Recordes de XP/h e GP/h por 10 min de hunt. 4) Eliminação total de mojibake com badges nativos OTUI. | ✅ **Concluído & Online** |
| 🏛️ **Alta** | **Restauração de Templos & Correção de Janela OTUI Idle Hunt** | 1) Identificação e bloqueio de mapas secundários (`toggleMapCustom = false`): carregamento de mapa customizado sobrescrevia o cabeçalho de towns do MariaDB com IDs legados. 2) Restauração de todas as cidades oficiais no banco de dados, fixando Thais (Town ID 8) estritamente em `(32369, 32241, 7)`. 3) Teleporte de `[GOD] Wolfy`, `Druid Sample` e demais samples de volta para o Templo de Thais. 4) Eliminação da tela cinza/vazia do menu: remoção de comentários inválidos `--` em `idlehunt.otui`, inclusão dos estilos `HuntCard`, `ElementBadge` e `DropRowItem`, e correção da carga via `g_ui.displayUI('idlehunt')` em `idlehunt.lua`. 5) Mapeamento seguro das 21 hunts para masmorras temáticas oficiais de `world.otbm` e sync do zip DEV no site. | ✅ **Concluído & Online** |
| 🏹 **Alta** | **Fase 12.1: Correção de Catálogo de Hunts, TipBoxes & Eliminação de Mojibake** | 1) Identificação e correção do crash fatal em `string.trimSpace` que abortava a listagem de hunts no catálogo. 2) Carga do catálogo mestre com todas as 21 hunts completas (ondas, custos, elementos, loot). 3) Criação do widget de estilo nativo `TipBox` inserido no rodapé de todas as 3 telas (Dashboard, Catálogo e Detalhes) com badge dourado `[DICA]`, ícone e texto cyan sem corte. 4) Eliminação total de mojibake nos botões de filtro (`Todas`, `[FACIL] Nivel 8+`, `[MEDIO] Nivel 20+`, `[DIFICIL] Nivel 35+`). 5) Validação de sintaxe via `luac 5.1` e sincronização no zip DEV. | ✅ **Concluído & Online** |
| ⚔️ **Alta** | **Fase 12.2: Instanciação Dinâmica de Arenas & Blindagem Anti-Spawn no Templo** | 1) Resolução do bug de inversão de teleporte: teleporte para (385, 754, 8) falhava silenciosamente por ausência física de ground tile em `world.otbm`, fazendo a invocação de rotworms disparar na posição anterior (Thais). 2) Criação do subsistema `ensureArenaTiles` que constrói dinamicamente em tempo de execução o chão (sand tile 104) e paredes limítrofes (rocks 602) nas 3 coordenadas de arena (`385, 754, 8`, `421, 301, 11`, `440, 785, 11`). 3) Validação estrita do retorno de `player:teleportTo`: se o jogador não estiver na coordenada da arena, a caçada é cancelada e NENHUM monstro é invocado. 4) Trava de proximidade em `spawnHuntWave` bloqueando spawns a mais de 8 sqm da arena. 5) Inicialização nativa no boot do servidor via `GlobalEvent("IdleHuntArenaInit")`. | ✅ **Concluído & Online** |
| 🔒 **Alta** | **Fase 12.3: Desbloqueio Right-Click, Botão Cadeado nos Drops, Auto-Sell 10m & Quick Sell 2m** | 1) Diagnóstico e correção do menu de contexto de itens: exportação formal de `setItemLootRule` e `isItemLocked` para `modules.game_idlehunt`, `idleHuntController` e `_G`. Alternância dinâmica entre "Unlock for Auto-Sell" e "Lock for Auto-Sell" com notificação em tela e persistência no banco. 2) Inclusão do painel de Drops da Sessão na tela de caçada ativa (`huntingCard` / `droppedLootCard`) com scrollbar, sprite `UIItem`, contadores e botão interativo com ícone do cadeado (`/images/game/actionbar/locked.png` vs `unlocked.png`) que alterna instantaneamente com 1 clique. 3) Adição do botão de cadeado também no card de configuração de drops (`DropRowCheckItem`). 4) Widget de `AUTO SELL: 10:00` adicionado na janela ativa com contagem regressiva em tempo real e tooltip informativo. 5) Calibração do cooldown de Quick Sell para 2 minutos (120s) com formatação regressiva `Quick Sell (MM:SS)`. 6) Registro dos eventos `IdleHuntMonsterKill` e `IdleHuntPlayerLogout` no jogador, permitindo contabilização real de drops na backpack, gold no banco e EXP baseada no ganho real de nível. 7) Validação com `luac 5.1`, atualização do pacote `Exura_Client_DEV.zip` e commit no monorepo GitHub. | ✅ **Concluído & Online** |
| ⚔️ **Alta** | **Fase 12.4: Arena Wipe on Death, Mana Potion Fix, Magias/Runas Plug & Play & Popup Flutuante Transparente** | 1) Limpeza total da arena ao morrer via `IdleHuntPlayerDeath` (`clearArenaArea` com `CONST_ME_POFF` e interrupção limpa). 2) Widget flutuante de suprimentos 100% transparente com fonte clássica contornada do Tibia: mostra a poção (`Aaaah... -56 gp`) ou runa (`Avalanche -64 gp`, etc.) em tamanho pequeno flutuando sobre a cabeça. 3) Magias e Runas de ataque 100% Plug & Play: sem condição de porcentagem na hotkey IDLE, disparo periódico (2s) automático no alvo com suporte a suprimento híbrido (mochila ou débito do banco). 4) Auto Loot estrito via `monster:setDropLoot(false)` impedindo coleta involuntária de itens desmarcados (como Meat). 5) Botão `Loot: ON` / `Loot: OFF` calibrado para 74px com alinhamento perfeito. | ✅ **Concluído & Online** |
| 🔑 **Alta** | **Fase 12.6: Correção de Persistência de Login & Remember Password** | Resolução definitiva da falha de restauração de credenciais ao abrir o client: eliminação da declaração duplicada com sombreamento de escopo (`local enterGame`) em `entergame.lua` que deixava a variável como `nil` para `loadSavedAccount`. Adicionada blindagem em `setDefaultServer` preservando login salvo quando `rememberEmailBox` está ativo. Sincronizado nos clients DEV e Prod. | ✅ **Concluído & Validado** |
| 🧭 **Alta** | **Fase 13: Central de Quests, MiniWindow Tracker & GPS Breadcrumbs no Chão** | 1) MiniWindow do Tracker reformulada para o sidebar: layout vertical responsivo sem overlap de botões, exibindo Nome, Alvo/NPC, Etapa, Dica rápida de fala (`Say: "hi" > "mission" > "yes"`) e Bússola em tempo real. 2) Botões adaptáveis: `[GPS: ON/OFF]`, `[X]` (Desafixar) e `[Details]`. 3) Top Banner com bússola e distância. | ✅ **Concluído & Online** |
| 🛠️ **Alta** | **Fase 13.1: Correção do Crash em Quest Details & Projeção Real de Breadcrumbs no Chão** | 1) Resolução da falha de layout `0xC00000FD`: remoção de `fit-children: true` em `ScrollablePanel` duplamente ancorado e eliminação do wrapper `dialogueBox`, utilizando labels auto-ajustáveis (`text-auto-resize: true` e `text-wrap: true`) com caixa estilizada nativa no `dialogueText`. 2) Resolução do erro cíclico `/game_questtracker/questtracker.lua:257: attempt to call method 'getTileRect' (a nil value)`: cálculo matemático vetorial puro de projeção de tela (`cam`, `dim`, `mapRect`, `tileW`, `tileH`) que posiciona os `GpsDot` no piso exato do mapa sem depender de métodos inexistentes na C++ engine. 3) Substituição de `displayStatusConsole` pelo método oficial `displayStatusMessage`. 4) Sincronização nos clients DEV e repositório GitHub. | ✅ **Concluído & Validado** |
| 🧭 **Alta** | **Fase 13.2: Pathfinding A* no Chão, Partículas Suaves Circulares, Radar de Minimapa & Correção de Overlaps UI** | 1) Eliminação total de linhas retas e colisões com edifícios: implementação de pathfinding inteligente com `g_map.findPath`, contornando ruas, muros e obstáculos, desenhando as partículas estritamente em pisos transitáveis (`tile:isWalkable()`). 2) Substituição de caixas quadradas por partículas circulares com brilho suave e transparência (`gps_dot.png`, `gps_beacon.png`), com animação de onda ondulante contínua (`sin(wave)`). 3) Indicador direcional e de distância integrado ao Minimap (`GpsMinimapMarker` + flag 11 + crosshair), projetando o alvo na borda do radar caso esteja distante/outro andar. 4) Ocultação do banner invasivo no topo da tela. 5) Correção de layout: botões do mini-window ajustados sem vazamento para fora da borda (`GPS: ON`, `Info`, `X`), eliminação de miniwindows duplicadas, e delimitação estrita de `npcInfo` no card de quests sem colidir com o botão `Quest Details`. 6) Correção de mojibake (`[Tracking]`). | ✅ **Concluído & Online** |
| 🏝️ **Média** | **Fase 12.5: Ambientação Estética das Arenas IDLE (Ilha com Bordas e Água)** | Reformulação visual do chão e entorno das salas instanciadas com ilha temático-natural, bordas trabalhadas e água ao redor para dar acabamento premium às arenas. | 📋 **A Planejar** |
| 🛡️ **Média** | **Rotina de Backup Automatizada** | Script cron diário no Linux para backup compactado do banco de dados MariaDB (`mysqldump`) e arquivos de casas/jogadores com retenção de 7 dias. | 📋 **A Planejar** |







