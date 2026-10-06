g_ui.importStyle('idlehunt_styles')

local OPCODE_IDLE_HUNT = 106

local idleButton = nil

-- Tabela Oficial Fallback de 21 Hunts (3 Dificuldades: Fácil, Médio, Difícil)
local DEFAULT_HUNTS_CATALOG = {
    -- 🟢 FÁCIL
    { id = 1, name = "Rotworms (Fácil)", tier = "easy", level = 8, focus = "Balanced", desc = "Sala de treino inicial com 3 Rotworms. Ideal para iniciantes.", cost = 10, req_lvl = 8, looktype = 26, waves = {{ name = "Rotworm", count = 3 }} },
    { id = 2, name = "Amazons (Fácil)", tier = "easy", level = 15, focus = "More Loot", desc = "3 Amazons ágeis com drops frequentes de Protective Charm.", cost = 15, req_lvl = 15, looktype = 137, waves = {{ name = "Amazon", count = 3 }} },
    { id = 3, name = "Cyclops (Fácil)", tier = "easy", level = 25, focus = "More EXP", desc = "3 Cyclops corpulentos com bom ganho de experiência e Cyclops Toes.", cost = 30, req_lvl = 25, looktype = 22, waves = {{ name = "Cyclops", count = 3 }} },
    { id = 4, name = "Minotaurs (Fácil)", tier = "easy", level = 20, focus = "More Loot", desc = "3 Minotaurs com alto rendimento de Minotaur Leather.", cost = 25, req_lvl = 20, looktype = 29, waves = {{ name = "Minotaur", count = 3 }} },
    { id = 5, name = "Undeads (Fácil)", tier = "easy", level = 22, focus = "Balanced", desc = "3 Skeletons antigos para treino rápido.", cost = 25, req_lvl = 22, looktype = 18, waves = {{ name = "Skeleton", count = 3 }} },
    { id = 6, name = "Dragons (Fácil)", tier = "easy", level = 50, focus = "More EXP", desc = "3 Dragons clássicos. Excelente avanço de experiência intermediária.", cost = 80, req_lvl = 50, looktype = 34, waves = {{ name = "Dragon", count = 3 }} },
    { id = 7, name = "Demons (Fácil)", tier = "easy", level = 80, focus = "More EXP", desc = "3 Fire Elementals incandescentes para treinar combate elemental.", cost = 130, req_lvl = 80, looktype = 49, waves = {{ name = "Fire Elemental", count = 3 }} },

    -- 🟡 MÉDIO
    { id = 8, name = "Rotworms (Médio)", tier = "medium", level = 20, focus = "Balanced", desc = "3 Rotworms acompanhados por 2 Carrion Worms famintos.", cost = 25, req_lvl = 20, looktype = 26, waves = {{ name = "Rotworm", count = 3 }, { name = "Carrion Worm", count = 2 }} },
    { id = 9, name = "Amazons (Médio)", tier = "medium", level = 28, focus = "More Loot", desc = "2 Amazons e 3 Valkyries atiradoras de lanças.", cost = 35, req_lvl = 28, looktype = 137, waves = {{ name = "Amazon", count = 2 }, { name = "Valkyrie", count = 3 }} },
    { id = 10, name = "Cyclops (Médio)", tier = "medium", level = 40, focus = "More EXP", desc = "3 Cyclops e 2 Cyclops Drones agressivos.", cost = 55, req_lvl = 40, looktype = 22, waves = {{ name = "Cyclops", count = 3 }, { name = "Cyclops Drone", count = 2 }} },
    { id = 11, name = "Minotaurs (Médio)", tier = "medium", level = 35, focus = "More Loot", desc = "2 Minotaurs, 2 Minotaur Guards e 1 Minotaur Archer.", cost = 50, req_lvl = 35, looktype = 29, waves = {{ name = "Minotaur", count = 2 }, { name = "Minotaur Guard", count = 2 }, { name = "Minotaur Archer", count = 1 }} },
    { id = 12, name = "Undeads (Médio)", tier = "medium", level = 45, focus = "Balanced", desc = "2 Ghouls e 2 Crypt Shamblers rastejantes.", cost = 65, req_lvl = 45, looktype = 18, waves = {{ name = "Ghoul", count = 2 }, { name = "Crypt Shambler", count = 2 }} },
    { id = 13, name = "Dragons (Médio)", tier = "medium", level = 75, focus = "More EXP", desc = "4 Dragons soltando rajadas de fogo contínuas.", cost = 130, req_lvl = 75, looktype = 34, waves = {{ name = "Dragon", count = 4 }} },
    { id = 14, name = "Demons (Médio)", tier = "medium", level = 120, focus = "More EXP", desc = "2 Fire Elementals e 2 Diabolic Imps traiçoeiros.", cost = 260, req_lvl = 120, looktype = 49, waves = {{ name = "Fire Elemental", count = 2 }, { name = "Diabolic Imp", count = 2 }} },

    -- 🔴 DIFÍCIL
    { id = 15, name = "Rotworms (Difícil)", tier = "hard", level = 35, focus = "Balanced", desc = "4 Carrion Worms e 2 Rotworm Queens enfurecidas.", cost = 50, req_lvl = 35, looktype = 26, waves = {{ name = "Carrion Worm", count = 4 }, { name = "Rotworm Queen", count = 2 }} },
    { id = 16, name = "Amazons (Difícil)", tier = "hard", level = 45, focus = "More Loot", desc = "4 Valkyries armadas e 2 Witches conjuradoras de fogo.", cost = 70, req_lvl = 45, looktype = 137, waves = {{ name = "Valkyrie", count = 4 }, { name = "Witch", count = 2 }} },
    { id = 17, name = "Cyclops (Difícil)", tier = "hard", level = 60, focus = "More EXP", desc = "3 Cyclops Drones e 3 Cyclops Smiths forjadores.", cost = 100, req_lvl = 60, looktype = 22, waves = {{ name = "Cyclops Drone", count = 3 }, { name = "Cyclops Smith", count = 3 }} },
    { id = 18, name = "Minotaurs (Difícil)", tier = "hard", level = 55, focus = "More Loot", desc = "3 Minotaur Guards, 2 Minotaur Archers e 2 Minotaur Mages.", cost = 90, req_lvl = 55, looktype = 29, waves = {{ name = "Minotaur Guard", count = 3 }, { name = "Minotaur Archer", count = 2 }, { name = "Minotaur Mage", count = 2 }} },
    { id = 19, name = "Undeads (Difícil)", tier = "hard", level = 70, focus = "Balanced", desc = "3 Crypt Shamblers, 2 Bonebeasts e 1 Vampire sinistro.", cost = 120, req_lvl = 70, looktype = 18, waves = {{ name = "Crypt Shambler", count = 3 }, { name = "Bonebeast", count = 2 }, { name = "Vampire", count = 1 }} },
    { id = 20, name = "Dragons (Difícil)", tier = "hard", level = 100, focus = "More EXP", desc = "3 Dragons enfurecidos e 3 Dragon Lords devastadores.", cost = 280, req_lvl = 100, looktype = 39, waves = {{ name = "Dragon", count = 3 }, { name = "Dragon Lord", count = 3 }} },
    { id = 21, name = "Demons (Difícil)", tier = "hard", level = 180, focus = "More EXP", desc = "4 Diabolic Imps velozes e 2 Demons titânicos.", cost = 500, req_lvl = 180, looktype = 35, waves = {{ name = "Diabolic Imp", count = 4 }, { name = "Demon", count = 2 }} }
}

local huntsCache = DEFAULT_HUNTS_CATALOG
local activeFilter = "all"
local currentView = "dashboard"
local inHunt = false
local currentHuntId = 0
local selectedHuntId = 1
local selectedPull = "bold"

local quickSellCooldownTimer = 0
local quickSellEvent = nil
local autoCombatEvent = nil
local stopCountdownEvent = nil
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

-- Helper de persistência de regras de loot
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
        and string.format("Item #%d [LOCKED]: Guardado na backpack.", id)
        or string.format("Item #%d [UNLOCKED]: Marcado para Auto-Venda.", id)

    if modules.game_textmessage and modules.game_textmessage.displayStatusMessage then
        modules.game_textmessage.displayStatusMessage(msg)
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
    g_ui.importStyle('idlehunt')
    self.ui = g_ui.createWidget('MainWindow', rootWidget)
    self.ui:setId('idleHuntWindow')
    self.ui:setText(tr('IDLE HUNT - SISTEMA DE CAÇADAS'))
    self.ui:setSize({ width = 720, height = 620 })
    self.ui:hide()

    self.ui.onEscape = function() self.ui:hide() end

    ProtocolGame.registerExtendedOpcode(OPCODE_IDLE_HUNT, function(protocol, opcode, buffer)
        self:onOpcodeReceived(protocol, opcode, buffer)
    end)

    connect(g_game, {
        onGameStart = function() self:onGameStart() end,
        onGameEnd = function() self:onGameEnd() end
    })

    self:setupTopMenuButton()
    self:setupDashboardUI()
    self:setupCatalogUI()
    self:setupDetailsUI()
end

function idleHuntController:onTerminate()
    ProtocolGame.unregisterExtendedOpcode(OPCODE_IDLE_HUNT)
    if self.ui then
        self.ui:destroy()
        self.ui = nil
    end
    if idleButton then
        idleButton:destroy()
        idleButton = nil
    end
    self:stopAutoCombat()
end

function idleHuntController:setupTopMenuButton()
    if modules.client_topmenu and modules.client_topmenu.addLeftGameButton then
        idleButton = modules.client_topmenu.addLeftGameButton(
            'idleHuntButton',
            tr('Idle Hunt (Ctrl+H)'),
            '/images/topbuttons/cooldowns',
            function() self:toggle() end
        )
    end
    g_keyboard.bindKeyDown('Ctrl+H', function() self:toggle() end)
end

function idleHuntController:onGameStart()
    self:requestHunts()
    self:switchView("dashboard")
end

function idleHuntController:onGameEnd()
    self:stopAutoCombat()
    inHunt = false
    currentHuntId = 0
    if self.ui then
        self.ui:hide()
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
        self:requestHunts()
        self:switchView(inHunt and "dashboard" or currentView)
    end
end

-- =========================================================================
-- GERENCIADOR DE TELAS (FLUXO EM 3 ETAPAS)
-- =========================================================================
function idleHuntController:switchView(viewName, param)
    currentView = viewName
    if not self.ui then return end

    local dView = self.ui.dashboardView
    local cView = self.ui.catalogView
    local dtView = self.ui.detailsView

    if dView then dView:setVisible(viewName == "dashboard") end
    if cView then cView:setVisible(viewName == "catalog") end
    if dtView then dtView:setVisible(viewName == "details") end

    if viewName == "dashboard" then
        self:updateDashboardState()
    elseif viewName == "catalog" then
        self:filterHunts()
    elseif viewName == "details" then
        self:showDetails(param or selectedHuntId)
    end
end

-- =========================================================================
-- 1. SETUP TELA 1: DASHBOARD
-- =========================================================================
function idleHuntController:setupDashboardUI()
    local dView = self.ui.dashboardView
    if not dView then return end

    -- Botão Organizar Caçada
    local openCatBtn = dView.idleModeCard and dView.idleModeCard.openCatalogButton
    if openCatBtn then
        openCatBtn.onClick = function()
            self:switchView("catalog")
        end
    end

    -- Botão Parar Caçada
    local stopBtn = dView.activeHuntCard and dView.activeHuntCard.stopHuntButton
    if stopBtn then
        stopBtn.onClick = function()
            self:stopHunt()
        end
    end

    -- Botões Rodapé
    local bBar = dView.dashboardBottomBar
    if bBar then
        if bBar.quickSellButton then
            bBar.quickSellButton.onClick = function() self:quickSell() end
        end
        if bBar.teleportTempleButton then
            bBar.teleportTempleButton.onClick = function() self:teleportTemple() end
        end
        if bBar.teleportHouseButton then
            bBar.teleportHouseButton.onClick = function() self:teleportHouse() end
        end
    end
end

function idleHuntController:updateDashboardState()
    local dView = self.ui and self.ui.dashboardView
    if not dView then return end

    local idleCard = dView.idleModeCard
    local activeCard = dView.activeHuntCard

    if inHunt then
        if idleCard then idleCard:setVisible(false) end
        if activeCard then
            activeCard:setVisible(true)
            local hunt = self:getHuntById(currentHuntId)
            if hunt and activeCard.activeCreatureFrame and activeCard.activeCreatureFrame.activeCreature then
                if hunt.looktype and hunt.looktype > 0 then
                    activeCard.activeCreatureFrame.activeCreature:setOutfit({ type = hunt.looktype })
                    local cr = activeCard.activeCreatureFrame.activeCreature:getCreature()
                    if cr then cr:setStaticWalking(1000) end
                end
                activeCard.activeTitle:setText(string.format("Caçando: %s", hunt.name))
                activeCard.activePullLabel:setText(string.format("Intensidade: [%s]", string.upper(selectedPull or "bold")))
            end
        end
    else
        if idleCard then idleCard:setVisible(true) end
        if activeCard then activeCard:setVisible(false) end
    end
end

-- =========================================================================
-- 2. SETUP TELA 2: CATÁLOGO DE HUNTS
-- =========================================================================
function idleHuntController:setupCatalogUI()
    local cView = self.ui.catalogView
    if not cView then return end

    local topBar = cView.catalogTopBar
    if topBar and topBar.backToDashboardBtn then
        topBar.backToDashboardBtn.onClick = function()
            self:switchView("dashboard")
        end
    end

    if topBar and topBar.searchEdit then
        topBar.searchEdit.onTextChange = function()
            self:filterHunts()
        end
    end

    local filterPanel = cView.catalogFilterPanel
    if filterPanel and filterPanel:getChildCount() == 0 then
        local TIERS = {
            { id = "all", name = "Todas as Hunts", color = "#ffffff", w = 120 },
            { id = "easy", name = "[FÁCIL] Nível 8+", color = "#00ff88", w = 140 },
            { id = "medium", name = "[MÉDIO] Nível 20+", color = "#ffd700", w = 150 },
            { id = "hard", name = "[DIFÍCIL] Nível 35+", color = "#ff5555", w = 150 }
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

function idleHuntController:filterHunts()
    local cView = self.ui and self.ui.catalogView
    if not cView or not cView.huntList then return end
    local huntList = cView.huntList
    huntList:destroyChildren()

    local searchText = ""
    if cView.catalogTopBar and cView.catalogTopBar.searchEdit then
        searchText = string.lower(string.trimSpace(cView.catalogTopBar.searchEdit:getText() or ""))
    end

    local activeClean = string.lower(string.gsub(activeFilter or "all", "%s+", ""))

    for _, h in ipairs(huntsCache) do
        local tierClean = string.lower(string.gsub(h.tier or "", "%s+", ""))
        local matchTier = (activeClean == "all" or activeClean == "todas" or tierClean == activeClean)

        local nameMatch = true
        if searchText ~= "" then
            local n = string.lower(h.name or "")
            local d = string.lower(h.desc or "")
            nameMatch = (string.find(n, searchText, 1, true) ~= nil) or (string.find(d, searchText, 1, true) ~= nil)
        end

        if matchTier and nameMatch then
            local card = g_ui.createWidget("HuntCard", huntList)
            if card then
                local tierPrefix = ""
                if h.tier == "easy" then
                    tierPrefix = "[FÁCIL]"
                    card.huntTitle:setColor("#00ff88")
                elseif h.tier == "medium" then
                    tierPrefix = "[MÉDIO]"
                    card.huntTitle:setColor("#ffd700")
                elseif h.tier == "hard" then
                    tierPrefix = "[DIFÍCIL]"
                    card.huntTitle:setColor("#ff5555")
                end

                card.huntTitle:setText(string.format("%s %s", tierPrefix, h.name))

                if h.looktype and h.looktype > 0 and card.monsterFrame and card.monsterFrame.monsterCreature then
                    card.monsterFrame.monsterCreature:setOutfit({ type = h.looktype })
                    local cr = card.monsterFrame.monsterCreature:getCreature()
                    if cr then cr:setStaticWalking(1000) end
                end

                local tagColor = "#00ff88"
                if h.focus == "More EXP" or h.focus == "Mais XP" then
                    tagColor = "#ffcc00"
                elseif h.focus == "More Loot" or h.focus == "Mais Loot" then
                    tagColor = "#00ddff"
                end
                card.focusTag:setText("[" .. (h.focus or "Balanced") .. "]")
                card.focusTag:setColor(tagColor)

                local waveDesc = ""
                if h.waves and #h.waves > 0 then
                    local wp = {}
                    for _, w in ipairs(h.waves) do
                        table.insert(wp, string.format("%dx %s", w.count, w.name))
                    end
                    waveDesc = " | Onda: " .. table.concat(wp, " + ")
                end

                card.huntDesc:setText((h.desc or "") .. waveDesc)
                card.huntCost:setText(string.format("Supplies: ~%d gp/turn | Min Lvl: %d", tonumber(h.cost) or 10, tonumber(h.req_lvl or h.level) or 8))

                -- Recorde de XP/h e GP/h
                if card.recordLabel then
                    if (h.record_exp or 0) > 0 then
                        card.recordLabel:setText(string.format("Recorde: %s XP/h | %s GP/h", formatNumber(h.record_exp), formatNumber(h.record_gp or 0)))
                        card.recordLabel:setColor("#00ddff")
                    else
                        card.recordLabel:setText("Recorde: Sem registro ainda (10m)")
                        card.recordLabel:setColor("#777777")
                    end
                end

                card.configButton.onClick = function()
                    self:switchView("details", h.id)
                end
            end
        end
    end
end

-- =========================================================================
-- 3. SETUP TELA 3: DETALHES DA HUNT, PULLS, ELEMENTOS E DROPS
-- =========================================================================
function idleHuntController:setupDetailsUI()
    local dtView = self.ui.detailsView
    if not dtView then return end

    if dtView.detailsTopBar and dtView.detailsTopBar.backToCatalogBtn then
        dtView.detailsTopBar.backToCatalogBtn.onClick = function()
            self:switchView("catalog")
        end
    end

    -- Configuração dos Botões de Pull
    local pPanel = dtView.pullsPanel
    if pPanel then
        local function selectPull(pullName)
            selectedPull = pullName
            if pPanel.pullCautiousBtn then
                pPanel.pullCautiousBtn:setColor(pullName == "cautious" and "#00ff88" or "#888888")
                pPanel.pullCautiousBtn:setOn(pullName == "cautious")
            end
            if pPanel.pullBoldBtn then
                pPanel.pullBoldBtn:setColor(pullName == "bold" and "#ffd700" or "#888888")
                pPanel.pullBoldBtn:setOn(pullName == "bold")
            end
            if pPanel.pullAggressiveBtn then
                pPanel.pullAggressiveBtn:setColor(pullName == "aggressive" and "#ff5555" or "#888888")
                pPanel.pullAggressiveBtn:setOn(pullName == "aggressive")
            end
        end

        pPanel.pullCautiousBtn.onClick = function() selectPull("cautious") end
        pPanel.pullBoldBtn.onClick = function() selectPull("bold") end
        pPanel.pullAggressiveBtn.onClick = function() selectPull("aggressive") end

        selectPull(selectedPull or "bold")
    end
end

function idleHuntController:showDetails(huntId)
    local hunt = self:getHuntById(huntId)
    if not hunt then return end
    selectedHuntId = huntId

    local dtView = self.ui and self.ui.detailsView
    if not dtView then return end

    -- Topo e Header
    if dtView.detailsTopBar and dtView.detailsTopBar.detailsTitle then
        dtView.detailsTopBar.detailsTitle:setText(string.format("Configurar Caçada: %s", hunt.name))
    end

    local header = dtView.detailCreatureHeader
    if header then
        if header.detailCreatureFrame and header.detailCreatureFrame.detailCreature then
            if hunt.looktype and hunt.looktype > 0 then
                header.detailCreatureFrame.detailCreature:setOutfit({ type = hunt.looktype })
                local cr = header.detailCreatureFrame.detailCreature:getCreature()
                if cr then cr:setStaticWalking(1000) end
            end
        end
        header.detailHuntName:setText(hunt.name)
        header.detailHuntDesc:setText(hunt.desc or "")
        header.detailHuntInfo:setText(string.format("Suprimentos: ~%d gp / turno | Nível Recomendado: %d | Foco: %s", tonumber(hunt.cost) or 10, tonumber(hunt.req_lvl or hunt.level) or 8, hunt.focus or "Balanced"))

        if header.detailRecordLabel then
            if (hunt.record_exp or 0) > 0 then
                header.detailRecordLabel:setText(string.format("Recorde Pessoal: %s XP/h | %s GP/h", formatNumber(hunt.record_exp), formatNumber(hunt.record_gp or 0)))
                header.detailRecordLabel:setColor("#00ddff")
            else
                header.detailRecordLabel:setText("Recorde Pessoal: Sem registro ainda")
                header.detailRecordLabel:setColor("#777777")
            end
        end
    end

    -- Renderizar Fraquezas e Resistências Elementais (7 Elementos)
    local elemRow = dtView.elementsPanel and dtView.elementsPanel.elementsRow
    if elemRow then
        elemRow:destroyChildren()
        local ELEM_DEFS = {
            { key = "physical", name = "Físico", color = "#cccccc" },
            { key = "fire",     name = "Fogo",   color = "#ff5533" },
            { key = "ice",      name = "Gelo",   color = "#66ccff" },
            { key = "earth",    name = "Terra",  color = "#88cc44" },
            { key = "energy",   name = "Energia",color = "#cc88ff" },
            { key = "holy",     name = "Sagrado",color = "#ffee66" },
            { key = "death",    name = "Morte",  color = "#cc44ff" },
        }

        for _, el in ipairs(ELEM_DEFS) do
            local val = (hunt.elements and hunt.elements[el.key]) or 0
            local badge = g_ui.createWidget("ElementBadge", elemRow)
            if badge then
                badge.elementLabel:setText(el.name)
                badge.elementLabel:setColor(el.color)

                local valStr = ""
                local valColor = "#888888"
                if val == -100 then
                    valStr = "Imune"
                    valColor = "#ff4444"
                elseif val < 0 then
                    valStr = string.format("%d%% Forte", val)
                    valColor = "#ffaa00"
                elseif val > 0 then
                    valStr = string.format("+%d%% Fraco", val)
                    valColor = "#00ff88"
                else
                    valStr = "Neutro (0%)"
                    valColor = "#aaaaaa"
                end

                badge.valueLabel:setText(valStr)
                badge.valueLabel:setColor(valColor)
            end
        end
    end

    -- Renderizar Drops da Hunt (Loot Table com Pegar vs Vender)
    local dropsList = dtView.dropsBoxPanel and dtView.dropsBoxPanel.detailDropsList
    if dropsList then
        dropsList:destroyChildren()
        if hunt.loot and #hunt.loot > 0 then
            for _, item in ipairs(hunt.loot) do
                local row = g_ui.createWidget("DropRowItem", dropsList)
                if row then
                    row.itemWidget:setItemId(item.id)
                    row.itemNameLabel:setText(item.name or "Item")
                    row.itemInfoLabel:setText(string.format("Valor: %s gp | Chance: %d%%", formatNumber(item.price or 0), item.chance or 0))

                    local tip = item.look or (item.name or "Item")
                    tip = tip .. string.format("\n------------------------\nChance de Drop: %d%%\nPreço de Venda: %s gp", item.chance or 0, formatNumber(item.price or 0))
                    row:setTooltip(tip)
                    row.itemWidget:setTooltip(tip)

                    local function applyRule(rule)
                        if rule == "keep" then
                            row.lockButton:setText("[LOCKED] Guardar (BP)")
                            row.lockButton:setColor("#00ff88")
                            row.lockButton:setTooltip("Item guardado com segurança na backpack.\nClique para marcar para Auto-Venda.")
                        else
                            row.lockButton:setText("[UNLOCKED] Vender (GP)")
                            row.lockButton:setColor("#ffd700")
                            row.lockButton:setTooltip("Item marcado para venda no Quick Sell e a cada 10m.\nClique para bloquear na backpack.")
                        end
                    end

                    local initialRule = itemRulesCache[item.id] or "keep"
                    applyRule(initialRule)

                    row.lockButton.onClick = function()
                        local current = itemRulesCache[item.id] or "keep"
                        local nextRule = (current == "keep") and "sell" or "keep"
                        itemRulesCache[item.id] = nextRule
                        applyRule(nextRule)
                        self:setLootRule(item.id, nextRule)
                    end
                end
            end
        else
            local empty = g_ui.createWidget("Label", dropsList)
            empty:setText("Nenhum dado de loot disponível.")
            empty:setColor("#777777")
        end
    end

    -- Solicitar verificação de requisitos
    self:requestRequirements(hunt.id)

    -- Botão Iniciar Caçada
    if dtView.startHuntButton then
        dtView.startHuntButton.onClick = function()
            self:startHunt(hunt.id, selectedPull)
        end
    end
end

function idleHuntController:getHuntById(id)
    id = tonumber(id) or 1
    for _, h in ipairs(huntsCache) do
        if h.id == id then return h end
    end
    return huntsCache[1]
end

-- =========================================================================
-- COMUNICAÇÃO DE REDE / OPCODES
-- =========================================================================
function idleHuntController:requestHunts()
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"get_hunts"}')
end

function idleHuntController:requestRequirements(huntId)
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"get_requirements","hunt_id":%d}', huntId))
end

function idleHuntController:startHunt(huntId, pull)
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end
    pull = pull or selectedPull or "bold"
    modules.game_textmessage.displayStatusMessage(string.format("Iniciando caçada IDLE (Intensidade: %s)...", string.upper(pull)))
    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"start_hunt","hunt_id":%d,"pull":%q}', huntId, pull))
end

function idleHuntController:stopHunt()
    if not g_game.isOnline() then return end
    local protocol = g_game.getProtocolGame()
    if not protocol then return end

    if stopCountdownEvent then return end

    local activeCard = self.ui and self.ui.dashboardView and self.ui.dashboardView.activeHuntCard
    local stopBtn = activeCard and activeCard.stopHuntButton

    local secondsLeft = 5
    if stopBtn then
        stopBtn:setEnabled(false)
        stopBtn:setText(string.format("Encerrando (%ds)...", secondsLeft))
    end

    local function countdown()
        secondsLeft = secondsLeft - 1
        if secondsLeft > 0 then
            if stopBtn then
                stopBtn:setText(string.format("Encerrando (%ds)...", secondsLeft))
            end
            stopCountdownEvent = scheduleEvent(countdown, 1000)
        else
            stopCountdownEvent = nil
            protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"stop_hunt"}')
            if stopBtn then
                stopBtn:setText("ENCERRAR CAÇADA")
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
        modules.game_textmessage.displayStatusMessage(string.format("Aguarde %d segundo(s) para usar o Quick Sell novamente.", quickSellCooldownTimer))
        return
    end

    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"quick_sell"}')
end

function idleHuntController:setLootRule(itemId, rule)
    setItemLootRule(itemId, rule)
end

-- =========================================================================
-- MANIPULADOR DE PACOTES (OPCODE 106)
-- =========================================================================
function idleHuntController:onOpcodeReceived(protocol, opcode, buffer)
    if opcode ~= OPCODE_IDLE_HUNT then return end

    local ok, data = pcall(function() return json.decode(buffer) end)
    if not ok or not data then return end

    local action = data.action

    if action == "hunts_list" then
        if data.hunts and #data.hunts > 0 then
            huntsCache = data.hunts
        end

        local staminaMins = data.stamina or 1440
        local maxStamina = data.max_stamina or 1440
        local hours = math.floor(staminaMins / 60)
        local mins = staminaMins % 60

        local sPanel = self.ui and self.ui.dashboardView and self.ui.dashboardView.staminaPanel
        if sPanel then
            sPanel.staminaLabel:setText(string.format("Stamina IDLE: %02dh %02dm", hours, mins))
            sPanel.staminaBar:setValue(staminaMins, 0, maxStamina)
        end

        inHunt = (data.in_hunt == true)
        currentHuntId = tonumber(data.active_hunt_id) or 0

        self:updateDashboardState()
        if currentView == "catalog" then
            self:filterHunts()
        end

    elseif action == "hunt_started" then
        inHunt = true
        currentHuntId = tonumber(data.hunt_id) or 1
        modules.game_textmessage.displayStatusMessage(string.format("Caçada IDLE iniciada: %s!", data.hunt_name or ""))

        self:switchView("dashboard")
        self:startAutoCombat()

    elseif action == "hunt_ended" then
        inHunt = false
        currentHuntId = 0
        self:stopAutoCombat()
        modules.game_textmessage.displayStatusMessage(data.reason or "Caçada IDLE finalizada.")

        self:switchView("dashboard")

    elseif action == "hunt_status" then
        local dView = self.ui and self.ui.dashboardView
        local aCard = dView and dView.activeHuntCard
        if aCard and aCard.activeStatsBox then
            local sb = aCard.activeStatsBox
            if sb.statXp then sb.statXp:setText(string.format("Experiência Ganha: +%s XP", formatNumber(data.xp_session or 0))) end
            if sb.statGold then sb.statGold:setText(string.format("Ouro / Loot Coletado: %s gp", formatNumber(data.pending_gold or 0))) end
            if sb.statSupplies then sb.statSupplies:setText(string.format("Suprimentos Gastos: %s gp", formatNumber(data.supplies_spent or 0))) end

            local rExp = data.rate_exp or 0
            local rGp = data.rate_gp or 0
            if sb.statRates then sb.statRates:setText(string.format("Taxa Atual: %s XP/h | %s GP/h", formatNumber(rExp), formatNumber(rGp))) end

            local elSec = data.elapsed or 0
            local elMins = math.floor(elSec / 60)
            local elRest = elSec % 60
            if sb.statTime then sb.statTime:setText(string.format("Tempo de Caçada: %02dm %02ds", elMins, elRest)) end

            local nextSec = data.next_autosell or 600
            local nMin = math.floor(nextSec / 60)
            local nRest = nextSec % 60
            if sb.statAutosell then sb.statAutosell:setText(string.format("Próxima Auto-Venda em: %02dm %02ds", nMin, nRest)) end
        end

        local staminaMins = data.idle_stamina or 1440
        local hours = math.floor(staminaMins / 60)
        local mins = staminaMins % 60
        local sPanel = dView and dView.staminaPanel
        if sPanel then
            sPanel.staminaLabel:setText(string.format("Stamina IDLE: %02dh %02dm", hours, mins))
            sPanel.staminaBar:setValue(staminaMins, 0, 1440)
        end

    elseif action == "requirements" then
        local dtView = self.ui and self.ui.detailsView
        local rPanel = dtView and dtView.reqPanel
        if rPanel then
            local meetsAll = (data.meets_all == true)
            if meetsAll then
                rPanel.reqSummaryLabel:setText("Requisitos de Sobrevivência: [ADEQUADO - Resgate 10% HP ATIVO]")
                rPanel.reqSummaryLabel:setColor("#00ff88")
            else
                rPanel.reqSummaryLabel:setText("Requisitos de Sobrevivência: [ABAIXO DO RECOMENDADO - Risco Real de Morte]")
                rPanel.reqSummaryLabel:setColor("#ff5555")
            end

            local lvlStr = string.format("Level: %d/%d [%s]", data.p_lvl or 0, data.r_lvl or 0, data.ok_lvl and "OK" or "FALTA")
            local atkStr = string.format("Atk: %d/%d [%s]", data.p_atk or 0, data.r_atk or 0, data.ok_atk and "OK" or "FALTA")
            local defStr = string.format("Def: %d/%d [%s]", data.p_def or 0, data.r_def or 0, data.ok_def and "OK" or "FALTA")
            local bankStr = string.format("Banco: %s/%s [%s]", formatNumber(data.p_bank or 0), formatNumber(data.r_bank or 0), data.ok_bank and "OK" or "FALTA")
            local potStr = string.format("Poções: %s", data.potions or "Health/Mana")

            rPanel.reqDetailsLabel:setText(string.format("%s | %s | %s | %s | %s", lvlStr, atkStr, defStr, bankStr, potStr))
        end

    elseif action == "quick_sell_result" then
        if (data.gold or 0) > 0 then
            local msg = string.format("Quick Sell concluído! Vendido(s) %d item(ns) por %s gold (creditado no banco).", data.count or 0, formatNumber(data.gold or 0))
            modules.game_textmessage.displayStatusMessage(msg)
            self:startQuickSellCooldown(data.cooldown or 5)
        else
            self:startQuickSellCooldown(0)
        end

    elseif action == "quick_sell_cooldown" then
        self:startQuickSellCooldown(data.remaining or 5)
    end
end

function idleHuntController:startQuickSellCooldown(seconds)
    quickSellCooldownTimer = seconds or 0
    if quickSellEvent then
        removeEvent(quickSellEvent)
        quickSellEvent = nil
    end

    local bBar = self.ui and self.ui.dashboardView and self.ui.dashboardView.dashboardBottomBar
    local qsBtn = bBar and bBar.quickSellButton
    if not qsBtn then return end

    if quickSellCooldownTimer <= 0 then
        qsBtn:setText("Quick Sell")
        qsBtn:setEnabled(true)
        return
    end

    qsBtn:setEnabled(false)
    qsBtn:setText(string.format("Quick Sell (%ds)", quickSellCooldownTimer))

    local function tick()
        if quickSellCooldownTimer > 0 then
            quickSellCooldownTimer = quickSellCooldownTimer - 1
            if qsBtn then
                if quickSellCooldownTimer > 0 then
                    qsBtn:setText(string.format("Quick Sell (%ds)", quickSellCooldownTimer))
                else
                    qsBtn:setText("Quick Sell")
                    qsBtn:setEnabled(true)
                end
            end
            if quickSellCooldownTimer > 0 then
                quickSellEvent = scheduleEvent(tick, 1000)
            end
        else
            if qsBtn then
                qsBtn:setText("Quick Sell")
                qsBtn:setEnabled(true)
            end
        end
    end

    quickSellEvent = scheduleEvent(tick, 1000)
end

-- =========================================================================
-- LOOP DE COMBATE TÁTICO AUTOMÁTICO (HOTKEYS IDLE)
-- =========================================================================
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

            -- 1. TARGET LOCK: Não troca de alvo enquanto o monstro atual estiver vivo!
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

            -- 2. AUTOMAÇÃO DE HOTKEYS IDLE
            local idleHotkeys = nil
            if modules.game_actionbar and modules.game_actionbar.IdleActionBar then
                idleHotkeys = modules.game_actionbar.IdleActionBar:getIdleHotkeys()
            end

            if idleHotkeys and #idleHotkeys > 0 then
                -- Trilha 1: Poções / Suprimentos
                if (now - lastPotionTime) >= 1000 then
                    for _, hk in ipairs(idleHotkeys) do
                        if hk.type == "object" and hk.itemId and hk.itemId > 0 then
                            local condMet = false
                            if hk.trigger == "always" then
                                condMet = true
                            elseif hk.trigger == "hp_under" then
                                condMet = (hpPercent <= (hk.triggerValue or 50))
                            elseif hk.trigger == "mp_under" then
                                condMet = (mpPercent <= (hk.triggerValue or 50))
                            elseif hk.trigger == "in_combat" then
                                condMet = inCombat
                            end

                            if condMet then
                                lastPotionTime = now
                                local protocol = g_game.getProtocolGame()
                                if protocol then
                                    protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"use_idle_supply","item_id":%d}', hk.itemId))
                                end
                                break
                            end
                        end
                    end
                end

                -- Trilha 2: Magias de Cura
                if (now - lastHealTime) >= 1000 then
                    for _, hk in ipairs(idleHotkeys) do
                        if hk.type == "spell" and hk.words and hk.words ~= "" then
                            local isHeal = string.find(string.lower(hk.words), "cura") or string.find(string.lower(hk.words), "exura")
                            if isHeal then
                                local condMet = false
                                if hk.trigger == "always" then
                                    condMet = true
                                elseif hk.trigger == "hp_under" then
                                    condMet = (hpPercent <= (hk.triggerValue or 50))
                                elseif hk.trigger == "mp_under" then
                                    condMet = (mpPercent <= (hk.triggerValue or 50))
                                elseif hk.trigger == "in_combat" then
                                    condMet = inCombat
                                end

                                if condMet then
                                    lastHealTime = now
                                    g_game.talk(hk.words)
                                    break
                                end
                            end
                        end
                    end
                end

                -- Trilha 3: Magias Ofensivas
                if (now - lastAttackSpellTime) >= 2000 and inCombat then
                    for _, hk in ipairs(idleHotkeys) do
                        if hk.type == "spell" and hk.words and hk.words ~= "" then
                            local isHeal = string.find(string.lower(hk.words), "cura") or string.find(string.lower(hk.words), "exura")
                            if not isHeal then
                                local condMet = false
                                if hk.trigger == "always" or hk.trigger == "in_combat" then
                                    condMet = true
                                elseif hk.trigger == "hp_under" then
                                    condMet = (hpPercent <= (hk.triggerValue or 50))
                                elseif hk.trigger == "mp_under" then
                                    condMet = (mpPercent <= (hk.triggerValue or 50))
                                end

                                if condMet then
                                    lastAttackSpellTime = now
                                    g_game.talk(hk.words)
                                    break
                                end
                            end
                        end
                    end
                end
            end

            -- 3. MOVIMENTAÇÃO / PATRULHA
            if nearestMonster and not nearestMonster:isDead() then
                local mPos = nearestMonster:getPosition()
                local dist = math.max(math.abs(pPos.x - mPos.x), math.abs(pPos.y - mPos.y))
                if dist > 1 and dist < 12 and (now - lastWanderTime) >= 600 then
                    lastWanderTime = now
                    g_game.walk(pPos:getFullPath(mPos))
                end
            end
        end)

        if not ok and err then
            print("[IDLE Hunt Auto-Combat Error]: " .. tostring(err))
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