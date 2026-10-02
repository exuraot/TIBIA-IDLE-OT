--[[
    Exura OT - Sistema de Caçadas IDLE Instanciadas & Stamina IDLE
    - Hunts organizadas por faixas de nível (1-20 até 300+)
    - Foco em EXP ou Loot
    - Débito de suprimentos (poções/runas) direto do saldo bancário a preço de NPC
    - Taxas: -20% de EXP (0.8x) e 100% de Loot
    - Stamina IDLE: dreno 3x mais lento que a caçada normal
    - Comparador de Requisitos:
        * Cumpre 100% dos requisitos -> Ejeção de emergência (salvamento) com 10% de HP.
        * Abaixo dos requisitos -> Risco real de morte normal.
    - Opcode de Comunicação: 106 (OPCODE_IDLE_HUNT)
]]

_G.OnIdleHunt = _G.OnIdleHunt or {}

local OPCODE_IDLE_HUNT = 106
local STORAGE_IDLE_STAMINA = 95000     -- Armazena minutos restantes de Stamina IDLE
local MAX_IDLE_STAMINA = 1440          -- 24 horas (em minutos)

-- Tabela oficial de Hunts por Faixas de Nível (Tiers 1 a 7)
local IDLE_HUNTS = {
	-- Tier 1: Level 1 a 20 (Iniciante)
	{
		id = 1,
		name = "Rotworms de Darashia",
		tier = "1 - 20",
		level = 8,
		focus = "Balanceado",
		desc = "Caçada clássica de Rotworms e Carrion Worms. Ideal para começar.",
		monster = "Rotworm",
		baseExp = 40,
		supplyCostPerTurn = 10,
		reqLevel = 8,
		reqAttack = 15,
		reqDefense = 12,
		reqBank = 1000,
		reqPotions = "Health / Mana Potion",
		damageMin = 5,
		damageMax = 18,
		healAmount = 25,
	},
	{
		id = 2,
		name = "Amazon Camp (Venore)",
		tier = "1 - 20",
		level = 15,
		focus = "Mais Loot",
		desc = "Amazons e Valkyries com drop frequente de Protective Charms.",
		monster = "Valkyrie",
		baseExp = 85,
		supplyCostPerTurn = 15,
		reqLevel = 15,
		reqAttack = 22,
		reqDefense = 18,
		reqBank = 2000,
		reqPotions = "Health / Mana Potion",
		damageMin = 10,
		damageMax = 30,
		healAmount = 35,
	},

	-- Tier 2: Level 20 a 40 (Básico)
	{
		id = 3,
		name = "Cyclopolis (Edron)",
		tier = "20 - 40",
		level = 25,
		focus = "Mais XP",
		desc = "Cyclops e Cyclops Drones em grande densidade. Excelente EXP.",
		monster = "Cyclops",
		baseExp = 150,
		supplyCostPerTurn = 35,
		reqLevel = 25,
		reqAttack = 30,
		reqDefense = 25,
		reqBank = 5000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 25,
		damageMax = 65,
		healAmount = 70,
	},
	{
		id = 4,
		name = "Minotaur Pyramid (Darashia)",
		tier = "20 - 40",
		level = 30,
		focus = "Mais Loot",
		desc = "Minotaur Guards e Archers. Alto retorno em Minotaur Leather.",
		monster = "Minotaur Guard",
		baseExp = 160,
		supplyCostPerTurn = 40,
		reqLevel = 30,
		reqAttack = 34,
		reqDefense = 28,
		reqBank = 6000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 30,
		damageMax = 75,
		healAmount = 80,
	},

	-- Tier 3: Level 40 a 80 (Intermediário)
	{
		id = 5,
		name = "Yalahar Dragon Lair",
		tier = "40 - 80",
		level = 50,
		focus = "Mais XP",
		desc = "Dragons e Dragon Hatchlings. Rush de experiência clássico.",
		monster = "Dragon",
		baseExp = 700,
		supplyCostPerTurn = 90,
		reqLevel = 50,
		reqAttack = 42,
		reqDefense = 35,
		reqBank = 15000,
		reqPotions = "Strong Potions & Fire Protection",
		damageMin = 60,
		damageMax = 150,
		healAmount = 160,
	},
	{
		id = 6,
		name = "Giant Spider Caves",
		tier = "40 - 80",
		level = 65,
		focus = "Mais Loot",
		desc = "Giant Spiders agressivas com chances de Spider Silk e Knight Set.",
		monster = "Giant Spider",
		baseExp = 750,
		supplyCostPerTurn = 110,
		reqLevel = 65,
		reqAttack = 46,
		reqDefense = 38,
		reqBank = 20000,
		reqPotions = "Great Potions",
		damageMin = 80,
		damageMax = 200,
		healAmount = 210,
	},

	-- Tier 4: Level 80 a 130 (Avançado)
	{
		id = 7,
		name = "Fenrock Dragon Lords",
		tier = "80 - 130",
		level = 90,
		focus = "Mais XP",
		desc = "Dragon Lords furiosos. Foco absoluto em rush de nível.",
		monster = "Dragon Lord",
		baseExp = 2100,
		supplyCostPerTurn = 200,
		reqLevel = 90,
		reqAttack = 50,
		reqDefense = 42,
		reqBank = 35000,
		reqPotions = "Great Potions & Magias de Área",
		damageMin = 150,
		damageMax = 380,
		healAmount = 400,
	},
	{
		id = 8,
		name = "Seacrest Grounds",
		tier = "80 - 130",
		level = 110,
		focus = "Balanceado",
		desc = "Sea Serpents e Young Sea Serpents. Ótima XP e lucro constante.",
		monster = "Sea Serpent",
		baseExp = 2300,
		supplyCostPerTurn = 220,
		reqLevel = 110,
		reqAttack = 52,
		reqDefense = 44,
		reqBank = 40000,
		reqPotions = "Great Potions",
		damageMin = 160,
		damageMax = 390,
		healAmount = 410,
	},

	-- Tier 5: Level 130 a 200 (Master)
	{
		id = 9,
		name = "Banuta Deeper (Medusa & Serpents)",
		tier = "130 - 200",
		level = 140,
		focus = "Mais Loot",
		desc = "Medusas e Serpent Spawns. Fartura em joias, rares e itens caros.",
		monster = "Medusa",
		baseExp = 3800,
		supplyCostPerTurn = 380,
		reqLevel = 140,
		reqAttack = 54,
		reqDefense = 46,
		reqBank = 60000,
		reqPotions = "Ultimate Potions",
		damageMin = 220,
		damageMax = 520,
		healAmount = 550,
	},
	{
		id = 10,
		name = "Grim Reapers (Drefia)",
		tier = "130 - 200",
		level = 160,
		focus = "Mais XP",
		desc = "Ceifadores implacáveis. Taxa altíssima de experiência por hora.",
		monster = "Grim Reaper",
		baseExp = 5500,
		supplyCostPerTurn = 450,
		reqLevel = 160,
		reqAttack = 56,
		reqDefense = 48,
		reqBank = 80000,
		reqPotions = "Ultimate Potions",
		damageMin = 280,
		damageMax = 680,
		healAmount = 700,
	},

	-- Tier 6: Level 200 a 250 (Expert)
	{
		id = 11,
		name = "Roshamuul Valley",
		tier = "200 - 250",
		level = 200,
		focus = "Mais Loot",
		desc = "Frazzlemaws e Silencers. Alto risco e lucros gigantescos em Clusters.",
		monster = "Frazzlemaw",
		baseExp = 6800,
		supplyCostPerTurn = 650,
		reqLevel = 200,
		reqAttack = 58,
		reqDefense = 50,
		reqBank = 120000,
		reqPotions = "Ultimate / Supreme Potions",
		damageMin = 350,
		damageMax = 850,
		healAmount = 880,
	},
	{
		id = 12,
		name = "Oramond West (Glooth Plains)",
		tier = "200 - 250",
		level = 220,
		focus = "Mais XP",
		desc = "Quaras, Devourers e Glooth Golems. Ritmo frenético de caça.",
		monster = "Glooth Golem",
		baseExp = 7200,
		supplyCostPerTurn = 700,
		reqLevel = 220,
		reqAttack = 60,
		reqDefense = 52,
		reqBank = 150000,
		reqPotions = "Supreme Potions",
		damageMin = 380,
		damageMax = 900,
		healAmount = 930,
	},

	-- Tier 7: Level 250 a 300+ (Endgame)
	{
		id = 13,
		name = "Cobra Bastion",
		tier = "250 - 300+",
		level = 270,
		focus = "Balanceado",
		desc = "Cobras de elite. Desafio supremo com itens raros de endgame.",
		monster = "Cobra Assassin",
		baseExp = 9500,
		supplyCostPerTurn = 900,
		reqLevel = 270,
		reqAttack = 62,
		reqDefense = 54,
		reqBank = 200000,
		reqPotions = "Supreme Potions & Imbuements",
		damageMin = 480,
		damageMax = 1150,
		healAmount = 1200,
	},
	{
		id = 14,
		name = "Issavi Sphinxes",
		tier = "250 - 300+",
		level = 300,
		focus = "Mais XP",
		desc = "Sphinxes e Crypt Wardens em Issavi. A experiência máxima do servidor.",
		monster = "Sphinx",
		baseExp = 12000,
		supplyCostPerTurn = 1100,
		reqLevel = 300,
		reqAttack = 65,
		reqDefense = 56,
		reqBank = 250000,
		reqPotions = "Supreme Potions",
		damageMin = 550,
		damageMax = 1350,
		healAmount = 1400,
	},
}

-- Funções Auxiliares de Stamina IDLE
local function getPlayerIdleStamina(player)
	local cur = player:getStorageValue(STORAGE_IDLE_STAMINA)
	if cur < 0 then
		cur = MAX_IDLE_STAMINA
		player:setStorageValue(STORAGE_IDLE_STAMINA, cur)
	end
	return cur
end

local function setPlayerIdleStamina(player, minutes)
	minutes = math.max(0, math.min(MAX_IDLE_STAMINA, minutes))
	player:setStorageValue(STORAGE_IDLE_STAMINA, minutes)
	return minutes
end

-- Cálculo de Poder de Combate Real do Jogador (Atk da arma + Defesa do Set)
local function calculatePlayerStats(player)
	local leftItem = player:getSlotItem(CONST_SLOT_LEFT)
	local rightItem = player:getSlotItem(CONST_SLOT_RIGHT)
	local headItem = player:getSlotItem(CONST_SLOT_HEAD)
	local armorItem = player:getSlotItem(CONST_SLOT_ARMOR)
	local legsItem = player:getSlotItem(CONST_SLOT_LEGS)
	local feetItem = player:getSlotItem(CONST_SLOT_FEET)

	local attackValue = 10
	local defenseValue = 0

	local function addArmor(item)
		if item then
			local it = item:getType()
			defenseValue = defenseValue + (it:getArmor() or 0)
			if it:getDefense() > 0 then
				defenseValue = defenseValue + it:getDefense()
			end
		end
	end

	addArmor(headItem)
	addArmor(armorItem)
	addArmor(legsItem)
	addArmor(feetItem)

	local function checkWeapon(item)
		if item then
			local it = item:getType()
			if it:getWeaponType() == WEAPON_SHIELD then
				defenseValue = defenseValue + (it:getDefense() or 0)
			elseif it:getWeaponType() ~= WEAPON_NONE then
				local atk = it:getAttack() or 0
				if atk > attackValue then
					attackValue = atk
				end
			end
		end
	end

	checkWeapon(leftItem)
	checkWeapon(rightItem)

	-- Bônus de Magic Level para mages
	local ml = player:getMagicLevel() or 0
	if ml > 30 and (attackValue < ml) then
		attackValue = ml
	end

	return {
		level = player:getLevel(),
		attack = attackValue,
		defense = defenseValue,
		bankBalance = player:getBankBalance(),
	}
end

-- Avaliação dos Requisitos da Hunt
local function evaluateHuntRequirements(player, hunt)
	local stats = calculatePlayerStats(player)
	local meetsLevel = stats.level >= hunt.reqLevel
	local meetsAttack = stats.attack >= hunt.reqAttack
	local meetsDefense = stats.defense >= hunt.reqDefense
	local meetsBank = stats.bankBalance >= hunt.reqBank

	local meetsAll = meetsLevel and meetsAttack and meetsDefense and meetsBank

	return meetsAll, {
		level = { player = stats.level, required = hunt.reqLevel, ok = meetsLevel },
		attack = { player = stats.attack, required = hunt.reqAttack, ok = meetsAttack },
		defense = { player = stats.defense, required = hunt.reqDefense, ok = meetsDefense },
		bank = { player = stats.bankBalance, required = hunt.reqBank, ok = meetsBank },
		potions = hunt.reqPotions,
	}
end

-- Finalizar Caçada IDLE
local function stopIdleHunt(playerId, reason, isEmergency)
	local session = _G.OnIdleHunt[playerId]
	if session then
		if session.event then
			stopEvent(session.event)
		end
		_G.OnIdleHunt[playerId] = nil
	end

	local player = Player(playerId)
	if player then
		player:teleportTo(player:getTown():getTemplePosition())
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)

		local msg = reason or "Caçada IDLE finalizada."
		if isEmergency then
			player:sendTextMessage(
				MESSAGE_EVENT_ADVANCE,
				"🛡️ [RESGATE IDLE]: Sua vida caiu abaixo de 10%! Como você cumpriu todos os requisitos da caçada, o sistema de emergência te resgatou com segurança para o Templo!"
			)
		else
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		end

		-- Notificar cliente via Opcode 106
		if player:isUsingOtClient() then
			player:sendExtendedOpcode(
				OPCODE_IDLE_HUNT,
				string.format(
					'{"action":"hunt_ended","reason":%q,"emergency":%s}',
					msg,
					isEmergency and "true" or "false"
				)
			)
		end
	end
end

-- Ciclo de Combate IDLE (a cada 2 segundos)
local function idleCombatLoop(playerId, huntId)
	local session = _G.OnIdleHunt[playerId]
	if not session then
		return
	end

	local player = Player(playerId)
	if not player then
		_G.OnIdleHunt[playerId] = nil
		return
	end

	local hunt = nil
	for _, h in ipairs(IDLE_HUNTS) do
		if h.id == huntId then
			hunt = h
			break
		end
	end

	if not hunt then
		stopIdleHunt(playerId, "Hunt inválida.", false)
		return
	end

	-- Verificar Stamina IDLE
	local curStamina = getPlayerIdleStamina(player)
	if curStamina <= 0 then
		stopIdleHunt(playerId, "Sua Stamina IDLE acabou! Caçada encerrada.", false)
		return
	end

	-- 1. Dedução de Suprimentos diretamente do Banco (a preço de NPC)
	local bankBalance = player:getBankBalance()
	if bankBalance < hunt.supplyCostPerTurn then
		player:sendTextMessage(
			MESSAGE_FAILURE,
			"Seu saldo bancário esgotou! Sem suprimentos para se curar na caçada."
		)
	else
		player:removeMoneyBank(hunt.supplyCostPerTurn)
		session.suppliesSpent = session.suppliesSpent + hunt.supplyCostPerTurn
	end

	-- 2. Dano Recebido dos Monstros
	local damage = math.random(hunt.damageMin, hunt.damageMax)
	local currentHealth = player:getHealth()
	local maxHealth = player:getMaxHealth()

	-- Cura automática do player via poções/magias debitadas
	if bankBalance >= hunt.supplyCostPerTurn then
		local heal = math.min(hunt.healAmount, maxHealth - currentHealth)
		if heal > 0 then
			player:addHealth(heal)
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		end
	end

	-- Aplicar dano real do monstro
	player:addHealth(-damage)
	player:getPosition():sendMagicEffect(CONST_ME_HITAREA)

	-- 3. Verificação de Saúde Crítica (Regra de Ouro do Risco & Requisitos)
	local healthPercent = (player:getHealth() / maxHealth) * 100
	if healthPercent <= 10 then
		if session.meetsRequirements then
			-- Cumpriu todos os requisitos: Ejeção de Emergência Salva o Jogador
			stopIdleHunt(playerId, "Ejeção de emergência aos 10% de HP.", true)
			return
		else
			-- NÃO cumpriu os requisitos: Corre risco real de morte!
			if player:getHealth() <= 0 then
				_G.OnIdleHunt[playerId] = nil
				-- O jogador morre normalmente pelas regras do jogo
				return
			end
		end
	end

	-- 4. Ganho de Experiência (-20% de XP = multiplicador 0.8x)
	local expGained = math.floor(hunt.baseExp * 0.8)
	player:addExperience(expGained, true)
	session.xpGained = session.xpGained + expGained

	-- 5. Consumo de Stamina IDLE (1 minuto a cada 3 minutos reais de caçada = dreno 3x mais lento)
	session.turnCount = (session.turnCount or 0) + 1
	if session.turnCount >= 90 then -- 90 turnos de 2s = 180 segundos = 3 minutos
		session.turnCount = 0
		curStamina = setPlayerIdleStamina(player, curStamina - 1)
	end

	-- 6. Telemetria e atualização para o Client via Opcode 106
	if player:isUsingOtClient() and (session.turnCount % 3 == 0) then
		local statusJson = string.format(
			'{"action":"hunt_status","hunt_id":%d,"hp_percent":%d,"xp_session":%d,"supplies_spent":%d,"idle_stamina":%d}',
			huntId,
			math.floor((player:getHealth() / maxHealth) * 100),
			session.xpGained,
			session.suppliesSpent,
			curStamina
		)
		player:sendExtendedOpcode(OPCODE_IDLE_HUNT, statusJson)
	end

	-- Agendar próximo turno de caçada (2.0 segundos)
	session.event = addEvent(idleCombatLoop, 2000, playerId, huntId)
end

-- Iniciar Caçada IDLE
local function startIdleHunt(player, huntId)
	local playerId = player:getId()

	if _G.OnIdleHunt[playerId] then
		player:sendTextMessage(MESSAGE_FAILURE, "Você já está em uma caçada IDLE.")
		return false
	end

	local hunt = nil
	for _, h in ipairs(IDLE_HUNTS) do
		if h.id == huntId then
			hunt = h
			break
		end
	end

	if not hunt then
		player:sendTextMessage(MESSAGE_FAILURE, "Hunt não encontrada.")
		return false
	end

	local curStamina = getPlayerIdleStamina(player)
	if curStamina <= 0 then
		player:sendTextMessage(MESSAGE_FAILURE, "Você não tem Stamina IDLE disponível.")
		return false
	end

	local meetsAll, reqDetails = evaluateHuntRequirements(player, hunt)

	-- Registrar sessão
	_G.OnIdleHunt[playerId] = {
		huntId = huntId,
		meetsRequirements = meetsAll,
		xpGained = 0,
		suppliesSpent = 0,
		turnCount = 0,
		event = nil,
	}

	local pzPos = player:getPosition()
	player:sendTextMessage(
		MESSAGE_STATUS_CONSOLE_BLUE,
		string.format(
			"Caçada IDLE iniciada: %s. Proteção de Emergência 10%% HP: %s.",
			hunt.name,
			meetsAll and "ATIVA" or "DESATIVADA (Abaixo dos Requisitos)"
		)
	)

	-- Notificar cliente
	if player:isUsingOtClient() then
		player:sendExtendedOpcode(
			OPCODE_IDLE_HUNT,
			string.format(
				'{"action":"hunt_started","hunt_id":%d,"hunt_name":%q,"meets_req":%s}',
				huntId,
				hunt.name,
				meetsAll and "true" or "false"
			)
		)
	end

	-- Iniciar loop
	_G.OnIdleHunt[playerId].event = addEvent(idleCombatLoop, 2000, playerId, huntId)
	return true
end

-- Manipulador de Opcode Estendido 106 para o Sistema IDLE
local idleOpcodeEvent = CreatureEvent("IdleHuntExtendedOpcode")

function idleOpcodeEvent.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= OPCODE_IDLE_HUNT then
		return
	end

	local action = buffer
	local huntId = 1

	-- Tentar parsing básico de JSON/string
	if buffer:find("get_hunts") then
		action = "get_hunts"
	elseif buffer:find("get_requirements") then
		action = "get_requirements"
		local id = buffer:match('"hunt_id"%s*:%s*(%d+)')
		if id then huntId = tonumber(id) end
	elseif buffer:find("start_hunt") then
		action = "start_hunt"
		local id = buffer:match('"hunt_id"%s*:%s*(%d+)')
		if id then huntId = tonumber(id) end
	elseif buffer:find("stop_hunt") then
		action = "stop_hunt"
	end

	local playerId = player:getId()

	if action == "get_hunts" then
		local curStamina = getPlayerIdleStamina(player)
		local huntsJsonParts = {}
		for _, h in ipairs(IDLE_HUNTS) do
			table.insert(
				huntsJsonParts,
				string.format(
					'{"id":%d,"name":%q,"tier":%q,"level":%d,"focus":%q,"desc":%q,"cost":%d,"req_lvl":%d,"req_atk":%d,"req_def":%d,"req_bank":%d,"potions":%q}',
					h.id, h.name, h.tier, h.level, h.focus, h.desc, h.supplyCostPerTurn, h.reqLevel, h.reqAttack, h.reqDefense, h.reqBank, h.reqPotions
				)
			)
		end

		local response = string.format(
			'{"action":"hunts_list","stamina":%d,"max_stamina":%d,"in_hunt":%s,"hunts":[%s]}',
			curStamina,
			MAX_IDLE_STAMINA,
			_G.OnIdleHunt[playerId] and "true" or "false",
			table.concat(huntsJsonParts, ",")
		)
		player:sendExtendedOpcode(OPCODE_IDLE_HUNT, response)

	elseif action == "get_requirements" then
		local hunt = nil
		for _, h in ipairs(IDLE_HUNTS) do
			if h.id == huntId then
				hunt = h
				break
			end
		end

		if hunt then
			local meetsAll, details = evaluateHuntRequirements(player, hunt)
			local response = string.format(
				'{"action":"requirements","hunt_id":%d,"hunt_name":%q,"meets_all":%s,' ..
				'"p_lvl":%d,"r_lvl":%d,"ok_lvl":%s,' ..
				'"p_atk":%d,"r_atk":%d,"ok_atk":%s,' ..
				'"p_def":%d,"r_def":%d,"ok_def":%s,' ..
				'"p_bank":%d,"r_bank":%d,"ok_bank":%s,' ..
				'"potions":%q}',
				hunt.id, hunt.name, meetsAll and "true" or "false",
				details.level.player, details.level.required, details.level.ok and "true" or "false",
				details.attack.player, details.attack.required, details.attack.ok and "true" or "false",
				details.defense.player, details.defense.required, details.defense.ok and "true" or "false",
				details.bank.player, details.bank.required, details.bank.ok and "true" or "false",
				details.potions
			)
			player:sendExtendedOpcode(OPCODE_IDLE_HUNT, response)
		end

	elseif action == "start_hunt" then
		startIdleHunt(player, huntId)

	elseif action == "stop_hunt" then
		stopIdleHunt(playerId, "Caçada IDLE encerrada pelo jogador.", false)
	end
end

idleOpcodeEvent:register()

-- Limpeza ao deslogar
local idleLogoutEvent = CreatureEvent("IdleHuntLogout")
function idleLogoutEvent.onLogout(player)
	local playerId = player:getId()
	if _G.OnIdleHunt[playerId] then
		if _G.OnIdleHunt[playerId].event then
			stopEvent(_G.OnIdleHunt[playerId].event)
		end
		_G.OnIdleHunt[playerId] = nil
	end
	return true
end
idleLogoutEvent:register()
