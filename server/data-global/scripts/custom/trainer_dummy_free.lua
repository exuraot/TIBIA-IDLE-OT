--[[
    Exura OT - Sistema de Treinamento Clássico Livre em Dummies
    Permite treinar com a arma equipada ao clicar com o botão direito no dummy,
    avançando skills e shielding na taxa normal de combate (sem consumir exercise weapons).
]]

_G.OnClassicDummyTraining = _G.OnClassicDummyTraining or {}

local DUMMY_IDS = {
	5787, 5788,           -- Classic training dummy
	15710,                -- Target dummy
	28558, 28565,         -- Exercise dummy
	28559, 28560,         -- Ferumbras exercise dummy
	28561, 28562,         -- Demon exercise dummy
	28563, 28564,         -- Monk exercise dummy
	50435, 50436,         -- Wooden dummy
}

local function stopDummyTraining(playerId, sendMsg, msg)
	local session = _G.OnClassicDummyTraining[playerId]
	if session then
		if session.event then
			stopEvent(session.event)
		end
		_G.OnClassicDummyTraining[playerId] = nil
	end

	local player = Player(playerId)
	if player and sendMsg then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg or "Você parou de treinar.")
	end
end

local function getEquippedCombatGear(player)
	local leftItem = player:getSlotItem(CONST_SLOT_LEFT)
	local rightItem = player:getSlotItem(CONST_SLOT_RIGHT)

	local weaponItem = nil
	local hasShield = false

	local function checkItem(item)
		if not item then return end
		local iType = item:getType()
		local wType = iType:getWeaponType()
		if wType == WEAPON_SHIELD then
			hasShield = true
		elseif wType ~= WEAPON_NONE and not weaponItem then
			weaponItem = item
		end
	end

	checkItem(leftItem)
	checkItem(rightItem)

	local skillType = SKILL_FIST
	local projectileEffect = nil
	local isWand = false
	local isDistance = false

	if weaponItem then
		local wType = weaponItem:getType():getWeaponType()
		if wType == WEAPON_SWORD then
			skillType = SKILL_SWORD
		elseif wType == WEAPON_AXE then
			skillType = SKILL_AXE
		elseif wType == WEAPON_CLUB then
			skillType = SKILL_CLUB
		elseif wType == WEAPON_DISTANCE or wType == WEAPON_MISSILE then
			skillType = SKILL_DISTANCE
			isDistance = true
			projectileEffect = CONST_ANI_SIMPLEARROW
		elseif wType == WEAPON_WAND then
			skillType = SKILL_MAGLEVEL
			isWand = true
			projectileEffect = CONST_ANI_FIRE
		else
			skillType = SKILL_FIST
		end
	end

	return skillType, hasShield, isDistance, isWand, projectileEffect
end

local function classicDummyTrainingLoop(playerId, dummyPos, dummyId)
	local session = _G.OnClassicDummyTraining[playerId]
	if not session then
		return
	end

	local player = Player(playerId)
	if not player then
		_G.OnClassicDummyTraining[playerId] = nil
		return
	end

	-- Verificar se o jogador se moveu da posição inicial
	local currentPos = player:getPosition()
	if currentPos ~= session.startPos then
		stopDummyTraining(playerId, true, "Você se moveu e interrompeu o treino.")
		return
	end

	-- Verificar se o dummy ainda está na posição
	local tile = Tile(dummyPos)
	local dummyItem = tile and tile:getItemById(dummyId)
	if not dummyItem then
		stopDummyTraining(playerId, true, "O dummy de treino não está mais lá.")
		return
	end

	-- Identificar equipamentos atuais
	local skillType, hasShield, isDistance, isWand, projectileEffect = getEquippedCombatGear(player)

	-- Executar avanço de skill
	if isWand then
		-- Treino de Magic Level para varinhas (gasto de mana moderado de treino)
		local currentMana = player:getMana()
		if currentMana >= 5 then
			player:addMana(-5)
			player:addManaSpent(5, true)
		else
			-- Sem mana, treina punho
			player:addSkillTries(SKILL_FIST, 1, true)
		end
	else
		-- Avanço padrão de combate corporal ou distância (1 try com multiplicador de stages do server)
		player:addSkillTries(skillType, 1, true)
	end

	-- Treinar defesa se estiver de escudo equipado
	if hasShield then
		player:addSkillTries(SKILL_SHIELD, 1, true)
		currentPos:sendMagicEffect(CONST_ME_BLOCKHIT)
	end

	-- Efeitos visuais de impacto no dummy
	if projectileEffect then
		currentPos:sendDistanceEffect(dummyPos, projectileEffect)
	end

	-- Alternar entre impacto de sangue/faísca no dummy
	local hitEffect = (math.random(1, 100) <= 65) and CONST_ME_HITAREA or CONST_ME_BLOCKHIT
	dummyPos:sendMagicEffect(hitEffect)

	-- Agendar próximo turno de ataque (2.0 segundos = 1 turno oficial do Tibia)
	session.event = addEvent(classicDummyTrainingLoop, 2000, playerId, dummyPos, dummyId)
end

local dummyAction = Action()

function dummyAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local playerId = player:getId()

	-- Se já está treinando, o clique direito cancela o treino
	if _G.OnClassicDummyTraining[playerId] then
		stopDummyTraining(playerId, true, "Você encerrou o treino no dummy.")
		return true
	end

	-- Parar treino de exercise weapons se estiver ativo
	if _G.OnExerciseTraining and _G.OnExerciseTraining[playerId] then
		stopEvent(_G.OnExerciseTraining[playerId].event)
		_G.OnExerciseTraining[playerId] = nil
	end

	local playerPos = player:getPosition()
	local dummyPos = item:getPosition()
	local skillType, hasShield, isDistance = getEquippedCombatGear(player)

	-- Validação de distância: corpo a corpo exige adjacência (<= 1 sqm), distância até 4 sqm
	local maxDist = isDistance and 4 or 1
	if playerPos:getDistance(dummyPos) > maxDist then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Você precisa estar mais perto do dummy para treinar.")
		return true
	end

	-- Iniciar sessão de treino
	_G.OnClassicDummyTraining[playerId] = {
		startPos = playerPos,
		dummyPos = dummyPos,
		dummyId = item:getId(),
		event = nil,
	}

	player:sendTextMessage(
		MESSAGE_STATUS_CONSOLE_BLUE,
		"Você iniciou o treino clássico no dummy. Para encerrar, mova-se ou clique com o botão direito no dummy novamente."
	)
	dummyPos:sendMagicEffect(CONST_ME_HITAREA)

	-- Iniciar o primeiro ciclo
	_G.OnClassicDummyTraining[playerId].event = addEvent(classicDummyTrainingLoop, 2000, playerId, dummyPos, item:getId())
	return true
end

-- Registrar a ação para todos os IDs de dummies
for _, dummyId in ipairs(DUMMY_IDS) do
	dummyAction:id(dummyId)
end

dummyAction:register()
