local OPCODE_BANK_BALANCE = 105

local function formatNumber(n)
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

bankBalanceController = Controller:new()
bankBalanceController:setUI('bankbalance', modules.game_interface.getMainRightPanel())

function bankBalanceController:onInit()
    self:registerExtendedOpcode(OPCODE_BANK_BALANCE, function(protocol, opcode, buffer)
        self:onBankBalanceReceived(buffer)
    end)
end

function bankBalanceController:onGameStart()
    self:requestBalance()
end

function bankBalanceController:requestBalance()
    if g_game.isOnline() then
        self:sendExtendedOpcode(OPCODE_BANK_BALANCE, "get")
    end
end

function bankBalanceController:onBankBalanceReceived(buffer)
    local balance = 0
    local success, data = pcall(function() return json.decode(buffer) end)
    if success and type(data) == "table" and data.balance ~= nil then
        balance = tonumber(data.balance) or 0
    else
        balance = tonumber(buffer) or 0
    end

    if self.ui and self.ui.bankBox and self.ui.bankBox.balanceText then
        local formatted = formatNumber(tostring(math.floor(balance)))
        self.ui.bankBox.balanceText:setText("Bank: " .. formatted .. " gp")
    end
end