local OPCODE_BANK_BALANCE = 105

local function formatNumber(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

bankBalanceController = Controller:new()
bankBalanceController:setUI('bankbalance', modules.game_interface.getMainRightPanel())

function bankBalanceController:onInit()
    -- 1. Register Extended Opcode 105 for server bank events
    self:registerExtendedOpcode(OPCODE_BANK_BALANCE, function(protocol, opcode, buffer)
        self:onBankBalanceReceived(buffer)
    end)

    -- 2. Connect to native CipSoft Resource Balance events
    connect(g_game, {
        onGameStart = function()
            self:updateDisplayFromPlayer()
            self:requestBalance()
        end,
        onGameEnd = function()
            self:updateBalance(0)
        end,
        onResourcesBalanceChange = function(balance, oldBalance, resType)
            local bankType = (ResourceTypes and ResourceTypes.BANK_BALANCE) or 0
            if resType == bankType then
                self:updateBalance(balance)
            end
        end,
        -- Trigger balance check when loot or items change in backpack/containers
        onContainerAddItem = function() self:onInventoryChanged() end,
        onContainerRemoveItem = function() self:onInventoryChanged() end,
        onContainerUpdateItem = function() self:onInventoryChanged() end,
    })

    -- 3. Connect to local player inventory changes
    connect(LocalPlayer, {
        onInventoryChange = function() self:onInventoryChanged() end,
    })

    -- 4. Fast reactive cycle (every 1.5s) to guarantee real-time sync with server
    self.pollEvent = cycleEvent(function()
        if g_game.isOnline() then
            self:updateDisplayFromPlayer()
            self:requestBalance()
        end
    end, 1500)
end

function bankBalanceController:onTerminate()
    if self.pollEvent then
        removeEvent(self.pollEvent)
        self.pollEvent = nil
    end
end

function bankBalanceController:onInventoryChanged()
    if g_game.isOnline() then
        self:updateDisplayFromPlayer()
        self:requestBalance()
    end
end

function bankBalanceController:updateDisplayFromPlayer()
    local player = g_game.getLocalPlayer()
    if player and player.getResourceBalance then
        local bankType = (ResourceTypes and ResourceTypes.BANK_BALANCE) or 0
        local bank = player:getResourceBalance(bankType)
        if bank and bank >= 0 then
            self:updateBalance(bank)
        end
    end
end

function bankBalanceController:requestBalance()
    if g_game.isOnline() then
        self:sendExtendedOpcode(OPCODE_BANK_BALANCE, "get")
    end
end

function bankBalanceController:updateBalance(balance)
    if self.ui and self.ui.bankBox and self.ui.bankBox.balanceText then
        local num = math.floor(tonumber(balance) or 0)
        local formatted = formatNumber(num)
        self.ui.bankBox.balanceText:setText("Bank: " .. formatted .. " gp")
    end
end

function bankBalanceController:onBankBalanceReceived(buffer)
    local balance = nil
    if type(buffer) == "string" then
        balance = tonumber(buffer:match('"balance"%s*:%s*(%d+)'))
    end
    if balance == nil then
        local success, data = pcall(function() return json.decode(buffer) end)
        if success and type(data) == "table" and data.balance ~= nil then
            balance = tonumber(data.balance)
        end
    end
    if balance == nil then
        balance = tonumber(buffer)
    end
    if balance ~= nil then
        self:updateBalance(balance)
    end
end