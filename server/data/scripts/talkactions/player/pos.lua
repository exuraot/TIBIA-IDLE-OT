local posTalk = TalkAction("!pos")

function posTalk.onSay(player, words, param)
	local p = player:getPosition()
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Sua posição atual é: X=%d, Y=%d, Z=%d", p.x, p.y, p.z))
	return true
end

posTalk:separator(" ")
posTalk:register()
