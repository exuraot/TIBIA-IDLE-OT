# RevScript API Cheatsheet (Canary / Crystal Server)

Este documento contém todos os construtores, eventos e métodos do RevScript para OpenTibia moderno.

---

## 1. Action (`Action()`)
Utilizado para alavancas, baús, itens utilizáveis com botão direito ou "Use With".

```lua
local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- player: Player object
    -- item: Item object sendo usado
    -- fromPosition: Position de onde o item foi usado
    -- target: Thing/Creature/Item clicado (se Use With)
    -- toPosition: Position do target
    -- isHotkey: boolean se foi via hotkey

    if item.itemid == 1945 then
        item:transform(1946)
    elseif item.itemid == 1946 then
        item:transform(1945)
    end
    return true
end

-- Formas de registro:
action:id(1945, 1946) -- Registra por ItemID
action:aid(45000)     -- Registra por ActionID
action:uid(50000)     -- Registra por UniqueID
action:register()
```

---

## 2. MoveEvent (`MoveEvent()`)
Pisos especiais, portais, portas de level e equipamentos ao vestir/despir.

```lua
local move = MoveEvent()

function move.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return true
    end

    if player:getLevel() < 100 then
        player:teleportTo(fromPosition, true)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Apenas level 100+ podem passar.")
        return true
    end

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Bem-vindo à área VIP!")
    return true
end

move:aid(45001)
move:register()
```

Equip / De-equip:
```lua
local equip = MoveEvent()
function equip.onEquipItem(player, item, slot, isCheck)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Item equipado.")
    return true
end
equip:id(2472)
equip:slot(CONST_SLOT_ARMOR)
equip:register()
```

---

## 3. CreatureEvent (`CreatureEvent()`)
Ganchos em criaturas ou jogadores: login, logout, morte, dano recebido/causado.

```lua
local event = CreatureEvent("CustomLoginReward")

function event.onLogin(player)
    player:registerEvent("CustomLoginReward")
    player:sendTextMessage(MESSAGE_LOGIN, "Bem-vindo ao servidor Tibia 15!")
    return true
end

event:register()
```

Outros callbacks comuns:
* `onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)`
* `onPrepareDeath(creature, killer)`
* `onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)`
* `onAdvance(player, skill, oldLevel, newLevel)`

---

## 4. GlobalEvent (`GlobalEvent()`)
Execuções agendadas, crons e loops temporais.

```lua
local global = GlobalEvent("ServerBroadcast")

function global.onTime(interval)
    Game.broadcastMessage("Visite nosso site para notícias e novidades!", MESSAGE_STATUS_WARNING)
    return true
end

global:time("12:00:00") -- Hora específica
-- OU: global:interval(60 * 1000) -- Intervalo de 60 segundos
global:register()
```

---

## 5. Spell (`Spell("instant")` e `Spell("rune")`)

Parâmetros de combate úteis:
```lua
COMBAT_PARAM_TYPE: COMBAT_PHYSICALDAMAGE, COMBAT_ENERGYDAMAGE, COMBAT_EARTHDAMAGE, COMBAT_FIREDAMAGE, COMBAT_ICEDAMAGE, COMBAT_HOLYDAMAGE, COMBAT_DEATHDAMAGE
COMBAT_PARAM_EFFECT: CONST_ME_FIREAREA, CONST_ME_HITBYFIRE, CONST_ME_MORTAREA, CONST_ME_HOLYAREA, etc.
COMBAT_PARAM_DISTANCEEFFECT: CONST_ANI_FIRE, CONST_ANI_ENERGY, CONST_ANI_SNIPERARROW, etc.
```

Áreas padrão:
`AREA_CROSS5X5`, `AREA_CIRCLE3X3`, `AREA_WAVE4`, `AREA_BEAM7`, etc.

---

## 6. Métodos Essenciais de Jogador (`Player`)
* `player:addItem(itemId, count, canDropOnMap, subType)`
* `player:removeItem(itemId, count)`
* `player:getItemCount(itemId)`
* `player:getStorageValue(key)` / `player:setStorageValue(key, value)`
* `player:teleportTo(position, pushMove)`
* `player:sendTextMessage(messageType, text)`
* `player:sendCancelMessage(text)`
* `player:addExperience(exp, sendText)`
* `player:addMoney(amount)` / `player:removeMoney(amount)`
* `player:getPosition()` -> Retorna objeto `Position(x, y, z)`
