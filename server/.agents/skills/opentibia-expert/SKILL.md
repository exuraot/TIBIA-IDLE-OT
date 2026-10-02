---
name: opentibia-expert
description: >-
  Master development runbook for OpenTibia (Canary, Crystal Server, TFS), modern Tibia 15 Qt6 client, OTClient (V8/Redemption/Mehah), Protobuf assets (appearances.dat, assets.json), Lua RevScript APIs, map editing (Canary Map Editor/RME), and MyAAC website development. Use whenever the user asks to create, modify, debug, or optimize any aspect of an OTServ server, client, site, database, spells, monsters, NPCs, items, quests, or assets.
---

# OpenTibia 15 & Modern OTServ Expert Development Skill

Este guia é a referência técnica definitiva para o desenvolvimento, manutenção e customização de servidores modernos de OpenTibia (Canary / Crystal Server), clientes modernos (Tibia 15 Qt6 e OTClient), websites (MyAAC) e ferramentas de assets/mapas.

---

## 1. Princípios Fundamentais & Regras Operacionais

1. **Pastas Ativas Sempre em Primeiro Lugar:**
   * **Servidor em execução:** [`C:/otserv/`](file:///C:/otserv/)
   * **Website em execução:** [`C:/xampp/htdocs/`](file:///C:/xampp/htdocs/)
   * **Cliente em uso:** [`C:/Users/desig/OneDrive/Documentos/Tibia 15/client/`](file:///C:/Users/desig/OneDrive/Documentos/Tibia%2015/client/)
   * Pastas em `OneDrive\.../otserv` e `...\site` são réplicas/backups secundários. Nunca edite nelas achando que terá efeito em tempo real.
2. **Padrão RevScript Obrigatório:**
   * Todo script novo (ações, monstros, npcs, spells, movements, quests) deve usar a sintaxe moderna orientada a objetos do RevScript e terminar com `:register()`.
   * **Nunca** adicione entradas em arquivos XML legados (como `actions.xml` ou `spells.xml`) para scripts que já possuem classes RevScript.
3. **Hot-Reloading In-Game (`/reload`):**
   * Evite reiniciar o executável `crystalserver.exe` para alterações de scripts ou dados.
   * Sempre teste e oriente o uso dos comandos de reload pelo personagem GOD.

---

## 2. Fluxos Rápidos de Desenvolvimento

### A. Criar ou Modificar Monstro
* **Local:** [`C:/otserv/data-global/monster/`](file:///C:/otserv/data-global/monster/) (organizado por subpastas: `bosses/`, `demons/`, `dragons/`, etc.).
* **Estrutura Básica:**
  ```lua
  local mType = Game.createMonsterType("Custom Demon")
  local monster = {}

  monster.description = "a custom demon"
  monster.experience = 7500
  monster.outfit = { lookType = 35 }
  monster.health = 10000
  monster.maxHealth = 10000
  monster.race = "fire"
  monster.corpse = 5995
  monster.speed = 150

  monster.changeTarget = { interval = 4000, chance = 20 }
  monster.flags = {
      summonable = false,
      attackable = true,
      hostile = true,
      canPushItems = true,
      canPushCreatures = true,
      targetDistance = 1,
      staticAttackChance = 70
  }

  monster.attacks = {
      { name = "melee", interval = 2000, chance = 100, minDamage = -200, maxDamage = -450 },
      { name = "combat", interval = 2000, chance = 20, type = COMBAT_FIREDAMAGE, minDamage = -150, maxDamage = -350, range = 7, shootEffect = CONST_ANI_FIRE, effect = CONST_ME_FIREAREA }
  }

  monster.defenses = {
      defense = 40,
      armor = 40,
      { name = "combat", interval = 2000, chance = 15, type = COMBAT_HEALING, minDamage = 200, maxDamage = 400, effect = CONST_ME_MAGIC_BLUE }
  }

  monster.elements = {
      { type = COMBAT_FIREDAMAGE, percent = 100 },
      { type = COMBAT_ICEDAMAGE, percent = -10 }
  }

  monster.immunities = {
      { type = "paralyze", condition = true },
      { type = "invisible", condition = true }
  }

  monster.loot = {
      { id = 3031, chance = 100000, maxCount = 100 }, -- gold coin
      { id = 3035, chance = 80000, maxCount = 10 },   -- platinum coin
      { id = 3386, chance = 500 }                     -- dragon scale mail
  }

  mType:register(monster)
  ```
* **Aplicar:** Salvar o arquivo e rodar `/reload monsters` in-game.

---

### B. Criar Nova Magia ou Runa
* **Local Magias Instantâneas:** [`C:/otserv/data/scripts/spells/`](file:///C:/otserv/data/scripts/spells/) ou [`C:/otserv/data-global/scripts/spells/`](file:///C:/otserv/data-global/scripts/spells/)
* **Local Runas:** [`C:/otserv/data/scripts/spells/runes/`](file:///C:/otserv/data/scripts/spells/runes/)
* **Estrutura Magia Instantânea:**
  ```lua
  local combat = Combat()
  combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
  combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_FIREAREA)

  local area = createCombatArea(AREA_CROSS5X5)
  combat:setArea(area)

  function onGetFormulaValues(player, level, maglevel)
      local min = (level / 5) + (maglevel * 3) + 20
      local max = (level / 5) + (maglevel * 5) + 40
      return -min, -max
  end
  combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

  local spell = Spell("instant")
  function spell.onCastSpell(creature, var)
      return combat:execute(creature, var)
  end

  spell:name("Inferno Burst")
  spell:words("exevo gran mas flam hur")
  spell:group("attack")
  spell:level(60)
  spell:mana(200)
  spell:cooldown(4 * 1000)
  spell:groupCooldown(2 * 1000)
  spell:isPremium(true)
  spell:vocation("sorcerer;true", "master sorcerer;true")
  spell:register()
  ```
* **Aplicar:** Salvar e rodar `/reload spells` in-game.

---

### C. Criar Quest / Baú de Recompensa
* **Local:** [`C:/otserv/data-global/scripts/quests/`](file:///C:/otserv/data-global/scripts/quests/)
* **Estrutura:**
  ```lua
  local config = {
      storageKey = 65001,
      rewardItemId = 3389, -- Demon Armor
      rewardCount = 1,
      actionId = 45001     -- ID colocado no baú via Map Editor
  }

  local questChest = Action()
  function questChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
      if player:getStorageValue(config.storageKey) >= 1 then
          player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
          return true
      end

      local itemType = ItemType(config.rewardItemId)
      player:addItem(config.rewardItemId, config.rewardCount)
      player:setStorageValue(config.storageKey, 1)
      player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. itemType:getName() .. "!")
      player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
      return true
  end

  questChest:aid(config.actionId)
  questChest:register()
  ```
* **Aplicar:** Salvar e rodar `/reload quests` ou `/reload scripts`.

---

### D. Criar / Modificar NPC
* **Local:** [`C:/otserv/data-global/npc/`](file:///C:/otserv/data-global/npc/)
* **Estrutura:**
  ```lua
  local internalNpcName = "Mercador"
  local npcType = Game.createNpcType(internalNpcName)
  local npcConfig = {}

  npcConfig.name = internalNpcName
  npcConfig.description = internalNpcName
  npcConfig.health = 100
  npcConfig.maxHealth = 100
  npcConfig.walkInterval = 2000
  npcConfig.walkRadius = 2
  npcConfig.outfit = { lookType = 128 }

  -- Sistema de Compra e Venda (Shop)
  npcConfig.shop = {
      { itemName = "magic light wand", clientId = 3046, buy = 400 },
      { itemName = "rope", clientId = 3003, buy = 50, sell = 15 }
  }

  local keywordHandler = KeywordHandler:new()
  local npcHandler = NpcHandler:new(keywordHandler)

  npcType.onThink = function(npc, interval) npcHandler:onThink(npc, interval) end
  npcType.onAppear = function(npc, creature) npcHandler:onAppear(npc, creature) end
  npcType.onDisappear = function(npc, creature) npcHandler:onDisappear(npc, creature) end
  npcType.onMove = function(npc, creature, fromPos, toPos) npcHandler:onMove(npc, creature, fromPos, toPos) end
  npcType.onSay = function(npc, creature, type, message) npcHandler:onSay(npc, creature, type, message) end

  npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)
  npcType:register(npcConfig)
  ```
* **Aplicar:** Salvar e rodar `/reload npcs`.

---

### E. Comandos de Jogador & GOD (Talkactions)
* **Comandos de Jogadores:** [`C:/otserv/data/scripts/talkactions/player/`](file:///C:/otserv/data/scripts/talkactions/player/)
* **Comandos de GOD/GM:** [`C:/otserv/data/scripts/talkactions/god/`](file:///C:/otserv/data/scripts/talkactions/god/)
* **Estrutura:**
  ```lua
  local talk = TalkAction("!bless")
  function talk.onSay(player, words, param)
      if player:hasBlessing(1) then
          player:sendCancelMessage("You are already blessed.")
          return false
      end
      player:addBlessing(1, 1)
      player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You received the blessings!")
      return false
  end
  talk:separator(" ")
  talk:register()
  ```

---

## 3. Gestão do Cliente Tibia 15 & OTClient

### Tibia 15 Oficial (Qt6 / WebEngine)
* **Localização:** [`C:/Users/desig/OneDrive/Documentos/Tibia 15/client/`](file:///C:/Users/desig/OneDrive/Documentos/Tibia%2015/client/)
* **Executável:** `bin/client.exe`
* **Assets:**
  * `appearances.dat` (Google Protobuf binário) -> Define IDs, outfits, sprites e atributos visuais.
  * `assets.json` -> Catálogo com hashes SHA256 de cada recurso gráfico LZMA.
  * `conf/clientoptions.json` -> Configurações gráficas, atalhos e interface.
* **Autenticação:** O cliente consome o webservice `login.php` via JSON enviando credenciais e recebendo a lista de mundos e o token de sessão para a conexão TCP 7172.

### OTClient (V8 / Redemption / Mehah)
* **Interface (.otui):** Linguagem declarativa baseada em blocos e ancoragem (anchors).
  * Exemplo: `Button; id: btnClose; anchors.top: parent.top; text: Fechar`
* **Lógica (.lua):** Módulos em `modules/`, manipulando eventos com `connect()`, `disconnect()` e opcodes estendidos (`g_game.sendExtendedOpcode(opcode, buffer)`).

---

## 4. Gestão de Mapas e Sprites

* **Editor de Mapas (Canary Map Editor):**
  * Abre [`C:/otserv/data-global/world/world.otbm`](file:///C:/otserv/data-global/world/world.otbm).
  * Requer a base `datspr/datspr/Tibia.dat` e `Tibia.spr`.
  * Spawns e Casas salvos automaticamente em `world-monster.xml`, `world-npc.xml` e `world-house.xml`.
* **Editor de Sprites (Assets Editor):**
  * Utilizado para carregar `appearances.dat` e `assets.json`.
  * Permite importar novos sprites PNG, registrar novos IDs e exportar sincronizado para o servidor (`C:\otserv\data\items\appearances.dat`) e para o cliente.

---

## 5. Website MyAAC & Banco de Dados

* **Diretório Ativo:** [`C:/xampp/htdocs/`](file:///C:/xampp/htdocs/)
* **Arquivo de Configuração:** [`C:/xampp/htdocs/config.local.php`](file:///C:/xampp/htdocs/config.local.php)
  * Aponta para `$config['server_path'] = 'C:/otserv/';`
  * Versão do cliente: `$config['client'] = '1500';`
* **Autenticação do Cliente:** [`C:/xampp/htdocs/login.php`](file:///C:/xampp/htdocs/login.php)
* **Banco MySQL:**
  * Base: `otserv` (Porta 3306)
  * Usuário: `root` (sem senha)
  * Tabelas de Contas: `accounts`, `players`, `myaac_*`.

---

## 6. Documentação Detalhada de Referência

Consulte os guias aprofundados sempre que necessário:
* [RevScript API Cheatsheet](./references/revscript_cheatsheet.md)
* [Cliente & Assets Protobuf](./references/client_and_assets.md)
* [Servidor & Banco de Dados](./references/server_and_database.md)
* [Diagnóstico & Hot-Reloading](./references/troubleshooting_and_reload.md)
