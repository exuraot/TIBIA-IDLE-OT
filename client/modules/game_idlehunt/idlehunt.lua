g_ui.importStyle('idlehunt_styles')

local OPCODE_IDLE_HUNT = 106

local idleButton = nil
local DEFAULT_HUNTS_CATALOG = {
    { id = 1, name = "Rotworms de Darashia", tier = "1 - 20", level = 8, focus = "Balanced", desc = "Classic hunt with Rotworms and Carrion Worms. Ideal starting spot.", cost = 10, req_lvl = 8, looktype = 26 },
    { id = 2, name = "Larvas & Scarabs de Ankrahmun", tier = "1 - 20", level = 15, focus = "More EXP", desc = "Larvas and Scarabs under the desert sands of Ankrahmun.", cost = 25, req_lvl = 15, looktype = 73 },
    { id = 3, name = "Skeletons & Ghouls de Drefia", tier = "20 - 40", level = 22, focus = "Balanced", desc = "Undead catacombs with fast respawns and good gold drops.", cost = 40, req_lvl = 22, looktype = 100 },
    { id = 4, name = "Cyclopolis de Edron", tier = "20 - 40", level = 30, focus = "More EXP", desc = "High density of Cyclopes, Drones, and Smiths inside the volcano.", cost = 60, req_lvl = 30, looktype = 22 },
    { id = 5, name = "Yalahar Cults (Magician Quarter)", tier = "40 - 80", level = 45, focus = "More Loot", desc = "Acolytes and Adepts dropping creature products, gold and rare ropes.", cost = 95, req_lvl = 45, looktype = 194 },
    { id = 6, name = "Wyrms de Liberty Bay", tier = "40 - 80", level = 65, focus = "Balanced", desc = "Electric dragons on Vandura mountain. Good balance of XP and loot.", cost = 140, req_lvl = 65, looktype = 291 },
    { id = 7, name = "Giant Spiders das Plains of Havoc", tier = "80 - 130", level = 80, focus = "More Loot", desc = "Fast ambush predators dropping Knight Armors and Silk.", cost = 190, req_lvl = 80, looktype = 38 },
    { id = 8, name = "Sea Serpents de Svargrond", tier = "80 - 130", level = 100, focus = "More EXP", desc = "Underwater high-density EXP heaven for knights and paladins.", cost = 240, req_lvl = 100, looktype = 305 },
    { id = 9, name = "Medusa & Serpent Spawns (Banuta)", tier = "130 - 200", level = 135, focus = "More Loot", desc = "Deep underground jungle ruins packed with petrifying gorgons.", cost = 350, req_lvl = 135, looktype = 330 },
    { id = 10, name = "Draken Walls de Zao", tier = "130 - 200", level = 170, focus = "More EXP", desc = "High-tier Draconian citadel with massive AoE pulls and heavy loot.", cost = 460, req_lvl = 170, looktype = 339 },
    { id = 11, name = "Roshamuul Valley (Frazzlemaws)", tier = "200 - 250", level = 200, focus = "More Loot", desc = "Nightmarish valley crawling with Silencers and Frazzlemaws.", cost = 650, req_lvl = 200, looktype = 594 },
    { id = 12, name = "Nightmare Isle", tier = "200 - 250", level = 230, focus = "More EXP", desc = "Surreal rift filled with Choking Fears and Grim Reapers.", cost = 820, req_lvl = 230, looktype = 584 },
    { id = 13, name = "Falcon Bastion", tier = "250+", level = 260, focus = "Balanced", desc = "Holy order knights with massive physical damage and plate armor drops.", cost = 980, req_lvl = 260, looktype = 1071 },
    { id = 14, name = "Issavi Sphinxes & Crypt Wardens", tier = "250+", level = 290, focus = "More EXP", desc = "Ancient desert colossi with extreme damage and massive reward rates.", cost = 1200, req_lvl = 290, looktype = 1204 }
}
local huntsCache = DEFAULT_HUNTS_CATALOG
local activeFilter = "all"
local selectedHuntId = 1
local reqWindow = nil
local currentView = "hunts"
local inHunt = false
local currentHuntId = 0
local huntCenterPos = nil

local currentWaypoints = {}
local currentWaypointIndex = 1
local waypointLastPos = nil
local waypointStuckTime = 0

local quickSellCooldownTimer = 0
local quickSellEvent = nil
local autoCombatEvent = nil
local stopCountdownEvent = nil
local lastLootData = nil
local itemRulesCache = {}

-- Combat cooldowns
local lastHealTime = 0
local lastPotionTime = 0
local lastAttackSpellTime = 0
local lastRuneTime = 0
local lastWanderTime = 0

local function formatNumber(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

idleHuntController = {}

-- Safe backpack right-click loot rule toggler
local function setItemLootRule(itemId, rule)
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end

    local id = tonumber(itemId)
    if not id then return end
    itemRulesCache[id] = rule

    local buffer = string.format('{"action":"set_loot_rule","item_id":%d,"rule":%q}', id, rule)
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, buffer)

    local msg = (rule == "keep")
        and string.format("Item #%d [LOCKED]: Kept safe in backpack.", id)
        or string.format("Item #%d [UNLOCKED]: Marked for Auto-Sell.", id)

    if modules.game_textmessage and modules.game_textmessage.displayStatusMessage then
        modules.game_textmessage.displayStatusMessage(msg)
    else
        print("[Idle Hunt] " .. msg)
    end
end

local function isItemLocked(itemId)
    local id = tonumber(itemId)
    if not id then return true end
    local r = itemRulesCache[id]
    if r == nil then return true end
    return (r == "keep")
end

idleHuntController.setItemLootRule = setItemLootRule
idleHuntController.isItemLocked = isItemLocked

if modules and modules.game_idlehunt then
    modules.game_idlehunt.setItemLootRule = setItemLootRule
    modules.game_idlehunt.isItemLocked = isItemLocked
end

function idleHuntController:init()
    self:onInit()
end

function idleHuntController:terminate()
    self:onTerminate()
end

function idleHuntController:onInit()
    ProtocolGame.registerExtendedOpcode(OPCODE_IDLE_HUNT, function(protocol, opcode, buffer)
        self:onOpcodeReceived(buffer)
    end)

    self.ui = g_ui.displayUI('idlehunt')
    self.ui:hide()

    if modules.client_topmenu then
        idleButton = modules.client_topmenu.addLeftGameButton(
            'idleHuntTopButton',
            tr('Idle Hunts'),
            '/images/topbuttons/cooldowns',
            function() self:toggle() end
        )
    end

    connect(g_game, {
        onGameStart = function()
            self:requestHunts()
            -- Retry after extended opcode handshake (opcode 0) is guaranteed active
            scheduleEvent(function() self:requestHunts() end, 800)
            scheduleEvent(function() self:requestHunts() end, 2200)
        end,
        onGameEnd = function()
            self:stopAutoCombat()
            if stopCountdownEvent then
                removeEvent(stopCountdownEvent)
                stopCountdownEvent = nil
            end
            if quickSellEvent then
                removeEvent(quickSellEvent)
                quickSellEvent = nil
            end
            if self.dropsWindow then
                self.dropsWindow:destroy()
                self.dropsWindow = nil
            end
        end,
    })

    self:bindButtons()
end

function idleHuntController:onTerminate()
    ProtocolGame.unregisterExtendedOpcode(OPCODE_IDLE_HUNT)
    if idleButton then
        idleButton:destroy()
        idleButton = nil
    end
    if self.ui then
        self.ui:destroy()
        self.ui = nil
    end
    if reqWindow then
        reqWindow:destroy()
        reqWindow = nil
    end
    if self.dropsWindow then
        self.dropsWindow:destroy()
        self.dropsWindow = nil
    end
    self:stopAutoCombat()
    if stopCountdownEvent then
        removeEvent(stopCountdownEvent)
        stopCountdownEvent = nil
    end
    if quickSellEvent then
        removeEvent(quickSellEvent)
        quickSellEvent = nil
    end
end

function idleHuntController:bindButtons()
    if not self.ui then return end

    local topBar = self.ui.topActionBar
    if topBar then
        topBar.navHuntsButton.onClick = function() self:showView("hunts") end
        topBar.navLootButton.onClick = function() self:showView("loot") end
        topBar.teleportHouseButton.onClick = function() self:teleportHouse() end
        topBar.teleportTempleButton.onClick = function() self:teleportTemple() end
        topBar.quickSellButton.onClick = function() self:quickSell() end
    end

    local banner = self.ui.activeHuntBanner
    if banner and banner.stopHuntButton then
        banner.stopHuntButton.onClick = function() self:stopHunt() end
    end

    local closeBtn = self.ui.closeButton
    if closeBtn then
        closeBtn.onClick = function() self:toggle() end
    end

        -- Setup Tier Filter Buttons with explicit widths to prevent overlapping
    local filterPanel = self.ui.huntsContentPanel and self.ui.huntsContentPanel.filterPanel
    if filterPanel and filterPanel:getChildCount() == 0 then
        local TIERS = {
            { id = "all", name = "Todas", color = "#ffffff", w = 65 },
            { id = "easy", name = "[Facil] 3 Mobs", color = "#00ff88", w = 145 },
            { id = "medium", name = "[Medio] 4-5 Mobs", color = "#ffd700", w = 155 },
            { id = "hard", name = "[Dificil] 6-7 Mobs", color = "#ff5555", w = 155 }
        }
        for _, t in ipairs(TIERS) do
            local btn = g_ui.createWidget("Button", filterPanel)
            btn:setText(t.name)
            btn:setWidth(t.w)
            btn:setHeight(22)
            btn:setFont("verdana-11px-rounded")
            btn:setColor(t.color)
            btn:setOn(t.id == activeFilter)
            btn.onClick = function()
                for _, b in ipairs(filterPanel:getChildren()) do b:setOn(false) end
                btn:setOn(true)
                activeFilter = t.id
                self:filterHunts()
            end
        end
    end
end

function idleHuntController:toggle()
    if not self.ui then return end
    if self.ui:isVisible() then
        self.ui:hide()
    else
        self.ui:show()
        self.ui:raise()
        self.ui:focus()
        -- Always render existing / fallback hunts instantly so window is NEVER blank
        self:filterHunts()
        self:requestHunts()
        if inHunt and currentView == "loot" then
            self:requestHuntLoot()
        end
    end
end

function idleHuntController:showView(viewName)
    currentView = viewName
    if not self.ui then return end

    local topBar = self.ui.topActionBar
    if viewName == "hunts" then
        if self.ui.huntsContentPanel then
            self.ui.huntsContentPanel:show()
        end
        if self.ui.lootContentPanel then
            self.ui.lootContentPanel:hide()
        end
        if topBar then
            topBar.navHuntsButton:setOn(true)
            topBar.navLootButton:setOn(false)
        end
        self:filterHunts()
    elseif viewName == "loot" then
        if self.ui.huntsContentPanel then
            self.ui.huntsContentPanel:hide()
        end
        if self.ui.lootContentPanel then
            self.ui.lootContentPanel:show()
        end
        if topBar then
            topBar.navHuntsButton:setOn(false)
            topBar.navLootButton:setOn(true)
        end
        self:requestHuntLoot()
    end
end

function idleHuntController:requestHunts()
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"get_hunts"}')
end

function idleHuntController:requestHuntLoot()
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"get_hunt_loot","hunt_id":%d}', currentHuntId))
end

function idleHuntController:showRequirements(huntId)
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    selectedHuntId = huntId
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"get_requirements","hunt_id":%d}', huntId))
end

function idleHuntController:startHunt(huntId)
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    modules.game_textmessage.displayStatusMessage("Starting IDLE hunt...")
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"start_hunt","hunt_id":%d}', huntId))
end

function idleHuntController:stopHunt()
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end

    if stopCountdownEvent then return end

    local banner = self.ui and self.ui.activeHuntBanner
    local stopBtn = banner and banner.stopHuntButton

    local secondsLeft = 5
    if stopBtn then
        stopBtn:setEnabled(false)
        stopBtn:setText(string.format("Stopping (%ds)...", secondsLeft))
    end

    local function countdown()
        secondsLeft = secondsLeft - 1
        if secondsLeft > 0 then
            if stopBtn then
                stopBtn:setText(string.format("Stopping (%ds)...", secondsLeft))
            end
            stopCountdownEvent = scheduleEvent(countdown, 1000)
        else
            stopCountdownEvent = nil
            protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"stop_hunt"}')
            if stopBtn then
                stopBtn:setText("Stop Hunt")
                stopBtn:setEnabled(true)
            end
        end
    end
    stopCountdownEvent = scheduleEvent(countdown, 1000)
end

function idleHuntController:teleportHouse()
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"teleport_house"}')
end

function idleHuntController:teleportTemple()
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"teleport_temple"}')
end

function idleHuntController:quickSell()
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end

    if quickSellCooldownTimer > 0 then
        modules.game_textmessage.displayStatusMessage(string.format("Quick Sell is on cooldown. Please wait %d seconds.", quickSellCooldownTimer))
        return
    end

    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"quick_sell"}')
end

function idleHuntController:setLootRule(itemId, rule)
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end

    local id = tonumber(itemId)
    if not id then return end
    itemRulesCache[id] = rule

    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"set_loot_rule","item_id":%d,"rule":%q}', id, rule))
    scheduleEvent(function() self:requestHuntLoot() end, 200)
end

-- Modal Hunt Drops Window with Real Look Stats
function idleHuntController:showHuntDropsWindow(hunt)
    if not hunt then return end

    if self.dropsWindow then
        self.dropsWindow:destroy()
        self.dropsWindow = nil
    end

    self.dropsWindow = g_ui.displayUI('hunt_drops')
    if not self.dropsWindow then return end

    if self.dropsWindow.huntTitleLabel then
        self.dropsWindow.huntTitleLabel:setText(string.format("Drops Available in %s", hunt.name or ""))
    end

    local panel = self.dropsWindow.dropsPanel
    if not panel then return end
    panel:destroyChildren()

    if hunt.loot and #hunt.loot > 0 then
        for _, item in ipairs(hunt.loot) do
            local slot = g_ui.createWidget("DropSlotItem", panel)
            if slot then
                if slot.itemWidget then
                    slot.itemWidget:setItemId(item.id)
                end
                if slot.chanceLabel then
                    slot.chanceLabel:setText(string.format("%d%%", item.chance or 0))
                end
                if slot.priceLabel then
                    slot.priceLabel:setText(string.format("%d gp", item.price or 0))
                end

                local tip = item.look or (item.name or "Item")
                tip = tip .. string.format("\n------------------------\nDrop Chance: %d%%\nVendor Value: %s gp", item.chance or 0, formatNumber(item.price or 0))
                slot:setTooltip(tip)
                if slot.itemWidget then
                    slot.itemWidget:setTooltip(tip)
                end
            end
        end
    else
        local emptyLbl = g_ui.createWidget("Label", panel)
        emptyLbl:setText("No drop data available.")
        emptyLbl:setColor("#888888")
    end
end

-- Waypoint Patrol & Intelligent Combat Loop with Target Lock & IDLE Hotkeys
function idleHuntController:startAutoCombat()
    if autoCombatEvent then return end

    local function combatLoop()
        if not g_game.isOnline() or not inHunt then
            self:stopAutoCombat()
            return
        end

        local player = g_game.getLocalPlayer()
        if not player then
            autoCombatEvent = scheduleEvent(combatLoop, 400)
            return
        end

        local ok, err = pcall(function()
            local pPos = player:getPosition()
            local now = g_clock.millis()

            local maxHp = player:getMaxHealth() or 100
            local curHp = player:getHealth() or maxHp
            local hpPercent = (curHp / maxHp) * 100

            local maxMp = player:getMaxMana() or 100
            local curMp = player:getMana() or maxMp
            local mpPercent = (curMp / maxMp) * 100

            -- 1. TARGET LOCK: Do NOT switch monsters until current target dies!
            local attacking = g_game.getAttackingCreature()
            local nearestMonster = nil
            local nearestDist = 9999

            if attacking and not attacking:isDead() then
                local aPos = attacking:getPosition()
                if aPos and aPos.z == pPos.z then
                    nearestMonster = attacking
                else
                    attacking = nil
                end
            end

            -- Only acquire new target if no living target is currently locked
            if not nearestMonster then
                local specs = g_map.getSpectators(pPos, false)
                for _, spec in ipairs(specs) do
                    if spec:isMonster() and not spec:isDead() then
                        local mPos = spec:getPosition()
                        if mPos.z == pPos.z then
                            local d = math.max(math.abs(pPos.x - mPos.x), math.abs(pPos.y - mPos.y))
                            if d < nearestDist then
                                nearestDist = d
                                nearestMonster = spec
                            end
                        end
                    end
                end
            end

            if nearestMonster then
                if not attacking or attacking:isDead() or attacking:getId() ~= nearestMonster:getId() then
                    g_game.attack(nearestMonster)
                    attacking = nearestMonster
                end
            end

            local inCombat = (attacking ~= nil and not attacking:isDead())

            -- 2. TACTICAL COMBAT AUTOMATION (IDLE Hotkeys / Gambit System)
            local idleHotkeys = nil
            if modules.game_actionbar and modules.game_actionbar.getIdleHotkeys then
                idleHotkeys = modules.game_actionbar.getIdleHotkeys()
            end

            local executedItem = false
            local executedSpell = false

            if idleHotkeys and #idleHotkeys > 0 then
                -- 1) ITEM / POTION ACTIONS (evaluated first so potions never starve!)
                for _, slot in ipairs(idleHotkeys) do
                    if not executedItem and slot.type == "object" then
                        local reqPercent = tonumber(slot.percent) or 60
                        local conditionMet = false

                        if slot.resource == "HP" then
                            if hpPercent <= reqPercent then
                                conditionMet = true
                            end
                        elseif slot.resource == "MP" then
                            if slot.offensive then
                                if mpPercent >= reqPercent then
                                    conditionMet = true
                                end
                            else
                                if mpPercent <= reqPercent then
                                    conditionMet = true
                                end
                            end
                        end

                        if slot.combatOnly and not inCombat then
                            conditionMet = false
                        end

                        if conditionMet and (now - (slot.lastUsed or 0) >= (slot.cooldown or 1000)) then
                            local protocol = g_game.getProtocolGame()
                            if protocol then
                                protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"use_idle_supply","item_id":%d,"cost":%d}', slot.itemId, slot.cost or 0))
                            end
                            slot.lastUsed = now
                            executedItem = true
                        end
                    end
                end

                -- 2) SPELL ACTIONS (healing or offensive)
                for _, slot in ipairs(idleHotkeys) do
                    if not executedSpell and slot.type == "spell" then
                        local reqPercent = tonumber(slot.percent) or 80
                        local conditionMet = false
                        local isOffensive = (slot.offensive ~= nil and slot.offensive) or not (slot.words and (slot.words:lower():find("exura") or slot.words:lower():find("heal") or slot.words:lower():find("san") or slot.words:lower():find("vita") or slot.words:lower():find("cure")))
                        local op = slot.operator or (isOffensive and ">=" or "<=")

                        if slot.resource == "Combat" or slot.resource == "Always" or slot.resource == "In Combat" then
                            conditionMet = inCombat
                        elseif slot.resource == "HP" then
                            if isOffensive and op == "<=" then
                                -- Smart fallback: if offensive spell was saved with legacy HP <= 80, fire whenever in combat
                                conditionMet = inCombat
                            elseif op == ">=" then
                                conditionMet = (hpPercent >= reqPercent)
                            else
                                conditionMet = (hpPercent <= reqPercent)
                            end
                        elseif slot.resource == "MP" then
                            if op == ">=" then
                                conditionMet = (mpPercent >= reqPercent)
                            else
                                conditionMet = (mpPercent <= reqPercent)
                            end
                        end

                        if slot.combatOnly and not inCombat then
                            conditionMet = false
                        end

                        if conditionMet and (now - (slot.lastUsed or 0) >= (slot.cooldown or 1000)) then
                            g_game.talk(slot.words)
                            slot.lastUsed = now
                            executedSpell = true
                        end
                    end
                end
            end

            -- 3. WAYPOINT PATROL & CHASE
            if nearestMonster and nearestDist > 1 then
                local mPos = nearestMonster:getPosition()
                local path = g_map.findPath(pPos, mPos, 50, PathFindFlags.AllowWalkItem)
                if path and #path > 0 then
                    g_game.walk(path[1])
                end
            elseif #currentWaypoints > 0 then
                local targetWp = currentWaypoints[currentWaypointIndex]
                if targetWp then
                    local distToWp = math.max(math.abs(pPos.x - targetWp.x), math.abs(pPos.y - targetWp.y))
                    if distToWp <= 1 or (pPos.x == targetWp.x and pPos.y == targetWp.y) then
                        currentWaypointIndex = currentWaypointIndex + 1
                        if currentWaypointIndex > #currentWaypoints then
                            currentWaypointIndex = 1
                        end
                        waypointStuckTime = now
                        waypointLastPos = pPos
                    else
                        if waypointLastPos and pPos.x == waypointLastPos.x and pPos.y == waypointLastPos.y then
                            if now - waypointStuckTime > 5000 then
                                currentWaypointIndex = currentWaypointIndex + 1
                                if currentWaypointIndex > #currentWaypoints then
                                    currentWaypointIndex = 1
                                end
                                waypointStuckTime = now
                            end
                        else
                            waypointLastPos = pPos
                            waypointStuckTime = now
                        end

                        targetWp = currentWaypoints[currentWaypointIndex]
                        local wpPos = { x = targetWp.x, y = targetWp.y, z = targetWp.z or pPos.z }
                        local path = g_map.findPath(pPos, wpPos, 100, PathFindFlags.AllowWalkItem)
                        if path and #path > 0 then
                            g_game.walk(path[1])
                        end
                    end
                end
            elseif huntCenterPos and (now - lastWanderTime >= 2500) then
                local distFromCenter = math.max(math.abs(pPos.x - huntCenterPos.x), math.abs(pPos.y - huntCenterPos.y))
                if distFromCenter > 8 then
                    local path = g_map.findPath(pPos, huntCenterPos, 50, PathFindFlags.AllowWalkItem)
                    if path and #path > 0 then
                        g_game.walk(path[1])
                    end
                else
                    local randomDir = math.random(0, 3)
                    g_game.walk(randomDir)
                end
                lastWanderTime = now
            end
        end)

        if not ok and err then
            print("[Idle Combat Error] " .. tostring(err))
        end

        autoCombatEvent = scheduleEvent(combatLoop, 400)
    end

    autoCombatEvent = scheduleEvent(combatLoop, 400)
end

function idleHuntController:stopAutoCombat()
    if autoCombatEvent then
        removeEvent(autoCombatEvent)
        autoCombatEvent = nil
    end
end

function idleHuntController:onOpcodeReceived(buffer)
    local success, data = pcall(function() return json.decode(buffer) end)
    if not success or type(data) ~= "table" then
        pwarning('[IDLE HUNT] JSON decode failed: ' .. tostring(data))
        return
    end

    local action = data.action

    if action == "hunts_list" then
        self:renderHuntsList(data)
    elseif action == "requirements" then
        self:renderRequirements(data)
    elseif action == "hunt_started" then
        inHunt = true
        currentHuntId = data.hunt_id or 1
        currentWaypoints = data.waypoints or {}
        currentWaypointIndex = 1
        waypointLastPos = nil
        waypointStuckTime = g_clock.millis()

        if data.spawn_x and data.spawn_y and data.spawn_z then
            huntCenterPos = { x = data.spawn_x, y = data.spawn_y, z = data.spawn_z }
        end
        if self.ui and self.ui.activeHuntBanner then
            self.ui.activeHuntBanner:show()
            self.ui.activeHuntBanner.activeTitle:setText("Hunting: " .. (data.hunt_name or ""))
            local hunt = nil
            for _, h in ipairs(huntsCache) do
                if h.id == currentHuntId then hunt = h break end
            end
            if hunt and hunt.looktype and hunt.looktype > 0 and self.ui.activeHuntBanner.activeCreature then
                self.ui.activeHuntBanner.activeCreature:setOutfit({type = hunt.looktype})
                local cr = self.ui.activeHuntBanner.activeCreature:getCreature()
                if cr then cr:setStaticWalking(1000) end
            end
        end
        if self.ui and self.ui:isVisible() then
            self.ui:hide()
        end
        modules.game_textmessage.displayStatusMessage("[IDLE HUNT] Hunt started: " .. (data.hunt_name or ""))
        self:startAutoCombat()
        if currentView == "loot" then
            self:requestHuntLoot()
        end
    elseif action == "hunt_ended" then
        inHunt = false
        huntCenterPos = nil
        currentWaypoints = {}
        if stopCountdownEvent then
            removeEvent(stopCountdownEvent)
            stopCountdownEvent = nil
        end
        if self.ui and self.ui.activeHuntBanner then
            self.ui.activeHuntBanner:hide()
            local btn = self.ui.activeHuntBanner.stopHuntButton
            if btn then
                btn:setEnabled(true)
                btn:setText("Stop Hunt")
            end
        end
        self:stopAutoCombat()
    elseif action == "hunt_loot" then
        lastLootData = data
        self:renderLootList(data)
    elseif action == "hunt_update" then
        if self.ui and self.ui.activeHuntBanner and inHunt then
            if data.hunt_name then
                self.ui.activeHuntBanner.activeTitle:setText("Hunting: " .. data.hunt_name)
            end
        end
        if data.stamina and data.max_stamina then
            self:updateStamina(data.stamina, data.max_stamina)
        end
    elseif action == "quick_sell_result" then
        if (data.gold or 0) > 0 then
            local msg = string.format("Quick Sell completed! Sold %d item(s) for %s gold (credited to bank).", data.count or 0, formatNumber(data.gold or 0))
            modules.game_textmessage.displayStatusMessage(msg)
            self:startQuickSellCooldown(data.cooldown or 5)
        else
            self:startQuickSellCooldown(0)
        end
        self:requestHuntLoot()
    elseif action == "quick_sell_cooldown" then
        self:startQuickSellCooldown(data.remaining or 5)
    end
end

function idleHuntController:startQuickSellCooldown(seconds)
    quickSellCooldownTimer = seconds
    if quickSellEvent then
        removeEvent(quickSellEvent)
        quickSellEvent = nil
    end

    local topBar = self.ui and self.ui.topActionBar
    local qsBtn = topBar and topBar.quickSellButton

    local function tick()
        if quickSellCooldownTimer > 0 then
            quickSellCooldownTimer = quickSellCooldownTimer - 1
            if qsBtn then
                qsBtn:setText(string.format("Quick Sell (%ds)", quickSellCooldownTimer))
            end
            quickSellEvent = scheduleEvent(tick, 1000)
        else
            quickSellCooldownTimer = 0
            quickSellEvent = nil
            if qsBtn then
                qsBtn:setText("Quick Sell")
            end
        end
    end
    tick()
end

function idleHuntController:updateStamina(cur, max)
    if not self.ui or not self.ui.staminaPanel then return end
    local bar = self.ui.staminaPanel.staminaBar
    if bar then
        bar:setMinimum(0)
        bar:setMaximum(max)
        bar:setValue(cur)
    end

    local hours = math.floor(cur / 3600)
    local mins = math.floor((cur % 3600) / 60)
    local lbl = self.ui.staminaPanel.staminaLabel
    if lbl then
        lbl:setText(string.format("IDLE Stamina: %02dh %02dm", hours, mins))
    end
end

function idleHuntController:renderHuntsList(data)
    if data.hunts and #data.hunts > 0 then
        huntsCache = data.hunts
    elseif not huntsCache or #huntsCache == 0 then
        huntsCache = DEFAULT_HUNTS_CATALOG
    end
    self:updateStamina(data.stamina or 0, data.max_stamina or 86400)

    inHunt = data.in_hunt or false
    currentHuntId = data.active_hunt_id or 0

    if inHunt and self.ui and self.ui.activeHuntBanner then
        self.ui.activeHuntBanner:show()
        for _, h in ipairs(huntsCache) do
            if h.id == currentHuntId then
                if h.looktype and h.looktype > 0 and self.ui.activeHuntBanner.activeCreature then
                    self.ui.activeHuntBanner.activeCreature:setOutfit({type = h.looktype})
                    local cr = self.ui.activeHuntBanner.activeCreature:getCreature()
                    if cr then cr:setStaticWalking(1000) end
                end
                self.ui.activeHuntBanner.activeTitle:setText("Hunting: " .. h.name)
                break
            end
        end
    end

    self:filterHunts()
end

function idleHuntController:filterHunts()
    if not self.ui or not self.ui.huntsContentPanel then return end
    local huntList = self.ui.huntsContentPanel.huntList
    if not huntList then return end
    huntList:destroyChildren()

    local activeClean = string.lower(string.gsub(activeFilter or "all", "%s+", ""))

    for _, h in ipairs(huntsCache) do
        local tierClean = string.lower(string.gsub(h.tier or "", "%s+", ""))
        local match = (activeClean == "all" or activeClean == "todas" or tierClean == activeClean)

        if match then
            local card = g_ui.createWidget("HuntCard", huntList)
            if card then
                local tierPrefix = ""
                if h.tier == "easy" then
                    tierPrefix = "[🟢 Fácil]"
                elseif h.tier == "medium" then
                    tierPrefix = "[🟡 Médio]"
                elseif h.tier == "hard" then
                    tierPrefix = "[🔴 Difícil]"
                else
                    tierPrefix = string.format("[%s]", h.tier or "")
                end

                card.huntTitle:setText(string.format("%s %s", tierPrefix, h.name))

                if h.looktype and h.looktype > 0 and card.monsterFrame and card.monsterFrame.monsterCreature then
                    card.monsterFrame.monsterCreature:setOutfit({type = h.looktype})
                    local cr = card.monsterFrame.monsterCreature:getCreature()
                    if cr then
                        cr:setStaticWalking(1000)
                    end
                end

                local tagColor = "#00ff88"
                if h.focus == "More EXP" or h.focus == "Mais XP" then
                    tagColor = "#ffcc00"
                elseif h.focus == "More Loot" or h.focus == "Mais Loot" then
                    tagColor = "#00ddff"
                end
                card.focusTag:setText("[" .. (h.focus or "Balanced") .. "]")
                card.focusTag:setColor(tagColor)

                -- Clickable Bag Button opens Hunt Drops Window with Real Look Stats
                if card.lootBagButton then
                    card.lootBagButton.onClick = function()
                        self:showHuntDropsWindow(h)
                    end
                end

                local waveDesc = ""
                if h.waves and #h.waves > 0 then
                    local wp = {}
                    for _, w in ipairs(h.waves) do
                        table.insert(wp, string.format("%dx %s", w.count, w.name))
                    end
                    waveDesc = " | Onda: " .. table.concat(wp, " + ")
                end

                card.huntDesc:setText((h.desc or "") .. waveDesc)
                card.huntCost:setText(string.format("Supplies: ~%d gp / turn | Min Level: %d", tonumber(h.cost) or 10, tonumber(h.req_lvl or h.level) or 8))

                card.reqButton.onClick = function()
                    self:showRequirements(h.id)
                end

                card.startButton.onClick = function()
                    self:startHunt(h.id)
                end
            end
        end
    end
end

function idleHuntController:renderRequirements(data)
    if reqWindow then reqWindow:destroy() reqWindow = nil end

    reqWindow = g_ui.displayUI('hunt_requirements')
    if not reqWindow then return end

    local hunt = nil
    for _, h in ipairs(huntsCache) do
        if h.id == selectedHuntId then hunt = h break end
    end

    if hunt then
        reqWindow.huntTitleLabel:setText(string.format("Requirements for %s", hunt.name))
    end

    local function setComparison(curLbl, reqLbl, diffLbl, curVal, reqVal)
        curLbl:setText(formatNumber(curVal))
        reqLbl:setText(formatNumber(reqVal))
        local diff = curVal - reqVal
        if diff >= 0 then
            diffLbl:setText("+" .. formatNumber(diff) .. " OK")
            diffLbl:setColor("#00ff88")
        else
            diffLbl:setText(formatNumber(diff) .. " (Missing)")
            diffLbl:setColor("#ff4444")
        end
    end

    setComparison(reqWindow.curLvl, reqWindow.reqLvl, reqWindow.diffLvl, data.player_lvl or 1, data.req_lvl or 1)
    setComparison(reqWindow.curAtk, reqWindow.reqAtk, reqWindow.diffAtk, data.player_atk or 0, data.req_atk or 0)
    setComparison(reqWindow.curDef, reqWindow.reqDef, reqWindow.diffDef, data.player_def or 0, data.req_def or 0)
    setComparison(reqWindow.curBank, reqWindow.reqBank, reqWindow.diffBank, data.player_bank or 0, data.req_bank or 0)

    if reqWindow.reqPotions then
        reqWindow.reqPotions:setText(data.potions or "None")
    end

    reqWindow.startHuntButton.onClick = function()
        self:startHunt(selectedHuntId)
        reqWindow:destroy()
        reqWindow = nil
    end

    reqWindow.cancelButton.onClick = function()
        reqWindow:destroy()
        reqWindow = nil
    end
end

-- Render Loot List with Padlock Toggle & Excludes Gold Coin
function idleHuntController:renderLootList(data)
    if not self.ui or not self.ui.lootContentPanel then return end
    local panel = self.ui.lootContentPanel
    local list = panel.lootList
    if not list then return end
    list:destroyChildren()

    local gold = data.pending_gold or 0
    if panel.lootSummaryBox and panel.lootSummaryBox.pendingGoldText then
        panel.lootSummaryBox.pendingGoldText:setText(string.format("Loot ready to sell: %s gp", formatNumber(gold)))
    end

    local nextSellSecs = data.next_autosell or 600
    local nextMins = math.floor(nextSellSecs / 60)
    local nextSecs = nextSellSecs % 60
    if panel.lootSummaryBox and panel.lootSummaryBox.nextAutosellText then
        panel.lootSummaryBox.nextAutosellText:setText(string.format("Next auto-sell in: %02dm %02ds", nextMins, nextSecs))
    end

    local loot = data.loot or {}
    if #loot == 0 then
        local emptyCard = g_ui.createWidget("Label", list)
        emptyCard:setText("No items collected in this hunt yet.")
        emptyCard:setColor("#888888")
        return
    end

    local visibleCount = 0
    for _, item in ipairs(loot) do
        local inBag = item.in_bag or 0
        -- Apenas exibe itens que o jogador realmente tem na backpack atualmente
        if inBag > 0 and item.id ~= 3031 and item.id ~= 3035 and item.id ~= 3043 and not item.is_money then
            visibleCount = visibleCount + 1
            itemRulesCache[item.id] = item.rule or "keep"

            local card = g_ui.createWidget("LootCard", list)
            if card then
                card.itemIcon:setItemId(item.id)
                card.itemName:setText(string.format("%s (In Bag: %d)", item.name, inBag))

                if item.look then
                    card.itemIcon:setTooltip(item.look .. string.format("\nPrice: %d gp", item.price or 0))
                end

                local function applyRuleVisual(rule)
                    if rule == "keep" then
                        card.statusLabel:setText("Status: [LOCKED] Safe in Backpack")
                        card.statusLabel:setColor("#00ff88")
                        card.lockButton:setText("[LOCKED] Keep")
                        card.lockButton:setColor("#00ff88")
                        card.lockButton:setTooltip("Item is locked and WILL NOT be sold.\nClick to mark for Auto-Sell.")
                    else
                        card.statusLabel:setText("Status: [UNLOCKED] Marked for Auto-Sell")
                        card.statusLabel:setColor("#ffd700")
                        card.lockButton:setText("[UNLOCKED] Sell")
                        card.lockButton:setColor("#ffd700")
                        card.lockButton:setTooltip("Item is unlocked and will be sold on Quick Sell or every 10m.\nClick to Lock.")
                    end
                end

                local initialRule = itemRulesCache[item.id] or (item.rule or "keep")
                applyRuleVisual(initialRule)

                card.lockButton.onClick = function()
                    local current = itemRulesCache[item.id] or (item.rule or "keep")
                    local nextRule = (current == "keep") and "sell" or "keep"
                    itemRulesCache[item.id] = nextRule
                    applyRuleVisual(nextRule)
                    self:setLootRule(item.id, nextRule)
                end
            end
        end
    end

    if visibleCount == 0 then
        local emptyCard = g_ui.createWidget("Label", list)
        emptyCard:setText("No hunt loot currently in backpack.")
        emptyCard:setFont("verdana-11px-rounded")
        emptyCard:setColor("#888888")
        emptyCard:setMarginTop(20)
        emptyCard:setTextAutoResize(true)
    end
end