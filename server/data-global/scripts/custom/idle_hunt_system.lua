--[[
    Exura OT - Sistema de Caçadas IDLE Instanciadas, Stamina IDLE & IDLE HUNT MENU
    - Hunts organizadas por faixas de nível (1-20 até 300+)
    - Foco em EXP ou Loot
    - Débito de suprimentos (poções/runas) direto do saldo bancário a preço de NPC
    - Taxas: -20% de EXP (0.8x) e 100% de Loot
    - Stamina IDLE: dreno 3x mais lento que a caçada normal
    - Comparador de Requisitos:
        * Cumpre 100% dos requisitos -> Ejeção de emergência (salvamento) com 10% de HP.
        * Abaixo dos requisitos -> Risco real de morte normal.
    - Combate Ativo no Mapa:
        * O jogador ataca ativamente com armas, magias e projéteis.
        * Monstros da hunt são gerados e engajados em combate real.
    - Sistema de Loot e Vendas:
        * Tabela de drops reais para cada uma das 14 hunts.
        * Configuração de Manter (backpack) vs Vender (auto-venda 10m ou Venda Rápida).
        * Auto-venda a cada 10 minutos com depósito direto no banco.
        * Botão Venda Rápida com cooldown de 2 minutos.
    - Teleportes Rápidos:
        * House (teleporta para a casa própria se tiver).
        * Temple (teleporta para o templo da cidade natal).
    - Opcode de Comunicação: 106 (OPCODE_IDLE_HUNT)
]]

_G.OnIdleHunt = _G.OnIdleHunt or {}
_G.IdleLootPreferences = _G.IdleLootPreferences or {}

local OPCODE_IDLE_HUNT = 106
local STORAGE_IDLE_STAMINA = 95000     -- Armazena minutos restantes de Stamina IDLE
local MAX_IDLE_STAMINA = 1440          -- 24 horas (em minutos)

-- Tabela oficial de Hunts por Faixas de Nível (Tiers 1 a 7) com Loot Tables Reais
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
		lookType = 26,
		pos = Position(32797, 31560, 7),
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
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 85, countMin = 10, countMax = 45 },
			{ id = 3492, name = "Worm", price = 1, chance = 45, countMin = 1, countMax = 5 },
			{ id = 3577, name = "Meat", price = 2, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3286, name = "Mace", price = 30, chance = 18, countMin = 1, countMax = 1 },
			{ id = 3264, name = "Sword", price = 25, chance = 14, countMin = 1, countMax = 1 },
			{ id = 3374, name = "Legion Helmet", price = 22, chance = 8, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 2,
		name = "Amazon Camp (Venore)",
		tier = "1 - 20",
		level = 15,
		focus = "Mais Loot",
		desc = "Amazons e Valkyries com drop frequente de Protective Charms.",
		monster = "Valkyrie",
		lookType = 137,
		pos = Position(32355, 31645, 1),
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
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 85, countMin = 15, countMax = 60 },
			{ id = 11444, name = "Protective Charm", price = 200, chance = 25, countMin = 1, countMax = 2 },
			{ id = 3273, name = "Sabre", price = 12, chance = 30, countMin = 1, countMax = 1 },
			{ id = 3267, name = "Dagger", price = 2, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3377, name = "Scale Armor", price = 75, chance = 10, countMin = 1, countMax = 1 },
		},
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
		lookType = 22,
		pos = Position(32616, 31414, 2),
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
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 25, countMax = 90 },
			{ id = 9657, name = "Cyclops Toe", price = 55, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3413, name = "Battle Shield", price = 95, chance = 18, countMin = 1, countMax = 1 },
			{ id = 3269, name = "Halberd", price = 400, chance = 12, countMin = 1, countMax = 1 },
			{ id = 3384, name = "Dark Helmet", price = 250, chance = 8, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 4,
		name = "Minotaur Pyramid (Darashia)",
		tier = "20 - 40",
		level = 30,
		focus = "Mais Loot",
		desc = "Minotaur Guards e Archers. Alto retorno em Minotaur Leather.",
		monster = "Minotaur Guard",
		lookType = 29,
		pos = Position(32465, 31952, 4),
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
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 30, countMax = 110 },
			{ id = 5878, name = "Minotaur Leather", price = 80, chance = 35, countMin = 1, countMax = 2 },
			{ id = 11472, name = "Minotaur Horn", price = 75, chance = 30, countMin = 1, countMax = 2 },
			{ id = 3266, name = "Battle Axe", price = 80, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3275, name = "Double Axe", price = 260, chance = 10, countMin = 1, countMax = 1 },
		},
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
		lookType = 34,
		pos = Position(33078, 32168, 4),
		baseExp = 700,
		supplyCostPerTurn = 90,
		reqLevel = 50,
		reqAttack = 42,
		reqDefense = 35,
		reqBank = 15000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 60,
		damageMax = 160,
		healAmount = 170,
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 50, countMax = 180 },
			{ id = 3583, name = "Dragon Ham", price = 25, chance = 60, countMin = 1, countMax = 3 },
			{ id = 11457, name = "Dragon's Tail", price = 100, chance = 30, countMin = 1, countMax = 2 },
			{ id = 5877, name = "Green Dragon Leather", price = 100, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3297, name = "Serpent Sword", price = 900, chance = 12, countMin = 1, countMax = 1 },
			{ id = 3416, name = "Dragon Shield", price = 4000, chance = 6, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 6,
		name = "Giant Spider Caves",
		tier = "40 - 80",
		level = 65,
		focus = "Mais Loot",
		desc = "Giant Spiders e Tarantulas. Alta taxa de drop de Spider Silk.",
		monster = "Giant Spider",
		lookType = 38,
		pos = Position(32784, 31097, 1),
		baseExp = 900,
		supplyCostPerTurn = 110,
		reqLevel = 65,
		reqAttack = 46,
		reqDefense = 38,
		reqBank = 20000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 80,
		damageMax = 210,
		healAmount = 220,
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 60, countMax = 220 },
			{ id = 5879, name = "Spider Silk", price = 1500, chance = 25, countMin = 1, countMax = 2 },
			{ id = 3370, name = "Knight Armor", price = 5000, chance = 8, countMin = 1, countMax = 1 },
			{ id = 3371, name = "Knight Legs", price = 5000, chance = 6, countMin = 1, countMax = 1 },
			{ id = 3051, name = "Energy Ring", price = 500, chance = 15, countMin = 1, countMax = 1 },
		},
	},

	-- Tier 4: Level 80 a 130 (Avançado)
	{
		id = 7,
		name = "Fenrock Dragon Lords",
		tier = "80 - 130",
		level = 90,
		focus = "Mais XP",
		desc = "Dragon Lords ferozes. Excelente EXP por hora e drops de fogo.",
		monster = "Dragon Lord",
		lookType = 39,
		pos = Position(32797, 31558, 3),
		baseExp = 2100,
		supplyCostPerTurn = 220,
		reqLevel = 90,
		reqAttack = 54,
		reqDefense = 45,
		reqBank = 40000,
		reqPotions = "Ultimate Health / Great Mana Potion",
		damageMin = 150,
		damageMax = 380,
		healAmount = 400,
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 100, countMax = 300 },
			{ id = 5882, name = "Red Dragon Scale", price = 200, chance = 30, countMin = 1, countMax = 2 },
			{ id = 3280, name = "Fire Sword", price = 4000, chance = 10, countMin = 1, countMax = 1 },
			{ id = 3428, name = "Tower Shield", price = 8000, chance = 7, countMin = 1, countMax = 1 },
			{ id = 3392, name = "Royal Helmet", price = 30000, chance = 4, countMin = 1, countMax = 1 },
			{ id = 7402, name = "Dragon Slayer", price = 15000, chance = 5, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 8,
		name = "Seacrest Grounds",
		tier = "80 - 130",
		level = 110,
		focus = "Mais Loot",
		desc = "Criaturas aquáticas e Seacrests com pérolas e gemas preciosas.",
		monster = "Water Elemental",
		lookType = 275,
		pos = Position(31901, 30999, 9),
		baseExp = 2400,
		supplyCostPerTurn = 260,
		reqLevel = 110,
		reqAttack = 58,
		reqDefense = 48,
		reqBank = 50000,
		reqPotions = "Ultimate Health / Great Mana Potion",
		damageMin = 180,
		damageMax = 420,
		healAmount = 450,
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 85, countMin = 1, countMax = 5 },
			{ id = 3029, name = "Small Sapphire", price = 250, chance = 35, countMin = 1, countMax = 3 },
			{ id = 5895, name = "Fish Fin", price = 2000, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3051, name = "Energy Ring", price = 500, chance = 20, countMin = 1, countMax = 1 },
		},
	},

	-- Tier 5: Level 130 a 200 (Expert)
	{
		id = 9,
		name = "Banuta Deeper (Medusa)",
		tier = "130 - 200",
		level = 140,
		focus = "Mais XP",
		desc = "Medusas, Serpent Spawns e Hydras nas profundezas de Banuta.",
		monster = "Medusa",
		lookType = 330,
		pos = Position(32868, 32826, 2),
		baseExp = 4050,
		supplyCostPerTurn = 380,
		reqLevel = 140,
		reqAttack = 66,
		reqDefense = 55,
		reqBank = 80000,
		reqPotions = "Supreme Health / Ultimate Mana Potion",
		damageMin = 280,
		damageMax = 620,
		healAmount = 650,
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 90, countMin = 2, countMax = 8 },
			{ id = 9694, name = "Snake Skin", price = 400, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3436, name = "Medusa Shield", price = 9000, chance = 8, countMin = 1, countMax = 1 },
			{ id = 813, name = "Terra Boots", price = 2500, chance = 12, countMin = 1, countMax = 1 },
			{ id = 9302, name = "Sacred Tree Amulet", price = 3000, chance = 10, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 10,
		name = "Grim Reapers (Drefia)",
		tier = "130 - 200",
		level = 170,
		focus = "Mais Loot",
		desc = "Grim Reapers nas catacumbas de Drefia. Risco alto e loot raro.",
		monster = "Grim Reaper",
		lookType = 300,
		pos = Position(32784, 31025, 8),
		baseExp = 5500,
		supplyCostPerTurn = 450,
		reqLevel = 170,
		reqAttack = 72,
		reqDefense = 60,
		reqBank = 120000,
		reqPotions = "Supreme Health / Ultimate Mana Potion",
		damageMin = 350,
		damageMax = 750,
		healAmount = 780,
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 90, countMin = 3, countMax = 10 },
			{ id = 9647, name = "Demonic Skeletal Hand", price = 800, chance = 35, countMin = 1, countMax = 2 },
			{ id = 8082, name = "Underworld Rod", price = 22000, chance = 7, countMin = 1, countMax = 1 },
			{ id = 7418, name = "Nightmare Blade", price = 35000, chance = 4, countMin = 1, countMax = 1 },
		},
	},

	-- Tier 6: Level 200 a 250 (Master)
	{
		id = 11,
		name = "Roshamuul Valley",
		tier = "200 - 250",
		level = 210,
		focus = "Mais XP",
		desc = "Frazzlemaws e Guzzlemaw. Rush insano com dreno alto de potions.",
		monster = "Frazzlemaw",
		lookType = 594,
		pos = Position(33533, 32490, 5),
		baseExp = 7800,
		supplyCostPerTurn = 650,
		reqLevel = 210,
		reqAttack = 80,
		reqDefense = 68,
		reqBank = 200000,
		reqPotions = "Supreme Health / Ultimate Mana / SD Runes",
		damageMin = 480,
		damageMax = 980,
		healAmount = 1020,
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 95, countMin = 5, countMax = 15 },
			{ id = 20199, name = "Frazzle Skin", price = 800, chance = 40, countMin = 1, countMax = 2 },
			{ id = 20198, name = "Frazzle Tongue", price = 1000, chance = 35, countMin = 1, countMax = 2 },
			{ id = 238, name = "Great Mana Potion", price = 120, chance = 50, countMin = 1, countMax = 4 },
			{ id = 5895, name = "Fish Fin", price = 2000, chance = 15, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 12,
		name = "Oramond West (Glooth)",
		tier = "200 - 250",
		level = 230,
		focus = "Mais Loot",
		desc = "Glooth Bandits e Glooth Brigands. Máquina de fazer dinheiro.",
		monster = "Glooth Bandit",
		lookType = 600,
		pos = Position(33554, 31923, 3),
		baseExp = 8600,
		supplyCostPerTurn = 720,
		reqLevel = 230,
		reqAttack = 84,
		reqDefense = 72,
		reqBank = 250000,
		reqPotions = "Supreme Health / Ultimate Mana / SD Runes",
		damageMin = 520,
		damageMax = 1050,
		healAmount = 1100,
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 95, countMin = 5, countMax = 16 },
			{ id = 21179, name = "Glooth Blade", price = 15000, chance = 8, countMin = 1, countMax = 1 },
			{ id = 21180, name = "Glooth Axe", price = 18000, chance = 7, countMin = 1, countMax = 1 },
			{ id = 238, name = "Great Mana Potion", price = 120, chance = 45, countMin = 2, countMax = 5 },
		},
	},

	-- Tier 7: Level 250 a 300+ (Endgame)
	{
		id = 13,
		name = "Cobra Bastion",
		tier = "250 - 300+",
		level = 260,
		focus = "Mais XP",
		desc = "Cobra Scouts e Assassins. Dano massivo com itens lendários.",
		monster = "Cobra Assassin",
		lookType = 1217,
		pos = Position(33402, 32663, 0),
		baseExp = 12000,
		supplyCostPerTurn = 950,
		reqLevel = 260,
		reqAttack = 92,
		reqDefense = 78,
		reqBank = 400000,
		reqPotions = "Supreme Health / Ultimate Mana / Imbuements",
		damageMin = 650,
		damageMax = 1350,
		healAmount = 1400,
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 98, countMin = 8, countMax = 25 },
			{ id = 30398, name = "Cobra Sword", price = 50000, chance = 3, countMin = 1, countMax = 1 },
			{ id = 3038, name = "Green Gem", price = 5000, chance = 15, countMin = 1, countMax = 1 },
			{ id = 3041, name = "Blue Gem", price = 5000, chance = 12, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 14,
		name = "Issavi Sphinxes",
		tier = "250 - 300+",
		level = 290,
		focus = "Mais Loot",
		desc = "Sphinx e Crypt Warden. O ápice de XP e itens valiosos do servidor.",
		monster = "Sphinx",
		lookType = 1188,
		pos = Position(33883, 31437, 7),
		baseExp = 15000,
		supplyCostPerTurn = 1200,
		reqLevel = 290,
		reqAttack = 98,
		reqDefense = 85,
		reqBank = 600000,
		reqPotions = "Supreme Health / Ultimate Mana / Imbuements",
		damageMin = 750,
		damageMax = 1600,
		healAmount = 1650,
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 98, countMin = 10, countMax = 30 },
			{ id = 31437, name = "Sphinx Feather", price = 1200, chance = 40, countMin = 1, countMax = 3 },
			{ id = 3364, name = "Golden Legs", price = 30000, chance = 5, countMin = 1, countMax = 1 },
			{ id = 3038, name = "Green Gem", price = 5000, chance = 18, countMin = 1, countMax = 1 },
			{ id = 3041, name = "Blue Gem", price = 5000, chance = 15, countMin = 1, countMax = 1 },
		},
	},
}

-- Funções Auxiliares de Stamina IDLE
local function getPlayerIdleStamina(player)
	local stamina = player:getStorageValue(STORAGE_IDLE_STAMINA)
	if stamina < 0 then
		stamina = MAX_IDLE_STAMINA
		player:setStorageValue(STORAGE_IDLE_STAMINA, stamina)
	end
	return stamina
end

local function setPlayerIdleStamina(player, val)
	val = math.max(0, math.min(MAX_IDLE_STAMINA, val))
	player:setStorageValue(STORAGE_IDLE_STAMINA, val)
	return val
end

local function getHuntById(id)
	for _, h in ipairs(IDLE_HUNTS) do
		if h.id == id then
			return h
		end
	end
	return nil
end

local function formatNumber(n)
	local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
	if not left then return tostring(n) end
	return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

-- Cálculo de Requisitos do Jogador
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

-- Avaliação de Requisitos
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

-- Venda de Itens Pendentes (Auto 10m ou Venda Rápida)
local function sellPendingLoot(player, session, reason)
	local totalGold = 0
	local totalCount = 0
	local hunt = getHuntById(session.huntId)
	if not hunt or not hunt.lootTable then
		return 0, 0
	end

	local priceMap = {}
	for _, l in ipairs(hunt.lootTable) do
		priceMap[l.id] = l.price
	end

	for itemId, count in pairs(session.pendingSale or {}) do
		if count > 0 then
			local price = priceMap[itemId] or 1
			totalGold = totalGold + (count * price)
			totalCount = totalCount + count
		end
	end

	if totalGold > 0 then
		player:addMoneyBank(totalGold)
		session.pendingSale = {}
		session.totalLootGold = 0

		local prefix = (reason == "quick") and "💰 [VENDA RÁPIDA]" or "💰 [AUTO-VENDA 10M]"
		player:sendTextMessage(
			MESSAGE_EVENT_ADVANCE,
			string.format(
				"%s: %d itens foram vendidos por %s gold coins depositados diretamente no seu banco!",
				prefix,
				totalCount,
				formatNumber(totalGold)
			)
		)
		return totalGold, totalCount
	end
	return 0, 0
end

-- Finalizar Caçada IDLE
local function stopIdleHunt(playerId, reason, isEmergency, skipTeleport)
	local session = _G.OnIdleHunt[playerId]
	if session then
		if session.event then
			stopEvent(session.event)
		end
		-- Se tiver itens pendentes ao encerrar, realizar venda automática para não perder loot
		local player = Player(playerId)
		if player and session.pendingSale then
			sellPendingLoot(player, session, "auto")
		end
		_G.OnIdleHunt[playerId] = nil
	end

	local player = Player(playerId)
	if player then
		if not skipTeleport then
			local templePos = player:getTown():getTemplePosition()
			if templePos then
				player:teleportTo(templePos)
				templePos:sendMagicEffect(CONST_ME_TELEPORT)
			end
		end

		local msg = reason or "Caçada IDLE finalizada."
		if isEmergency then
			player:sendTextMessage(
				MESSAGE_EVENT_ADVANCE,
				"🛡️ [RESGATE IDLE]: Sua vida caiu para 10%! Como cumpriu todos os requisitos, o sistema de emergência te resgatou com segurança para o Templo!"
			)
		else
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		end

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

-- Telemetria de Status da Caçada Ativa
local function sendHuntStatusOpcode(player, huntId, session, curStamina, maxHp)
	local now = os.time()
	local nextAutosell = math.max(0, 600 - (now - (session.lastAutoSell or now)))
	local quickCooldown = math.max(0, 120 - (now - (session.lastQuickSell or 0)))

	local statusJson = string.format(
		'{"action":"hunt_status","hunt_id":%d,"hp_percent":%d,"xp_session":%d,"supplies_spent":%d,"idle_stamina":%d,"pending_gold":%d,"next_autosell":%d,"quick_cooldown":%d}',
		huntId,
		math.floor((player:getHealth() / maxHp) * 100),
		session.xpGained or 0,
		session.suppliesSpent or 0,
		curStamina,
		session.totalLootGold or 0,
		nextAutosell,
		quickCooldown
	)
	player:sendExtendedOpcode(OPCODE_IDLE_HUNT, statusJson)
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

	local hunt = getHuntById(huntId)
	if not hunt then
		stopIdleHunt(playerId, "Hunt inválida.", false)
		return
	end

	-- 1. Stamina IDLE
	local curStamina = getPlayerIdleStamina(player)
	if curStamina <= 0 then
		stopIdleHunt(playerId, "Sua Stamina IDLE acabou! Caçada encerrada.", false)
		return
	end

	-- 2. Dedução de Suprimentos diretamente do Banco
	local bankBalance = player:getBankBalance()
	if bankBalance < hunt.supplyCostPerTurn then
		player:sendTextMessage(
			MESSAGE_FAILURE,
			"Seu saldo bancário esgotou! Sem suprimentos para curar na caçada."
		)
	else
		player:removeMoneyBank(hunt.supplyCostPerTurn)
		session.suppliesSpent = session.suppliesSpent + hunt.supplyCostPerTurn
	end

	-- 3. Dano Recebido e Cura Automática
	local damage = math.random(hunt.damageMin, hunt.damageMax)
	local curHealth = player:getHealth()
	local maxHealth = player:getMaxHealth()

	if bankBalance >= hunt.supplyCostPerTurn then
		local heal = math.min(hunt.healAmount, maxHealth - curHealth)
		if heal > 0 then
			player:addHealth(heal)
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		end
	end

	player:addHealth(-damage)
	player:getPosition():sendMagicEffect(CONST_ME_HITAREA)

	-- 4. Verificação de Saúde Crítica (10% HP)
	local healthPercent = (player:getHealth() / maxHealth) * 100
	if healthPercent <= 10 then
		if session.meetsRequirements then
			stopIdleHunt(playerId, "Ejeção de emergência aos 10% de HP.", true)
			return
		else
			if player:getHealth() <= 0 then
				_G.OnIdleHunt[playerId] = nil
				return
			end
		end
	end

	-- 5. COMBATE ATIVO NO MAPA (O personagem caça normalmente no mundo!)
	local pPos = player:getPosition()
	local spectators = Game.getSpectators(pPos, false, false, 7, 7, 5, 5)
	local targetMonster = nil
	local nearbyCount = 0

	for _, spec in ipairs(spectators) do
		if spec:isMonster() and not spec:isDead() then
			nearbyCount = nearbyCount + 1
			if not targetMonster then
				targetMonster = spec
			end
		end
	end

	-- Se houver menos de 2 monstros por perto, invocar monstro da hunt em tile livre
	if nearbyCount < 2 and hunt.monster then
		local spawnOffsets = {
			{x = 2, y = 1}, {x = -2, y = -1}, {x = 1, y = -2}, {x = -1, y = 2},
			{x = 2, y = -2}, {x = -2, y = 2}
		}
		for _, off in ipairs(spawnOffsets) do
			local sPos = Position(pPos.x + off.x, pPos.y + off.y, pPos.z)
			local tile = Tile(sPos)
			if tile and tile:isWalkable() and not tile:hasProperty(CONST_PROP_BLOCKSOLID) then
				local spawned = Game.createMonster(hunt.monster, sPos, true, false)
				if spawned then
					sPos:sendMagicEffect(CONST_ME_TELEPORT)
					if not targetMonster then
						targetMonster = spawned
					end
					break
				end
			end
		end
	end

	-- Ação Ativa de Ataque do Jogador contra o Monstro Alvo
	if targetMonster and not targetMonster:isDead() then
		local mPos = targetMonster:getPosition()
		player:setDirection(pPos:getDirectionTo(mPos))

		local voc = player:getVocation():getBaseId()
		local atkDmg = math.random(hunt.damageMin * 2, hunt.damageMax * 3)

		if voc == VOCATION_KNIGHT or voc == VOCATION_ELITE_KNIGHT then
			mPos:sendMagicEffect(CONST_ME_HITAREA)
			if math.random(1, 3) == 1 then
				player:say("Exori!", TALKTYPE_MONSTER_SAY)
				pPos:sendMagicEffect(CONST_ME_HITAREA)
			end
		elseif voc == VOCATION_PALADIN or voc == VOCATION_ROYAL_PALADIN then
			pPos:sendDistanceEffect(mPos, CONST_ANI_ARROW)
			mPos:sendMagicEffect(CONST_ME_HOLYDAMAGE)
			if math.random(1, 3) == 1 then
				player:say("Exori San!", TALKTYPE_MONSTER_SAY)
			end
		elseif voc == VOCATION_SORCERER or voc == VOCATION_MASTER_SORCERER then
			pPos:sendDistanceEffect(mPos, CONST_ANI_FIRE)
			mPos:sendMagicEffect(CONST_ME_FIREAREA)
			if math.random(1, 3) == 1 then
				player:say("Exori Flam!", TALKTYPE_MONSTER_SAY)
			end
		elseif voc == VOCATION_DRUID or voc == VOCATION_ELDER_DRUID then
			pPos:sendDistanceEffect(mPos, CONST_ANI_ICE)
			mPos:sendMagicEffect(CONST_ME_ICEAREA)
			if math.random(1, 3) == 1 then
				player:say("Exori Frigo!", TALKTYPE_MONSTER_SAY)
			end
		else
			mPos:sendMagicEffect(CONST_ME_HITAREA)
		end

		doTargetCombatHealth(player, targetMonster, COMBAT_PHYSICALDAMAGE, -atkDmg, -atkDmg, CONST_ME_NONE)
	end

	-- 6. Ganho de Experiência (-20% XP)
	local expGained = math.floor(hunt.baseExp * 0.8)
	player:addExperience(expGained, true)
	session.xpGained = session.xpGained + expGained

	-- 7. ROLAGEM DE LOOT REAL & PREFERÊNCIAS DO JOGADOR
	if hunt.lootTable and #hunt.lootTable > 0 then
		for _, lootItem in ipairs(hunt.lootTable) do
			local roll = math.random(1, 100)
			if roll <= lootItem.chance then
				local count = math.random(lootItem.countMin or 1, lootItem.countMax or 1)
				local rule = session.lootRules[lootItem.id] or "sell"

				if rule == "keep" then
					-- Guardado diretamente na backpack
					player:addItem(lootItem.id, count)
					session.keptDrops[lootItem.id] = (session.keptDrops[lootItem.id] or 0) + count
					player:sendTextMessage(
						MESSAGE_LOOT,
						string.format("🎒 [Loot]: %dx %s guardado na backpack.", count, lootItem.name)
					)
				else
					-- Acumulado para venda (auto 10m ou venda rápida)
					session.pendingSale[lootItem.id] = (session.pendingSale[lootItem.id] or 0) + count
					local itemTotalGold = count * lootItem.price
					session.totalLootGold = session.totalLootGold + itemTotalGold
					player:sendTextMessage(
						MESSAGE_LOOT,
						string.format("💰 [Loot]: %dx %s acumulado para venda (+%d gp).", count, lootItem.name, itemTotalGold)
					)
				end
			end
		end
	end

	-- 8. AUTO-VENDA RECORRENTE A CADA 10 MINUTOS (600 segundos)
	local now = os.time()
	if (now - session.lastAutoSell) >= 600 then
		session.lastAutoSell = now
		sellPendingLoot(player, session, "auto")
	end

	-- 9. Consumo de Stamina IDLE (1 minuto a cada 3 minutos reais)
	session.turnCount = (session.turnCount or 0) + 1
	if session.turnCount >= 90 then
		session.turnCount = 0
		curStamina = setPlayerIdleStamina(player, curStamina - 1)
	end

	-- 10. Telemetria via Opcode 106
	if player:isUsingOtClient() and (session.turnCount % 2 == 0) then
		sendHuntStatusOpcode(player, huntId, session, curStamina, maxHealth)
	end

	session.event = addEvent(idleCombatLoop, 2000, playerId, huntId)
end

-- Iniciar Caçada IDLE
local function startIdleHunt(player, huntId)
	local playerId = player:getId()

	if _G.OnIdleHunt[playerId] then
		player:sendTextMessage(MESSAGE_FAILURE, "Você já está em uma caçada IDLE.")
		return false
	end

	local hunt = getHuntById(huntId)
	if not hunt then
		player:sendTextMessage(MESSAGE_FAILURE, "Hunt não encontrada.")
		return false
	end

	local curStamina = getPlayerIdleStamina(player)
	if curStamina <= 0 then
		player:sendTextMessage(MESSAGE_FAILURE, "Você não tem Stamina IDLE disponível.")
		return false
	end

	local meetsAll = evaluateHuntRequirements(player, hunt)

	-- Carregar preferências persistidas de loot do jogador
	local savedPrefs = _G.IdleLootPreferences[playerId] or {}

	_G.OnIdleHunt[playerId] = {
		huntId = huntId,
		meetsRequirements = meetsAll,
		xpGained = 0,
		suppliesSpent = 0,
		totalLootGold = 0,
		turnCount = 0,
		lastAutoSell = os.time(),
		lastQuickSell = 0,
		pendingSale = {},
		keptDrops = {},
		lootRules = savedPrefs,
		event = nil,
	}

	-- Teleportar jogador para o spawn real da caçada
	if hunt.pos then
		local curPos = player:getPosition()
		curPos:sendMagicEffect(CONST_ME_TELEPORT)
		player:teleportTo(hunt.pos)
		hunt.pos:sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(
			MESSAGE_EVENT_ADVANCE,
			string.format("🌀 [IDLE HUNT]: Você foi transportado para a área de caçada: %s!", hunt.name)
		)
	end

	player:sendTextMessage(
		MESSAGE_STATUS_CONSOLE_BLUE,
		string.format(
			"Caçada IDLE iniciada: %s. Proteção de Emergência 10%% HP: %s.",
			hunt.name,
			meetsAll and "ATIVA" or "DESATIVADA (Abaixo dos Requisitos)"
		)
	)

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

	_G.OnIdleHunt[playerId].event = addEvent(idleCombatLoop, 2000, playerId, huntId)
	return true
end

-- Manipulador de Opcode Estendido 106 para o IDLE HUNT MENU
local idleOpcodeEvent = CreatureEvent("IdleHuntExtendedOpcode")

function idleOpcodeEvent.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= OPCODE_IDLE_HUNT then
		return
	end

	local playerId = player:getId()

	-- 1. CATÁLOGO GERAL DE HUNTS
	if buffer:find("get_hunts") then
		local curStamina = getPlayerIdleStamina(player)
		local huntsJsonParts = {}
		for _, h in ipairs(IDLE_HUNTS) do
			table.insert(
				huntsJsonParts,
				string.format(
					'{"id":%d,"name":%q,"tier":%q,"level":%d,"focus":%q,"desc":%q,"cost":%d,"req_lvl":%d,"req_atk":%d,"req_def":%d,"req_bank":%d,"potions":%q,"looktype":%d}',
					h.id, h.name, h.tier, h.level, h.focus, h.desc, h.supplyCostPerTurn, h.reqLevel, h.reqAttack, h.reqDefense, h.reqBank, h.reqPotions, h.lookType or 0
				)
			)
		end

		local session = _G.OnIdleHunt[playerId]
		local activeHuntId = session and session.huntId or 0

		local response = string.format(
			'{"action":"hunts_list","stamina":%d,"max_stamina":%d,"in_hunt":%s,"active_hunt_id":%d,"hunts":[%s]}',
			curStamina,
			MAX_IDLE_STAMINA,
			session and "true" or "false",
			activeHuntId,
			table.concat(huntsJsonParts, ",")
		)
		player:sendExtendedOpcode(OPCODE_IDLE_HUNT, response)

	-- 2. REQUISITOS DA HUNT
	elseif buffer:find("get_requirements") then
		local huntId = tonumber(buffer:match('"hunt_id"%s*:%s*(%d+)')) or 1
		local hunt = getHuntById(huntId)
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

	-- 3. INICIAR / ENCERRAR CAÇADA
	elseif buffer:find("start_hunt") then
		local huntId = tonumber(buffer:match('"hunt_id"%s*:%s*(%d+)')) or 1
		startIdleHunt(player, huntId)

	elseif buffer:find("stop_hunt") then
		stopIdleHunt(playerId, "Caçada IDLE encerrada pelo jogador.", false, false)

	-- 4. CONSULTAR DROPS E CONFIGURAÇÕES DE LOOT
	elseif buffer:find("get_hunt_loot") then
		local huntId = tonumber(buffer:match('"hunt_id"%s*:%s*(%d+)'))
		local session = _G.OnIdleHunt[playerId]
		if not huntId and session then
			huntId = session.huntId
		end
		huntId = huntId or 1

		local hunt = getHuntById(huntId)
		if hunt and hunt.lootTable then
			local lootParts = {}
			local userPrefs = session and session.lootRules or (_G.IdleLootPreferences[playerId] or {})

			for _, l in ipairs(hunt.lootTable) do
				local rule = userPrefs[l.id] or "sell"
				local droppedCount = (session and session.pendingSale and session.pendingSale[l.id]) or 0
				local keptCount = (session and session.keptDrops and session.keptDrops[l.id]) or 0

				table.insert(
					lootParts,
					string.format(
						'{"id":%d,"name":%q,"price":%d,"chance":%d,"rule":%q,"dropped":%d}',
						l.id, l.name, l.price, l.chance, rule, (droppedCount + keptCount)
					)
				)
			end

			local now = os.time()
			local nextAutosell = session and math.max(0, 600 - (now - (session.lastAutoSell or now))) or 600
			local quickCooldown = session and math.max(0, 120 - (now - (session.lastQuickSell or 0))) or 0
			local pendingGold = session and session.totalLootGold or 0

			local response = string.format(
				'{"action":"hunt_loot","hunt_id":%d,"hunt_name":%q,"pending_gold":%d,"next_autosell":%d,"quick_cooldown":%d,"loot":[%s]}',
				hunt.id, hunt.name, pendingGold, nextAutosell, quickCooldown, table.concat(lootParts, ",")
			)
			player:sendExtendedOpcode(OPCODE_IDLE_HUNT, response)
		end

	-- 5. DEFINIR REGRA DE LOOT (MANTER vs VENDER)
	elseif buffer:find("set_loot_rule") then
		local itemId = tonumber(buffer:match('"item_id"%s*:%s*(%d+)'))
		local rule = buffer:match('"rule"%s*:%s*"(%a+)"') or "sell"

		if itemId then
			_G.IdleLootPreferences[playerId] = _G.IdleLootPreferences[playerId] or {}
			_G.IdleLootPreferences[playerId][itemId] = rule

			local session = _G.OnIdleHunt[playerId]
			if session and session.lootRules then
				session.lootRules[itemId] = rule
			end
		end

	-- 6. BOTÃO DE VENDA RÁPIDA (COOLDOWN 2 MINUTOS)
	elseif buffer:find("quick_sell") then
		local session = _G.OnIdleHunt[playerId]
		if not session then
			player:sendTextMessage(MESSAGE_FAILURE, "Você não está em uma caçada IDLE com itens para vender.")
			return
		end

		local now = os.time()
		local elapsed = now - (session.lastQuickSell or 0)
		if elapsed < 120 then
			local remaining = 120 - elapsed
			player:sendTextMessage(
				MESSAGE_FAILURE,
				string.format("A Venda Rápida está em recarga. Aguarde mais %d segundos.", remaining)
			)
			player:sendExtendedOpcode(
				OPCODE_IDLE_HUNT,
				string.format('{"action":"quick_sell_cooldown","remaining":%d}', remaining)
			)
			return
		end

		local gold, count = sellPendingLoot(player, session, "quick")
		session.lastQuickSell = now

		player:sendExtendedOpcode(
			OPCODE_IDLE_HUNT,
			string.format(
				'{"action":"quick_sell_result","gold":%d,"count":%d,"cooldown":120}',
				gold, count
			)
		)

	-- 7. TELEPORTE RÁPIDO PARA A CASA (HOUSE)
	elseif buffer:find("teleport_house") then
		local house = player:getHouse()
		if not house then
			player:sendTextMessage(MESSAGE_FAILURE, "❌ [HOUSE]: Você não possui uma casa própria.")
			return
		end

		if _G.OnIdleHunt[playerId] then
			stopIdleHunt(playerId, "Teleportado para a casa pelo IDLE Hunt Menu.", false, true)
		end

		local exitPos = house:getExitPosition()
		if exitPos then
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:teleportTo(exitPos)
			exitPos:sendMagicEffect(CONST_ME_TELEPORT)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "🏠 [HOUSE]: Você foi teleportado para a sua casa com sucesso!")
		end

	-- 8. TELEPORTE RÁPIDO PARA O TEMPLO (TEMPLE)
	elseif buffer:find("teleport_temple") then
		local templePos = player:getTown():getTemplePosition()
		if not templePos then
			player:sendTextMessage(MESSAGE_FAILURE, "❌ [TEMPLE]: Templo da sua cidade não encontrado.")
			return
		end

		if _G.OnIdleHunt[playerId] then
			stopIdleHunt(playerId, "Teleportado para o templo pelo IDLE Hunt Menu.", false, true)
		end

		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		player:teleportTo(templePos)
		templePos:sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "🏛️ [TEMPLE]: Você foi teleportado para o templo de sua cidade com sucesso!")
	end
end

idleOpcodeEvent:register()

-- Limpeza ao Deslogar
local idleLogoutEvent = CreatureEvent("IdleHuntLogout")
function idleLogoutEvent.onLogout(player)
	local playerId = player:getId()
	if _G.OnIdleHunt[playerId] then
		if _G.OnIdleHunt[playerId].event then
			stopEvent(_G.OnIdleHunt[playerId].event)
		end
		-- Auto-venda do loot pendente para não perder
		sellPendingLoot(player, _G.OnIdleHunt[playerId], "auto")
		_G.OnIdleHunt[playerId] = nil
	end
	return true
end
idleLogoutEvent:register()
