local OPCODE_IDLE_HUNT = 106

local idleButton = nil
local huntsCache = {}
local activeFilter = "Todos"
local selectedHuntId = 1
local reqWindow = nil

local function formatNumber(n)
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

idleHuntController = Controller:new()
idleHuntController:setUI('idlehunt', modules.game_interface.getRootPanel())

function idleHuntController:onInit()
    self:registerExtendedOpcode(OPCODE_IDLE_HUNT, function(protocol, opcode, buffer)
        self:onOpcodeReceived(buffer)
    end)
end

function idleHuntController:onGameStart()
    if not idleButton then
        idleButton = modules.client_topmenu.addLeftGameButton(
            'idleHuntTopButton',
            tr('Caçadas IDLE'),
            '/images/topbuttons/questlog',
            function() self:toggle() end
        )
    end
    self:requestHunts()
end

function idleHuntController:onGameEnd()
    if idleButton then
        idleButton:destroy()
        idleButton = nil
    end
    if self.ui then
        self.ui:hide()
    end
    if reqWindow then
        reqWindow:destroy()
        reqWindow = nil
    end
end

function idleHuntController:toggle()
    if not self.ui then return end
    if self.ui:isVisible() then
        self.ui:hide()
        if reqWindow then reqWindow:hide() end
    else
        self.ui:show()
        self.ui:raise()
        self.ui:focus()
        self:requestHunts()
    end
end

function idleHuntController:requestHunts()
    if g_game.isOnline() then
        self:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"get_hunts"}')
    end
end

function idleHuntController:requestRequirements(huntId)
    if g_game.isOnline() then
        selectedHuntId = huntId
        self:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"get_requirements","hunt_id":%d}', huntId))
    end
end

function idleHuntController:startHunt(huntId)
    if g_game.isOnline() then
        self:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"start_hunt","hunt_id":%d}', huntId))
    end
end

function idleHuntController:stopHunt()
    if g_game.isOnline() then
        self:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"stop_hunt"}')
    end
end

function idleHuntController:onOpcodeReceived(buffer)
    local success, data = pcall(function() return json.decode(buffer) end)
    if not success or type(data) ~= "table" then
        return
    end

    local action = data.action

    if action == "hunts_list" then
        self:renderHuntsList(data)
    elseif action == "requirements" then
        self:renderRequirements(data)
    elseif action == "hunt_started" then
        if self.ui and self.ui.activeHuntBanner then
            self.ui.activeHuntBanner:show()
            self.ui.activeHuntBanner.activeInfo:setText("Caçando ativamente: " .. (data.hunt_name or ""))
        end
    elseif action == "hunt_ended" then
        if self.ui and self.ui.activeHuntBanner then
            self.ui.activeHuntBanner:hide()
        end
    elseif action == "hunt_status" then
        if self.ui and self.ui.activeHuntBanner then
            self.ui.activeHuntBanner:show()
            self.ui.activeHuntBanner.activeInfo:setText(string.format(
                "Em Caçada | HP: %d%% | XP Sessão: +%s | Suprimentos: %s gp",
                data.hp_percent or 100,
                formatNumber(tostring(data.xp_session or 0)),
                formatNumber(tostring(data.supplies_spent or 0))
            ))
            if data.idle_stamina and self.ui.staminaPanel then
                local st = data.idle_stamina
                self.ui.staminaPanel.staminaLabel:setText(string.format("Stamina IDLE: %02dh %02dm", math.floor(st / 60), st % 60))
                self.ui.staminaPanel.staminaBar:setPercent((st / 1440) * 100)
            end
        end
    end
end

function idleHuntController:renderHuntsList(data)
    if not self.ui then return end

    -- Atualizar Stamina IDLE
    local stamina = data.stamina or 1440
    local maxStamina = data.max_stamina or 1440
    self.ui.staminaPanel.staminaLabel:setText(string.format("Stamina IDLE: %02dh %02dm", math.floor(stamina / 60), stamina % 60))
    self.ui.staminaPanel.staminaBar:setPercent((stamina / maxStamina) * 100)

    -- Atualizar Banner Ativo
    if data.in_hunt then
        self.ui.activeHuntBanner:show()
        self.ui.activeHuntBanner.stopHuntButton.onClick = function() self:stopHunt() end
    else
        self.ui.activeHuntBanner:hide()
    end

    -- Criar Filtros
    local filterPanel = self.ui.filterPanel
    filterPanel:destroyChildren()

    local tiers = { "Todos", "1 - 20", "20 - 40", "40 - 80", "80 - 130", "130 - 200", "200 - 250", "250 - 300+" }
    for _, t in ipairs(tiers) do
        local btn = g_ui.createWidget("Button", filterPanel)
        btn:setText(t)
        btn:setWidth(t == "Todos" and 50 or 60)
        if t == activeFilter then
            btn:setColor("#ffd700")
        end
        btn.onClick = function()
            activeFilter = t
            self:filterHunts()
        end
    end

    -- Guardar hunts em cache e renderizar
    huntsCache = data.hunts or {}
    self:filterHunts()
end

function idleHuntController:filterHunts()
    local huntList = self.ui.huntList
    huntList:destroyChildren()

    for _, h in ipairs(huntsCache) do
        if activeFilter == "Todos" or h.tier == activeFilter then
            local card = g_ui.createWidget("HuntCard", huntList)
            card.huntTitle:setText(string.format("[%s] %s", h.tier, h.name))
            
            -- Tag de Foco
            local tagColor = "#00ff88"
            if h.focus == "Mais XP" then
                tagColor = "#ffcc00"
            elseif h.focus == "Mais Loot" then
                tagColor = "#00ddff"
            end
            card.focusTag:setText("[" .. h.focus .. "]")
            card.focusTag:setColor(tagColor)

            card.huntDesc:setText(h.desc)
            card.huntCost:setText(string.format("Suprimentos: ~%d gp / turno | Level Mínimo: %d", h.cost, h.req_lvl))

            -- Botão Requisitos
            card.reqButton.onClick = function()
                self:requestRequirements(h.id)
            end

            -- Botão Iniciar
            card.startButton.onClick = function()
                self:startHunt(h.id)
            end
        end
    end
end

function idleHuntController:renderRequirements(data)
    if not reqWindow then
        reqWindow = g_ui.displayUI('requirements')
    end

    reqWindow:show()
    reqWindow:raise()
    reqWindow:focus()

    local huntName = data.hunt_name or ("Hunt #" .. tostring(data.hunt_id))
    reqWindow:setText("Requisitos: " .. huntName)

    -- Status Geral (Banner)
    local meetsAll = data.meets_all
    local statusText = reqWindow.statusBanner.statusText
    if meetsAll then
        statusText:setText("🛡️ [SEGURO: Proteção 10% de HP ATIVA]")
        statusText:setColor("#00ff66")
    else
        statusText:setText("⚠️ [PERIGO: Abaixo dos Requisitos - Risco Real de Morte!]")
        statusText:setColor("#ff4444")
    end

    -- Checklist
    local pLvl = data.p_lvl or 0
    local rLvl = data.r_lvl or 0
    reqWindow.checklistPanel.lvlLabel:setText(string.format(
        "• Nível: Seu Level %d / Recomendado %d  [%s]",
        pLvl, rLvl, (data.ok_lvl and "OK" or "ABAIXO")
    ))
    reqWindow.checklistPanel.lvlLabel:setColor(data.ok_lvl and "#00ff66" or "#ff4444")

    local pAtk = data.p_atk or 0
    local rAtk = data.r_atk or 0
    reqWindow.checklistPanel.atkLabel:setText(string.format(
        "• Poder de Ataque / Arma: %d / Recomendado %d  [%s]",
        pAtk, rAtk, (data.ok_atk and "OK" or "ABAIXO")
    ))
    reqWindow.checklistPanel.atkLabel:setColor(data.ok_atk and "#00ff66" or "#ff4444")

    local pDef = data.p_def or 0
    local rDef = data.r_def or 0
    reqWindow.checklistPanel.defLabel:setText(string.format(
        "• Defesa Total (Armadura/Escudo): %d / Recomendado %d  [%s]",
        pDef, rDef, (data.ok_def and "OK" or "ABAIXO")
    ))
    reqWindow.checklistPanel.defLabel:setColor(data.ok_def and "#00ff66" or "#ff4444")

    local pBank = data.p_bank or 0
    local rBank = data.r_bank or 0
    reqWindow.checklistPanel.bankLabel:setText(string.format(
        "• Saldo Bancário para Suprimentos: %s gp / Mínimo %s gp  [%s]",
        formatNumber(tostring(pBank)), formatNumber(tostring(rBank)), (data.ok_bank and "OK" or "ABAIXO")
    ))
    reqWindow.checklistPanel.bankLabel:setColor(data.ok_bank and "#00ff66" or "#ff4444")

    reqWindow.checklistPanel.potionsLabel:setText("• Poções Sugeridas: " .. (data.potions or "Health / Mana Potion"))

    -- Botão Iniciar a partir do Modal
    reqWindow.startFromReqButton.onClick = function()
        self:startHunt(data.hunt_id)
        reqWindow:hide()
    end
end