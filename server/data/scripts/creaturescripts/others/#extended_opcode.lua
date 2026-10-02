local OPCODE_LANGUAGE = 1
local OPCODE_BANK_BALANCE = 105

local extendedOpcode = CreatureEvent("ExtendedOpcode")

function extendedOpcode.onExtendedOpcode(player, opcode, buffer)
	if opcode == OPCODE_LANGUAGE then
		-- otclient language
		if buffer == "en" or buffer == "pt" then
			-- player:setStorageValue(SOME_STORAGE_ID, SOME_VALUE)
		end
	elseif opcode == OPCODE_BANK_BALANCE then
		player:sendBankBalance()
	end
end

extendedOpcode:register()
