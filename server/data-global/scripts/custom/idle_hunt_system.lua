-- IDLE HUNT SYSTEM - EXURA OT SERVER (RevScript)
-- Sistema de Caçadas IDLE Instanciadas (Fácil, Médio, Difícil) com Respawn Contínuo por Ondas
-- Correção Definitiva de Venda: Tabela Mestre Global, Persistência em Storage, Cooldown 0 em Venda Vazia

local OPCODE_IDLE_HUNT = 106
local OPCODE_BANK_BALANCE = 105
local STORAGE_IDLE_STAMINA = 95000
local MAX_IDLE_STAMINA = 1440

-- Base storage para persistência de regras de loot no banco de dados (player_storage)
-- STORAGE_IDLE_LOOT_BASE + itemId: 1 = sell, 0 / <= 0 = keep
local STORAGE_IDLE_AUTOLOOT_BASE = 870000 -- 1 = coletar (default), 0 = ignorar
local STORAGE_IDLE_LOOT_BASE = 880000
local STORAGE_LAST_QUICK_SELL = 889999
local STORAGE_RECORD_EXP_BASE = 890000
local STORAGE_RECORD_GP_BASE = 895000

-- Coordenadas das Áreas IDLE Oficiais em world.otbm
local ROOM_POS_EASY = Position(385, 754, 8)
local ROOM_POS_MEDIUM = Position(421, 301, 11)
local ROOM_POS_HARD = Position(440, 785, 11)

-- Helper de Formatação
local function formatNumber(n)
	local left, num, right = string.match(tostring(n), "^([^%d]*%d)(%d*)(.-)$")
	if not left then return tostring(n) end
	return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

local function escapeJsonString(str)
	if not str then return '""' end
	str = tostring(str)
	str = str:gsub('\\', '\\\\')
	str = str:gsub('"', '\\"')
	str = str:gsub('\r', '')
	str = str:gsub('\n', '\\n')
	str = str:gsub('\t', '\\t')
	return '"' .. str .. '"'
end

-- Tabela Oficial de Hunts: 3 Dificuldades (Fácil: 3 monstros, Médio: 4-5 monstros, Difícil: 6-7 monstros)
local IDLE_HUNTS = {
	-- =========================================================================
	-- 🟢 FÁCIL (EASY) - Sala: Position(385, 754, 8) - 3 Monstros por Onda
	-- =========================================================================
	{
		id = 1,
		name = "Rotworms (Fácil)",
		tier = "easy",
		level = 8,
		focus = "Balanced",
		desc = "Sala de treino inicial com 3 Rotworms. Ideal para iniciantes.",
		monster = "Rotworm",
		lookType = 26,
		elements = { physical = 0, fire = 0, earth = 0, energy = 0, ice = 0, holy = 0, death = 0 },
		pos = ROOM_POS_EASY,
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
		waves = {
			{ name = "Rotworm", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 85, countMin = 10, countMax = 45, isMoney = true },
			{ id = 3492, name = "Worm", price = 1, chance = 45, countMin = 1, countMax = 5 },
			{ id = 3577, name = "Meat", price = 2, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3286, name = "Mace", price = 30, chance = 18, countMin = 1, countMax = 1 },
			{ id = 3264, name = "Sword", price = 25, chance = 14, countMin = 1, countMax = 1 },
			{ id = 3374, name = "Legion Helmet", price = 22, chance = 8, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 2,
		name = "Amazons (Fácil)",
		tier = "easy",
		level = 15,
		focus = "More Loot",
		desc = "3 Amazons ágeis com drops frequentes de Protective Charm.",
		monster = "Amazon",
		lookType = 137,
		elements = { physical = 0, fire = 10, earth = -10, energy = 0, ice = 10, holy = 0, death = 10 },
		pos = ROOM_POS_EASY,
		baseExp = 80,
		supplyCostPerTurn = 15,
		reqLevel = 15,
		reqAttack = 20,
		reqDefense = 16,
		reqBank = 2000,
		reqPotions = "Health / Mana Potion",
		damageMin = 10,
		damageMax = 28,
		healAmount = 35,
		waves = {
			{ name = "Amazon", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 85, countMin = 15, countMax = 50, isMoney = true },
			{ id = 11444, name = "Protective Charm", price = 200, chance = 25, countMin = 1, countMax = 2 },
			{ id = 3273, name = "Sabre", price = 12, chance = 30, countMin = 1, countMax = 1 },
			{ id = 3267, name = "Dagger", price = 2, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3377, name = "Scale Armor", price = 75, chance = 10, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 3,
		name = "Cyclops (Fácil)",
		tier = "easy",
		level = 25,
		focus = "More EXP",
		desc = "3 Cyclops corpulentos com bom ganho de experiência e Cyclops Toes.",
		monster = "Cyclops",
		lookType = 22,
		elements = { physical = 0, fire = 0, earth = -20, energy = 0, ice = 0, holy = 10, death = 10 },
		pos = ROOM_POS_EASY,
		baseExp = 150,
		supplyCostPerTurn = 30,
		reqLevel = 25,
		reqAttack = 28,
		reqDefense = 22,
		reqBank = 4000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 20,
		damageMax = 55,
		healAmount = 60,
		waves = {
			{ name = "Cyclops", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 25, countMax = 80, isMoney = true },
			{ id = 9657, name = "Cyclops Toe", price = 55, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3413, name = "Battle Shield", price = 95, chance = 18, countMin = 1, countMax = 1 },
			{ id = 3269, name = "Halberd", price = 400, chance = 12, countMin = 1, countMax = 1 },
			{ id = 3384, name = "Dark Helmet", price = 250, chance = 8, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 4,
		name = "Minotaurs (Fácil)",
		tier = "easy",
		level = 20,
		focus = "More Loot",
		desc = "3 Minotaurs com alto rendimento de Minotaur Leather.",
		monster = "Minotaur",
		lookType = 29,
		elements = { physical = 0, fire = -20, earth = 0, energy = 0, ice = 10, holy = 0, death = 10 },
		pos = ROOM_POS_EASY,
		baseExp = 120,
		supplyCostPerTurn = 25,
		reqLevel = 20,
		reqAttack = 24,
		reqDefense = 20,
		reqBank = 3000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 18,
		damageMax = 48,
		healAmount = 50,
		waves = {
			{ name = "Minotaur", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 20, countMax = 70, isMoney = true },
			{ id = 5878, name = "Minotaur Leather", price = 80, chance = 35, countMin = 1, countMax = 2 },
			{ id = 11472, name = "Minotaur Horn", price = 75, chance = 30, countMin = 1, countMax = 2 },
			{ id = 3266, name = "Battle Axe", price = 80, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3275, name = "Double Axe", price = 260, chance = 10, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 5,
		name = "Undeads (Fácil)",
		tier = "easy",
		level = 22,
		focus = "Balanced",
		desc = "3 Skeletons antigos para treino rápido.",
		monster = "Skeleton",
		lookType = 18,
		elements = { physical = -20, fire = 10, earth = 100, energy = 0, ice = 0, holy = 20, death = -100 },
		pos = ROOM_POS_EASY,
		baseExp = 110,
		supplyCostPerTurn = 25,
		reqLevel = 22,
		reqAttack = 25,
		reqDefense = 20,
		reqBank = 3500,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 15,
		damageMax = 45,
		healAmount = 45,
		waves = {
			{ name = "Skeleton", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 15, countMax = 60, isMoney = true },
			{ id = 3115, name = "Bone", price = 5, chance = 40, countMin = 1, countMax = 3 },
			{ id = 3351, name = "Steel Helmet", price = 293, chance = 10, countMin = 1, countMax = 1 },
			{ id = 3410, name = "Plate Shield", price = 45, chance = 20, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 6,
		name = "Dragons (Fácil)",
		tier = "easy",
		level = 50,
		focus = "More EXP",
		desc = "3 Dragons clássicos. Excelente avanço de experiência intermediária.",
		monster = "Dragon",
		lookType = 34,
		elements = { physical = 0, fire = -100, earth = -100, energy = -10, ice = 10, holy = 0, death = 0 },
		pos = ROOM_POS_EASY,
		baseExp = 700,
		supplyCostPerTurn = 80,
		reqLevel = 50,
		reqAttack = 40,
		reqDefense = 35,
		reqBank = 12000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 50,
		damageMax = 140,
		healAmount = 150,
		waves = {
			{ name = "Dragon", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 50, countMax = 160, isMoney = true },
			{ id = 3583, name = "Dragon Ham", price = 25, chance = 60, countMin = 1, countMax = 3 },
			{ id = 11457, name = "Dragon's Tail", price = 100, chance = 30, countMin = 1, countMax = 2 },
			{ id = 5877, name = "Green Dragon Leather", price = 100, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3297, name = "Serpent Sword", price = 900, chance = 12, countMin = 1, countMax = 1 },
			{ id = 3416, name = "Dragon Shield", price = 4000, chance = 6, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 7,
		name = "Demons (Fácil)",
		tier = "easy",
		level = 80,
		focus = "More EXP",
		desc = "3 Fire Elementals incandescentes para treinar combate elemental.",
		monster = "Fire Elemental",
		lookType = 49,
		elements = { physical = -10, fire = -100, earth = 0, energy = 0, ice = 25, holy = 0, death = 0 },
		pos = ROOM_POS_EASY,
		baseExp = 1200,
		supplyCostPerTurn = 130,
		reqLevel = 80,
		reqAttack = 52,
		reqDefense = 42,
		reqBank = 25000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 90,
		damageMax = 230,
		healAmount = 240,
		waves = {
			{ name = "Fire Elemental", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 60, countMax = 200, isMoney = true },
			{ id = 3046, name = "Magic Sulphur", price = 1000, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3280, name = "Fire Sword", price = 4000, chance = 8, countMin = 1, countMax = 1 },
		},
	},

	-- =========================================================================
	-- 🟡 MÉDIO (MEDIUM) - Sala: Position(421, 301, 11) - 4 a 5 Monstros por Onda
	-- =========================================================================
	{
		id = 8,
		name = "Rotworms (Médio)",
		tier = "medium",
		level = 20,
		focus = "Balanced",
		desc = "3 Rotworms acompanhados por 2 Carrion Worms famintos.",
		monster = "Carrion Worm",
		lookType = 26,
		elements = { physical = 0, fire = 0, earth = 10, energy = -10, ice = 0, holy = 0, death = 0 },
		pos = ROOM_POS_MEDIUM,
		baseExp = 110,
		supplyCostPerTurn = 25,
		reqLevel = 20,
		reqAttack = 26,
		reqDefense = 22,
		reqBank = 3000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 15,
		damageMax = 45,
		healAmount = 50,
		waves = {
			{ name = "Rotworm", count = 3 },
			{ name = "Carrion Worm", count = 2 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 20, countMax = 80, isMoney = true },
			{ id = 3492, name = "Worm", price = 1, chance = 50, countMin = 2, countMax = 8 },
			{ id = 3577, name = "Meat", price = 2, chance = 40, countMin = 1, countMax = 4 },
			{ id = 3286, name = "Mace", price = 30, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3264, name = "Sword", price = 25, chance = 18, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 9,
		name = "Amazons (Médio)",
		tier = "medium",
		level = 28,
		focus = "More Loot",
		desc = "2 Amazons e 3 Valkyries atiradoras de lanças.",
		monster = "Valkyrie",
		lookType = 137,
		elements = { physical = 0, fire = 0, earth = 0, energy = 0, ice = 10, holy = 0, death = 10 },
		pos = ROOM_POS_MEDIUM,
		baseExp = 180,
		supplyCostPerTurn = 35,
		reqLevel = 28,
		reqAttack = 32,
		reqDefense = 26,
		reqBank = 5000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 25,
		damageMax = 65,
		healAmount = 70,
		waves = {
			{ name = "Amazon", count = 2 },
			{ name = "Valkyrie", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 30, countMax = 100, isMoney = true },
			{ id = 11444, name = "Protective Charm", price = 200, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3277, name = "Spear", price = 3, chance = 50, countMin = 1, countMax = 3 },
			{ id = 3377, name = "Scale Armor", price = 75, chance = 15, countMin = 1, countMax = 1 },
			{ id = 3410, name = "Plate Shield", price = 45, chance = 20, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 10,
		name = "Cyclops (Médio)",
		tier = "medium",
		level = 40,
		focus = "More EXP",
		desc = "3 Cyclops e 2 Cyclops Drones agressivos.",
		monster = "Cyclops Drone",
		lookType = 22,
		elements = { physical = 0, fire = 0, earth = -20, energy = 0, ice = 5, holy = 10, death = 10 },
		pos = ROOM_POS_MEDIUM,
		baseExp = 320,
		supplyCostPerTurn = 55,
		reqLevel = 40,
		reqAttack = 38,
		reqDefense = 30,
		reqBank = 8000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 40,
		damageMax = 95,
		healAmount = 100,
		waves = {
			{ name = "Cyclops", count = 3 },
			{ name = "Cyclops Drone", count = 2 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 40, countMax = 140, isMoney = true },
			{ id = 9657, name = "Cyclops Toe", price = 55, chance = 40, countMin = 1, countMax = 3 },
			{ id = 3269, name = "Halberd", price = 400, chance = 15, countMin = 1, countMax = 1 },
			{ id = 3384, name = "Dark Helmet", price = 250, chance = 12, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 11,
		name = "Minotaurs (Médio)",
		tier = "medium",
		level = 35,
		focus = "More Loot",
		desc = "2 Minotaurs, 2 Minotaur Guards e 1 Minotaur Archer.",
		monster = "Minotaur Guard",
		lookType = 29,
		elements = { physical = 0, fire = -20, earth = 0, energy = 0, ice = 10, holy = 0, death = 10 },
		pos = ROOM_POS_MEDIUM,
		baseExp = 260,
		supplyCostPerTurn = 50,
		reqLevel = 35,
		reqAttack = 36,
		reqDefense = 28,
		reqBank = 7000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 35,
		damageMax = 85,
		healAmount = 90,
		waves = {
			{ name = "Minotaur", count = 2 },
			{ name = "Minotaur Guard", count = 2 },
			{ name = "Minotaur Archer", count = 1 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 35, countMax = 120, isMoney = true },
			{ id = 5878, name = "Minotaur Leather", price = 80, chance = 40, countMin = 1, countMax = 3 },
			{ id = 11472, name = "Minotaur Horn", price = 75, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3275, name = "Double Axe", price = 260, chance = 15, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 12,
		name = "Undeads (Médio)",
		tier = "medium",
		level = 45,
		focus = "Balanced",
		desc = "2 Ghouls e 2 Crypt Shamblers rastejantes.",
		monster = "Crypt Shambler",
		lookType = 18,
		elements = { physical = -10, fire = 20, earth = 100, energy = 0, ice = 0, holy = 25, death = -100 },
		pos = ROOM_POS_MEDIUM,
		baseExp = 380,
		supplyCostPerTurn = 65,
		reqLevel = 45,
		reqAttack = 40,
		reqDefense = 32,
		reqBank = 10000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 45,
		damageMax = 110,
		healAmount = 115,
		waves = {
			{ name = "Ghoul", count = 2 },
			{ name = "Crypt Shambler", count = 2 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 40, countMax = 130, isMoney = true },
			{ id = 9647, name = "Rotten Piece of Cloth", price = 30, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3115, name = "Bone", price = 5, chance = 45, countMin = 1, countMax = 3 },
			{ id = 3369, name = "Warrior Helmet", price = 5000, chance = 5, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 13,
		name = "Dragons (Médio)",
		tier = "medium",
		level = 75,
		focus = "More EXP",
		desc = "4 Dragons soltando rajadas de fogo contínuas.",
		monster = "Dragon",
		lookType = 34,
		elements = { physical = 0, fire = -100, earth = -100, energy = -10, ice = 10, holy = 0, death = 0 },
		pos = ROOM_POS_MEDIUM,
		baseExp = 1100,
		supplyCostPerTurn = 130,
		reqLevel = 75,
		reqAttack = 48,
		reqDefense = 40,
		reqBank = 22000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 85,
		damageMax = 220,
		healAmount = 230,
		waves = {
			{ name = "Dragon", count = 4 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 70, countMax = 220, isMoney = true },
			{ id = 3583, name = "Dragon Ham", price = 25, chance = 70, countMin = 1, countMax = 4 },
			{ id = 11457, name = "Dragon's Tail", price = 100, chance = 35, countMin = 1, countMax = 2 },
			{ id = 5877, name = "Green Dragon Leather", price = 100, chance = 30, countMin = 1, countMax = 2 },
			{ id = 3416, name = "Dragon Shield", price = 4000, chance = 8, countMin = 1, countMax = 1 },
			{ id = 3280, name = "Fire Sword", price = 4000, chance = 7, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 14,
		name = "Demons (Médio)",
		tier = "medium",
		level = 120,
		focus = "More EXP",
		desc = "2 Fire Elementals e 2 Diabolic Imps traiçoeiros.",
		monster = "Diabolic Imp",
		lookType = 49,
		elements = { physical = 0, fire = -100, earth = -100, energy = 0, ice = 15, holy = 10, death = -10 },
		pos = ROOM_POS_MEDIUM,
		baseExp = 2600,
		supplyCostPerTurn = 260,
		reqLevel = 120,
		reqAttack = 62,
		reqDefense = 52,
		reqBank = 45000,
		reqPotions = "Ultimate Health / Great Mana Potion",
		damageMin = 180,
		damageMax = 440,
		healAmount = 450,
		waves = {
			{ name = "Fire Elemental", count = 2 },
			{ name = "Diabolic Imp", count = 2 }
		},
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 85, countMin = 1, countMax = 5, isMoney = true },
			{ id = 3046, name = "Magic Sulphur", price = 1000, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3051, name = "Energy Ring", price = 500, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3420, name = "Demon Shield", price = 30000, chance = 3, countMin = 1, countMax = 1 },
		},
	},

	-- =========================================================================
	-- 🔴 DIFÍCIL (HARD) - Sala: Position(440, 785, 11) - 6 a 7 Monstros por Onda
	-- =========================================================================
	{
		id = 15,
		name = "Rotworms (Difícil)",
		tier = "hard",
		level = 35,
		focus = "Balanced",
		desc = "4 Carrion Worms e 2 Rotworm Queens enfurecidas.",
		monster = "Rotworm Queen",
		lookType = 26,
		elements = { physical = 0, fire = 0, earth = 20, energy = -15, ice = 0, holy = 0, death = 0 },
		pos = ROOM_POS_HARD,
		baseExp = 310,
		supplyCostPerTurn = 50,
		reqLevel = 35,
		reqAttack = 36,
		reqDefense = 30,
		reqBank = 6000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 35,
		damageMax = 90,
		healAmount = 95,
		waves = {
			{ name = "Carrion Worm", count = 4 },
			{ name = "Rotworm Queen", count = 2 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 40, countMax = 130, isMoney = true },
			{ id = 3492, name = "Worm", price = 1, chance = 60, countMin = 3, countMax = 10 },
			{ id = 3577, name = "Meat", price = 2, chance = 50, countMin = 2, countMax = 6 },
			{ id = 3286, name = "Mace", price = 30, chance = 25, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 16,
		name = "Amazons (Difícil)",
		tier = "hard",
		level = 45,
		focus = "More Loot",
		desc = "4 Valkyries armadas e 2 Witches conjuradoras de fogo.",
		monster = "Witch",
		lookType = 137,
		elements = { physical = 0, fire = -20, earth = 0, energy = -20, ice = 10, holy = 0, death = 10 },
		pos = ROOM_POS_HARD,
		baseExp = 420,
		supplyCostPerTurn = 70,
		reqLevel = 45,
		reqAttack = 42,
		reqDefense = 34,
		reqBank = 9000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 45,
		damageMax = 120,
		healAmount = 125,
		waves = {
			{ name = "Valkyrie", count = 4 },
			{ name = "Witch", count = 2 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 50, countMax = 160, isMoney = true },
			{ id = 11444, name = "Protective Charm", price = 200, chance = 45, countMin = 1, countMax = 3 },
			{ id = 3277, name = "Spear", price = 3, chance = 60, countMin = 2, countMax = 5 },
			{ id = 3377, name = "Scale Armor", price = 75, chance = 20, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 17,
		name = "Cyclops (Difícil)",
		tier = "hard",
		level = 60,
		focus = "More EXP",
		desc = "3 Cyclops Drones e 3 Cyclops Smiths forjadores.",
		monster = "Cyclops Smith",
		lookType = 22,
		elements = { physical = 0, fire = -50, earth = -20, energy = 0, ice = 10, holy = 10, death = 10 },
		pos = ROOM_POS_HARD,
		baseExp = 780,
		supplyCostPerTurn = 100,
		reqLevel = 60,
		reqAttack = 46,
		reqDefense = 38,
		reqBank = 15000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 65,
		damageMax = 170,
		healAmount = 180,
		waves = {
			{ name = "Cyclops Drone", count = 3 },
			{ name = "Cyclops Smith", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 60, countMax = 200, isMoney = true },
			{ id = 9657, name = "Cyclops Toe", price = 55, chance = 50, countMin = 1, countMax = 4 },
			{ id = 3269, name = "Halberd", price = 400, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3384, name = "Dark Helmet", price = 250, chance = 18, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 18,
		name = "Minotaurs (Difícil)",
		tier = "hard",
		level = 55,
		focus = "More Loot",
		desc = "3 Minotaur Guards, 2 Minotaur Archers e 2 Minotaur Mages.",
		monster = "Minotaur Mage",
		lookType = 29,
		elements = { physical = 0, fire = -20, earth = 0, energy = -100, ice = 10, holy = 0, death = 10 },
		pos = ROOM_POS_HARD,
		baseExp = 690,
		supplyCostPerTurn = 90,
		reqLevel = 55,
		reqAttack = 44,
		reqDefense = 36,
		reqBank = 14000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 60,
		damageMax = 155,
		healAmount = 165,
		waves = {
			{ name = "Minotaur Guard", count = 3 },
			{ name = "Minotaur Archer", count = 2 },
			{ name = "Minotaur Mage", count = 2 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 50, countMax = 180, isMoney = true },
			{ id = 5878, name = "Minotaur Leather", price = 80, chance = 50, countMin = 1, countMax = 4 },
			{ id = 11472, name = "Minotaur Horn", price = 75, chance = 40, countMin = 1, countMax = 3 },
			{ id = 3275, name = "Double Axe", price = 260, chance = 20, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 19,
		name = "Undeads (Difícil)",
		tier = "hard",
		level = 70,
		focus = "Balanced",
		desc = "3 Crypt Shamblers, 2 Bonebeasts e 1 Vampire sinistro.",
		monster = "Vampire",
		lookType = 18,
		elements = { physical = 0, fire = 10, earth = 100, energy = 0, ice = 0, holy = 25, death = -100 },
		pos = ROOM_POS_HARD,
		baseExp = 980,
		supplyCostPerTurn = 120,
		reqLevel = 70,
		reqAttack = 50,
		reqDefense = 40,
		reqBank = 20000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 80,
		damageMax = 210,
		healAmount = 220,
		waves = {
			{ name = "Crypt Shambler", count = 3 },
			{ name = "Bonebeast", count = 2 },
			{ name = "Vampire", count = 1 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 60, countMax = 220, isMoney = true },
			{ id = 9647, name = "Rotten Piece of Cloth", price = 30, chance = 45, countMin = 1, countMax = 3 },
			{ id = 3115, name = "Bone", price = 5, chance = 50, countMin = 2, countMax = 5 },
			{ id = 3369, name = "Warrior Helmet", price = 5000, chance = 8, countMin = 1, countMax = 1 },
			{ id = 3434, name = "Vampire Shield", price = 15000, chance = 4, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 20,
		name = "Dragons (Difícil)",
		tier = "hard",
		level = 100,
		focus = "More EXP",
		desc = "3 Dragons enfurecidos e 3 Dragon Lords devastadores.",
		monster = "Dragon Lord",
		lookType = 39,
		elements = { physical = 0, fire = -100, earth = -100, energy = -20, ice = 10, holy = 0, death = 0 },
		pos = ROOM_POS_HARD,
		baseExp = 2800,
		supplyCostPerTurn = 280,
		reqLevel = 100,
		reqAttack = 58,
		reqDefense = 48,
		reqBank = 50000,
		reqPotions = "Ultimate Health / Great Mana Potion",
		damageMin = 190,
		damageMax = 460,
		healAmount = 480,
		waves = {
			{ name = "Dragon", count = 3 },
			{ name = "Dragon Lord", count = 3 }
		},
		lootTable = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 100, countMax = 320, isMoney = true },
			{ id = 5882, name = "Red Dragon Scale", price = 200, chance = 35, countMin = 1, countMax = 2 },
			{ id = 5877, name = "Green Dragon Leather", price = 100, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3280, name = "Fire Sword", price = 4000, chance = 12, countMin = 1, countMax = 1 },
			{ id = 3428, name = "Tower Shield", price = 8000, chance = 8, countMin = 1, countMax = 1 },
			{ id = 3392, name = "Royal Helmet", price = 30000, chance = 5, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 21,
		name = "Demons (Difícil)",
		tier = "hard",
		level = 180,
		focus = "More EXP",
		desc = "4 Diabolic Imps velozes e 2 Demons titânicos.",
		monster = "Demon",
		lookType = 35,
		elements = { physical = 0, fire = -100, earth = -100, energy = -20, ice = 10, holy = 12, death = -20 },
		pos = ROOM_POS_HARD,
		baseExp = 6800,
		supplyCostPerTurn = 500,
		reqLevel = 180,
		reqAttack = 75,
		reqDefense = 65,
		reqBank = 100000,
		reqPotions = "Supreme Health / Ultimate Mana Potion",
		damageMin = 350,
		damageMax = 850,
		healAmount = 900,
		waves = {
			{ name = "Diabolic Imp", count = 4 },
			{ name = "Demon", count = 2 }
		},
		lootTable = {
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 95, countMin = 3, countMax = 12, isMoney = true },
			{ id = 3046, name = "Magic Sulphur", price = 1000, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3051, name = "Energy Ring", price = 500, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3420, name = "Demon Shield", price = 30000, chance = 6, countMin = 1, countMax = 1 },
			{ id = 3388, name = "Mastermind Shield", price = 50000, chance = 3, countMin = 1, countMax = 1 },
		},
	},
}

-- TABELA MESTRE GLOBAL DE LOOTS (Pre-agregada de todas as caçadas)
local ALL_IDLE_LOOT_ITEMS = {}

for _, h in ipairs(IDLE_HUNTS) do
	if h.lootTable then
		for _, l in ipairs(h.lootTable) do
			if not l.isMoney and l.id ~= 3031 and l.id ~= 3035 and l.id ~= 3043 then
				ALL_IDLE_LOOT_ITEMS[l.id] = {
					id = l.id,
					name = l.name,
					price = l.price,
					chance = l.chance or 0
				}
			end
		end
	end
end

-- Tabela Global de Sessões de Caçada
_G.OnIdleHunt = _G.OnIdleHunt or {}

-- Obter Hunt por ID
local function getHuntById(huntId)
	for _, h in ipairs(IDLE_HUNTS) do
		if h.id == huntId then
			return h
		end
	end
	return nil
end

-- Persistência de Regras de Loot no Banco de Dados (player_storage)
local function getPlayerLootRule(player, itemId)
	local val = player:getStorageValue(STORAGE_IDLE_LOOT_BASE + itemId)
	if val == 1 then
		return "sell"
	else
		return "keep" -- Padrão: [LOCKED] Safe in Backpack
	end
end

local function setPlayerLootRule(player, itemId, rule)
	if rule == "sell" then
		player:setStorageValue(STORAGE_IDLE_LOOT_BASE + itemId, 1)
	else
		player:setStorageValue(STORAGE_IDLE_LOOT_BASE + itemId, 0)
	end
end

local function getPlayerAutoLootRule(player, itemId)
	local val = player:getStorageValue(STORAGE_IDLE_AUTOLOOT_BASE + itemId)
	if val == 0 then
		return false -- Ignorado
	end
	return true -- Coletar (padrão)
end

local function setPlayerAutoLootRule(player, itemId, enabled)
	player:setStorageValue(STORAGE_IDLE_AUTOLOOT_BASE + itemId, enabled and 1 or 0)
end

-- Stamina IDLE (Armazenada no Storage 95000)
local function getPlayerIdleStamina(player)
	local val = player:getStorageValue(STORAGE_IDLE_STAMINA)
	if val < 0 then
		player:setStorageValue(STORAGE_IDLE_STAMINA, MAX_IDLE_STAMINA)
		return MAX_IDLE_STAMINA
	end
	return math.min(MAX_IDLE_STAMINA, val)
end

local function setPlayerIdleStamina(player, amount)
	local clamped = math.max(0, math.min(MAX_IDLE_STAMINA, amount))
	player:setStorageValue(STORAGE_IDLE_STAMINA, clamped)
	return clamped
end

-- Avaliação de Requisitos
local function evaluateHuntRequirements(player, hunt)
	local pLevel = player:getLevel()
	local pSkillSword = player:getSkillLevel(SKILL_SWORD)
	local pSkillAxe = player:getSkillLevel(SKILL_AXE)
	local pSkillClub = player:getSkillLevel(SKILL_CLUB)
	local pSkillDist = player:getSkillLevel(SKILL_DISTANCE)
	local pSkillMag = player:getMagicLevel()

	local pAttack = math.max(pSkillSword, pSkillAxe, pSkillClub, pSkillDist, pSkillMag)
	local pDefense = player:getSkillLevel(SKILL_SHIELD)
	local pBank = player:getBankBalance()

	local okLevel = pLevel >= hunt.reqLevel
	local okAttack = pAttack >= hunt.reqAttack
	local okDefense = pDefense >= hunt.reqDefense
	local okBank = pBank >= hunt.reqBank

	local meetsAll = okLevel and okAttack and okDefense and okBank

	return meetsAll, {
		level = { player = pLevel, required = hunt.reqLevel, ok = okLevel },
		attack = { player = pAttack, required = hunt.reqAttack, ok = okAttack },
		defense = { player = pDefense, required = hunt.reqDefense, ok = okDefense },
		bank = { player = pBank, required = hunt.reqBank, ok = okBank },
		potions = hunt.reqPotions,
	}
end

-- Descrição de Look do Item
local function getItemLookDescription(itemId)
	local it = ItemType(itemId)
	if not it or it:getId() == 0 then
		return ""
	end

	local name = it:getName()
	local article = it:getArticle()
	local arm = it:getArmor()
	local atk = it:getAttack()
	local def = it:getDefense()
	local extDef = it:getExtraDefense()
	local weight = it:getWeight(1) / 100
	local desc = it:getDescription()

	local title = (article and article ~= "" and (article .. " ") or "") .. name
	local stats = {}
	if arm and arm > 0 then
		table.insert(stats, string.format("Arm:%d", arm))
	end
	if atk and atk > 0 then
		table.insert(stats, string.format("Atk:%d", atk))
	end
	if def and def > 0 then
		if extDef and extDef ~= 0 then
			table.insert(stats, string.format("Def:%d %+d", def, extDef))
		else
			table.insert(stats, string.format("Def:%d", def))
		end
	end

	local statStr = ""
	if #stats > 0 then
		statStr = " (" .. table.concat(stats, ", ") .. ")"
	end

	local look = string.format("You see %s%s.", title, statStr)
	if desc and desc ~= "" then
		look = look .. "\n" .. desc
	end
	if weight and weight > 0 then
		look = look .. string.format("\nIt weighs %.2f oz.", weight)
	end
	return look
end

-- =========================================================================
-- ENGINE DE VENDA DEFINITIVA: Quick Sell & Auto-Sell (Varredura Global na Mochila)
-- =========================================================================
local function sellPlayerLootFromInventory(player, huntId, reason)
	local totalGold = 0
	local totalCount = 0

	-- Varredura sobre TODOS os itens da tabela mestre de caçadas IDLE
	for itemId, info in pairs(ALL_IDLE_LOOT_ITEMS) do
		local rule = getPlayerLootRule(player, itemId)
		if rule == "sell" then
			local countInBag = player:getItemCount(itemId)
			if countInBag > 0 then
				if player:removeItem(itemId, countInBag) then
					local earned = countInBag * info.price
					totalGold = totalGold + earned
					totalCount = totalCount + countInBag
				end
			end
		end
	end

	if totalGold > 0 then
		player:addMoneyBank(totalGold)
		player:sendBankBalance()

		local prefix = (reason == "quick") and "[QUICK SELL]" or "[AUTO-SELL 10M]"
		player:sendTextMessage(
			MESSAGE_EVENT_ADVANCE,
			string.format(
				"%s: %d item(s) from your backpack were sold for %s gold coins deposited into your bank!",
				prefix,
				totalCount,
				formatNumber(totalGold)
			)
		)
		return totalGold, totalCount
	end

	return 0, 0
end

-- Envio de Atualização da Janela de Loot & Sell para o Cliente
local function sendLootUpdateOpcode(player, huntId)
	local playerId = player:getId()
	local session = _G.OnIdleHunt[playerId]
	local lootParts = {}
	local pendingSaleGold = 0
	local seenItems = {}

	-- 1. Itens da Hunt Ativa (se houver)
	local hunt = getHuntById(huntId)
	if hunt and hunt.lootTable then
		for _, l in ipairs(hunt.lootTable) do
			if not l.isMoney and l.id ~= 3031 and l.id ~= 3035 and l.id ~= 3043 then
				seenItems[l.id] = true
				local rule = getPlayerLootRule(player, l.id)
				local droppedCount = (session and session.droppedCounts and session.droppedCounts[l.id]) or 0
				local inBag = player:getItemCount(l.id)
				if rule == "sell" then
					pendingSaleGold = pendingSaleGold + (inBag * l.price)
				end
				local look = getItemLookDescription(l.id)
				table.insert(
					lootParts,
					string.format(
						'{"id":%d,"name":%s,"price":%d,"chance":%d,"rule":%s,"autoloot":%s,"dropped":%d,"in_bag":%d,"look":%s}',
						l.id, escapeJsonString(l.name), l.price, l.chance, escapeJsonString(rule), getPlayerAutoLootRule(player, l.id) and "true" or "false", droppedCount, inBag, escapeJsonString(look)
					)
				)
			end
		end
	end

	-- 2. Itens da Tabela Mestre Global que o jogador tem na mochila
	for itemId, info in pairs(ALL_IDLE_LOOT_ITEMS) do
		if not seenItems[itemId] then
			local inBag = player:getItemCount(itemId)
			if inBag > 0 then
				local rule = getPlayerLootRule(player, itemId)
				if rule == "sell" then
					pendingSaleGold = pendingSaleGold + (inBag * info.price)
				end
				local look = getItemLookDescription(itemId)
				table.insert(
					lootParts,
					string.format(
						'{"id":%d,"name":%s,"price":%d,"chance":%d,"rule":%s,"dropped":0,"in_bag":%d,"look":%s}',
						itemId, escapeJsonString(info.name), info.price, info.chance or 0, escapeJsonString(rule), inBag, escapeJsonString(look)
					)
				)
			end
		end
	end

	local now = os.time()
	local nextAutosell = session and math.max(0, 600 - (now - (session.lastAutoSell or now))) or 600
	local lastQ = session and session.lastQuickSell or (player:getStorageValue(STORAGE_LAST_QUICK_SELL) > 0 and player:getStorageValue(STORAGE_LAST_QUICK_SELL) or 0)
	local quickCooldown = math.max(0, 120 - (now - lastQ))

	local huntName = (hunt and hunt.name) or "Global Loot"
	local response = string.format(
		'{"action":"hunt_loot","hunt_id":%d,"hunt_name":%s,"pending_gold":%d,"next_autosell":%d,"quick_cooldown":%d,"loot":[%s]}',
		huntId or 0, escapeJsonString(huntName), pendingSaleGold, nextAutosell, quickCooldown, table.concat(lootParts, ",")
	)
	player:sendExtendedOpcode(OPCODE_IDLE_HUNT, response)
end

-- =========================================================================
-- =========================================================================
-- INSTANCIAÇÃO DINÂMICA DE ARENAS IDLE EM ÁREAS ISOLADAS DO MAPA
-- =========================================================================
local function ensureArenaTiles(center, radius, groundId, wallId)
	if not center then return end
	radius = radius or 6
	groundId = groundId or 104 -- Sand floor
	wallId = wallId or 602     -- Rock wall barrier

	-- 1. Cria o chão caminhável do interior da arena
	for x = center.x - radius, center.x + radius do
		for y = center.y - radius, center.y + radius do
			local pos = Position(x, y, center.z)
			local tile = Tile(pos)
			if not tile then
				tile = Game.createTile(pos)
			end
			if tile and not tile:getGround() then
				tile:addItem(groundId, 1, FLAG_NOLIMIT)
			end
		end
	end

	-- 2. Cria paredes de pedra no perímetro para limitar a sala
	local outer = radius + 1
	for x = center.x - outer, center.x + outer do
		for _, y in ipairs({ center.y - outer, center.y + outer }) do
			local pos = Position(x, y, center.z)
			local tile = Tile(pos)
			if not tile then tile = Game.createTile(pos) end
			if tile then
				if not tile:getGround() then tile:addItem(groundId, 1, FLAG_NOLIMIT) end
				if not tile:getItemById(wallId) then tile:addItem(wallId, 1, FLAG_NOLIMIT) end
			end
		end
	end
	for y = center.y - outer, center.y + outer do
		for _, x in ipairs({ center.x - outer, center.x + outer }) do
			local pos = Position(x, y, center.z)
			local tile = Tile(pos)
			if not tile then tile = Game.createTile(pos) end
			if tile then
				if not tile:getGround() then tile:addItem(groundId, 1, FLAG_NOLIMIT) end
				if not tile:getItemById(wallId) then tile:addItem(wallId, 1, FLAG_NOLIMIT) end
			end
		end
	end
end

-- =========================================================================
-- ENGINE DE SPAWN CONTÍNUO POR ONDAS (WAVES) NA SALA INSTANCIADA
-- =========================================================================
local function clearArenaArea(centerPos, radius)
	if not centerPos then return end
	radius = radius or 8
	for x = centerPos.x - radius, centerPos.x + radius do
		for y = centerPos.y - radius, centerPos.y + radius do
			local tile = Tile(Position(x, y, centerPos.z))
			if tile then
				local creatures = tile:getCreatures()
				if creatures then
					for _, c in ipairs(creatures) do
						if c:isMonster() then
							c:getPosition():sendMagicEffect(CONST_ME_POFF)
							c:remove()
						end
					end
				end
			end
		end
	end
end

local function clearHuntMonsters(session, huntPos)
	if session and session.spawnedMonsters then
		for _, mId in ipairs(session.spawnedMonsters) do
			local m = Monster(mId)
			if m and not m:isDead() then
				local mPos = m:getPosition()
				mPos:sendMagicEffect(CONST_ME_POFF)
				m:remove()
			end
		end
		session.spawnedMonsters = {}
	end
	if huntPos then
		clearArenaArea(huntPos, 8)
	end
end

local function spawnHuntWave(player, hunt, session)
	if not player or not session or not hunt then return end
	local pPos = player:getPosition()
	session.spawnedMonsters = session.spawnedMonsters or {}

	-- SEGURANÇA TOTAL: Impedir qualquer spawn caso o jogador não esteja na arena da caçada
	if hunt.pos then
		local dist = math.max(math.abs(pPos.x - hunt.pos.x), math.abs(pPos.y - hunt.pos.y))
		if pPos.z ~= hunt.pos.z or dist > 8 then
			return
		end
	end

	-- Limpar IDs de monstros que já morreram
	local aliveMonsters = {}
	for _, mId in ipairs(session.spawnedMonsters) do
		local m = Monster(mId)
		if m and not m:isDead() then
			table.insert(aliveMonsters, mId)
		end
	end
	session.spawnedMonsters = aliveMonsters

	-- Se ainda há monstros vivos na onda atual, não invoca nova onda
	if #session.spawnedMonsters > 0 then
		return
	end

	-- Limite de monstros pela intensidade do Pull escolhido pelo jogador
	local pull = session.pull or "bold"
	local maxPullMonsters = 3
	if pull == "cautious" then
		maxPullMonsters = 1
	elseif pull == "bold" then
		maxPullMonsters = (hunt.tier == "easy") and 2 or ((hunt.tier == "medium") and 3 or 4)
	elseif pull == "aggressive" then
		maxPullMonsters = (hunt.tier == "easy") and 3 or ((hunt.tier == "medium") and 5 or 7)
	end

	-- Invocação da nova onda
	local offsets = {
		{ x = -1, y = -1 }, { x = 1, y = -1 }, { x = -1, y = 1 }, { x = 1, y = 1 },
		{ x = 0, y = -2 }, { x = 0, y = 2 }, { x = -2, y = 0 }, { x = 2, y = 0 }
	}
	local offsetIndex = 1
	local totalSpawned = 0

	if hunt.waves then
		for _, w in ipairs(hunt.waves) do
			for i = 1, w.count do
				if totalSpawned >= maxPullMonsters then
					break
				end
				local off = offsets[offsetIndex] or { x = math.random(-2, 2), y = math.random(-2, 2) }
				offsetIndex = (offsetIndex % #offsets) + 1
				local spawnPos = Position(pPos.x + off.x, pPos.y + off.y, pPos.z)

				local monster = Game.createMonster(w.name, spawnPos, true, true)
				if monster then
					monster:setDropLoot(false)
					spawnPos:sendMagicEffect(CONST_ME_TELEPORT)
					monster:setTarget(player)
					table.insert(session.spawnedMonsters, monster:getId())
					totalSpawned = totalSpawned + 1
				end
			end
			if totalSpawned >= maxPullMonsters then
				break
			end
		end
	end
end

-- Telemetria de Status da Caçada Ativa
local function sendHuntStatusOpcode(player, huntId, session, curStamina, maxHp)
	local now = os.time()
	local curExp = player:getExperience()
	session.xpGained = math.max(0, curExp - (session.startExperience or curExp))
	local nextAutosell = math.max(0, 600 - (now - (session.lastAutoSell or now)))
	local lastQ = session.lastQuickSell or (player:getStorageValue(STORAGE_LAST_QUICK_SELL) > 0 and player:getStorageValue(STORAGE_LAST_QUICK_SELL) or 0)
	local quickCooldown = math.max(0, 120 - (now - lastQ))
	local elapsed = math.max(1, now - (session.startTime or now))
	local rateExp = math.floor(((session.xpGained or 0) / elapsed) * 3600)
	local rateGp = math.floor(((session.goldEarned or 0) / elapsed) * 3600)

	local statusJson = string.format(
		'{"action":"hunt_status","hunt_id":%d,"hp_percent":%d,"xp_session":%d,"supplies_spent":%d,"idle_stamina":%d,"pending_gold":%d,"next_autosell":%d,"quick_cooldown":%d,"elapsed":%d,"rate_exp":%d,"rate_gp":%d,"pull":%q}',
		huntId,
		math.floor((player:getHealth() / maxHp) * 100),
		session.xpGained or 0,
		session.suppliesSpent or 0,
		curStamina,
		session.goldEarned or 0,
		nextAutosell,
		quickCooldown,
		elapsed,
		rateExp,
		rateGp,
		session.pull or "bold"
	)
	player:sendExtendedOpcode(OPCODE_IDLE_HUNT, statusJson)
end

-- Finalizar Caçada IDLE
local function stopIdleHunt(playerId, reason, isEmergency, skipTeleport)
	local session = _G.OnIdleHunt[playerId]
	local huntId = session and session.huntId or 1

	local hunt = getHuntById(huntId)
	if session then
		if session.event then
			stopEvent(session.event)
		end
		clearHuntMonsters(session, hunt and hunt.pos)
		_G.OnIdleHunt[playerId] = nil
	end

	local player = Player(playerId)
	if player then
		-- 1. Executa auto-venda de itens marcados com [$] antes de sair
		sellPlayerLootFromInventory(player, huntId, "auto")

		-- Verificação final de Recordes de XP/h e GP/h se durou pelo menos 10 minutos
		if session and session.startTime then
			local elapsed = os.time() - session.startTime
			if elapsed >= 600 then
				local curExpRate = math.floor(((session.xpGained or 0) / elapsed) * 3600)
				local curGpRate = math.floor(((session.goldEarned or 0) / elapsed) * 3600)
				local bestExp = math.max(0, player:getStorageValue(STORAGE_RECORD_EXP_BASE + huntId))
				local bestGp = math.max(0, player:getStorageValue(STORAGE_RECORD_GP_BASE + huntId))

				if curExpRate > bestExp then
					player:setStorageValue(STORAGE_RECORD_EXP_BASE + huntId, curExpRate)
					player:sendTextMessage(
						MESSAGE_EVENT_ADVANCE,
						string.format("[NOVO RECORDE IDLE]: Novo recorde de EXP/h em %s: %s XP/h!", (hunt and hunt.name or "Hunt"), formatNumber(curExpRate))
					)
				end
				if curGpRate > bestGp then
					player:setStorageValue(STORAGE_RECORD_GP_BASE + huntId, curGpRate)
				end
			end
		end

		-- 2. Limpa condições de combate
		player:unregisterEvent("IdleHuntMonsterKill")
		player:unregisterEvent("IdleHuntPlayerLogout")
		player:unregisterEvent("IdleHuntPlayerDeath")

		player:removeCondition(CONDITION_INFIGHT)
		player:removeCondition(CONDITION_HUNTING)

		-- 3. Teleporte seguro para o Templo
		if not skipTeleport then
			local town = player:getTown()
			local templePos = town and town:getTemplePosition()
			if not templePos then
				templePos = Position(32369, 32241, 7) -- Thais temple fallback
			end
			player:teleportTo(templePos)
			templePos:sendMagicEffect(CONST_ME_TELEPORT)
		end

		player:removeCondition(CONDITION_INFIGHT)
		player:removeCondition(CONDITION_HUNTING)

		local msg = reason or "Caçada IDLE finalizada."
		if isEmergency then
			player:sendTextMessage(
				MESSAGE_EVENT_ADVANCE,
				"[IDLE RESCUE]: Sua vida caiu abaixo de 10%! Você foi resgatado com segurança para o Templo."
			)
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, msg)
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

-- Ciclo IDLE (a cada 2 segundos)
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
		stopIdleHunt(playerId, "Hunt inválida.", false, false)
		return
	end

	-- 1. Stamina IDLE
	local curStamina = getPlayerIdleStamina(player)
	if curStamina <= 0 then
		stopIdleHunt(playerId, "Sua Stamina IDLE acabou! Caçada encerrada.", false, false)
		return
	end

	-- 2. Proteção de Emergência aos 10% HP
	local curHealth = player:getHealth()
	local maxHealth = player:getMaxHealth()
	local healthPercent = (curHealth / maxHealth) * 100
	if healthPercent <= 10 then
		if session.meetsRequirements then
			stopIdleHunt(playerId, "Resgate de Emergência aos 10% de HP.", true, false)
			return
		else
			if curHealth <= 0 then
				_G.OnIdleHunt[playerId] = nil
				return
			end
		end
	end

	-- 3. Verificação e Respawn Contínuo de Ondas
	spawnHuntWave(player, hunt, session)

	-- 4. Auto-Venda Recorrente e Verificação de Recordes a cada 10 Minutos
	local now = os.time()
	if (now - session.lastAutoSell) >= 600 then
		session.lastAutoSell = now
		sellPlayerLootFromInventory(player, huntId, "auto")
	end

	-- Verificação e Persistência de Recordes de XP/h e GP/h (após 10 minutos de caçada)
	local elapsed = now - (session.startTime or now)
	if elapsed >= 600 then
		local curExpRate = math.floor(((session.xpGained or 0) / elapsed) * 3600)
		local curGpRate = math.floor(((session.goldEarned or 0) / elapsed) * 3600)
		local bestExp = math.max(0, player:getStorageValue(STORAGE_RECORD_EXP_BASE + huntId))
		local bestGp = math.max(0, player:getStorageValue(STORAGE_RECORD_GP_BASE + huntId))

		if curExpRate > bestExp then
			player:setStorageValue(STORAGE_RECORD_EXP_BASE + huntId, curExpRate)
			player:sendTextMessage(
				MESSAGE_EVENT_ADVANCE,
				string.format("[NOVO RECORDE IDLE]: Novo recorde de EXP/h em %s: %s XP/h!", hunt.name, formatNumber(curExpRate))
			)
		end
		if curGpRate > bestGp then
			player:setStorageValue(STORAGE_RECORD_GP_BASE + huntId, curGpRate)
		end
	end

	-- 5. Consumo de Stamina IDLE (1 minuto a cada 3 minutos reais)
	session.turnCount = (session.turnCount or 0) + 1
	if session.turnCount >= 90 then
		session.turnCount = 0
		curStamina = setPlayerIdleStamina(player, curStamina - 1)
	end

	-- 6. Telemetria via Opcode 106
	if player:isUsingOtClient() and (session.turnCount % 2 == 0) then
		sendHuntStatusOpcode(player, huntId, session, curStamina, maxHealth)
	end

	session.event = addEvent(idleCombatLoop, 2000, playerId, huntId)
end

-- Iniciar Caçada IDLE
local function startIdleHunt(player, huntId, pull)
	local playerId = player:getId()

	if _G.OnIdleHunt[playerId] then
		stopIdleHunt(playerId, "Reiniciando caçada IDLE.", false, true)
	end

	local hunt = getHuntById(huntId)
	if not hunt then
		player:sendTextMessage(MESSAGE_FAILURE, "Hunt não encontrada.")
		return false
	end

	local curStamina = getPlayerIdleStamina(player)
	if curStamina <= 0 then
		player:sendTextMessage(MESSAGE_FAILURE, "Você não possui Stamina IDLE disponível.")
		return false
	end

	pull = (pull == "cautious" or pull == "aggressive") and pull or "bold"
	local meetsAll = evaluateHuntRequirements(player, hunt)
	local now = os.time()

	_G.OnIdleHunt[playerId] = {
		huntId = huntId,
		pull = pull,
		startTime = now,
		meetsRequirements = meetsAll,
		xpGained = 0,
		suppliesSpent = 0,
		goldEarned = 0,
		turnCount = 0,
		lastAutoSell = now,
		lastQuickSell = 0,
		spawnedMonsters = {},
		droppedCounts = {},
		event = nil,
	}

	local session = _G.OnIdleHunt[playerId]

	-- Teleportar jogador para o centro da arena instanciada da dificuldade
	if hunt.pos then
		-- Garante existência física dos tiles da arena antes do teleporte
		ensureArenaTiles(hunt.pos, 6, 104, 602)

		local targetTile = Tile(hunt.pos)
		if not targetTile or not targetTile:getGround() then
			player:sendTextMessage(MESSAGE_FAILURE, "[IDLE HUNT ERRO]: Não foi possível instanciar a arena da caçada.")
			return false
		end

		local curPos = player:getPosition()
		curPos:sendMagicEffect(CONST_ME_TELEPORT)
		local teleportOk = player:teleportTo(hunt.pos)
		if not teleportOk then
			player:sendTextMessage(MESSAGE_FAILURE, "[IDLE HUNT ERRO]: Falha ao teleportar para a arena. Caçada cancelada por segurança.")
			return false
		end

		hunt.pos:sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(
			MESSAGE_EVENT_ADVANCE,
			string.format("[IDLE HUNT]: Você entrou na arena: %s!", hunt.name)
		)
	end

	-- SEGURANÇA TOTAL: Bloqueio estrito de spawn caso o jogador não esteja na arena
	local playerPos = player:getPosition()
	if hunt.pos and (playerPos.x ~= hunt.pos.x or playerPos.y ~= hunt.pos.y or playerPos.z ~= hunt.pos.z) then
		player:sendTextMessage(MESSAGE_FAILURE, "[IDLE HUNT ERRO]: O teleporte não foi concluído. Invocação de monstros bloqueada por segurança.")
		stopIdleHunt(playerId, "Teleporte falhou.", false, false)
		return false
	end

	-- Registro de Eventos de Kill, Logout e Morte no Jogador
	player:registerEvent("IdleHuntMonsterKill")
	player:registerEvent("IdleHuntPlayerLogout")
	player:registerEvent("IdleHuntPlayerDeath")
	session.startExperience = player:getExperience()

	-- Invocação imediata da primeira onda de monstros
	spawnHuntWave(player, hunt, session)

	-- Envio do estado inicial de drops & loot
	sendLootUpdateOpcode(player, huntId)

	-- Ativar AutoLoot nativo se presente
	pcall(function()
		if Features and Features.AutoLoot then
			player:setFeature(Features.AutoLoot, 2)
		end
	end)

	player:sendTextMessage(
		MESSAGE_EVENT_ADVANCE,
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
				'{"action":"hunt_started","hunt_id":%d,"hunt_name":%s,"tier":%s,"meets_req":%s,"spawn_x":%d,"spawn_y":%d,"spawn_z":%d}',
				huntId,
				escapeJsonString(hunt.name),
				escapeJsonString(hunt.tier),
				meetsAll and "true" or "false",
				hunt.pos.x,
				hunt.pos.y,
				hunt.pos.z
			)
		)
	end

	session.event = addEvent(idleCombatLoop, 2000, playerId, huntId)
	return true
end

-- =========================================================================
-- MANIPULADOR DE OPCODE ESTENDIDO 106 (IDLE HUNT PROTOCOL)
-- =========================================================================
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
			local lootParts = {}
			if h.lootTable then
				for _, l in ipairs(h.lootTable) do
					local okLook, look = pcall(getItemLookDescription, l.id)
					if not okLook or not look then look = l.name end
					table.insert(lootParts, string.format('{"id":%d,"name":%s,"price":%d,"chance":%d,"look":%s}', l.id, escapeJsonString(l.name), l.price, l.chance, escapeJsonString(look)))
				end
			end

			local wavesParts = {}
			if h.waves then
				for _, w in ipairs(h.waves) do
					table.insert(wavesParts, string.format('{"name":%s,"count":%d}', escapeJsonString(w.name), w.count))
				end
			end

			local elemParts = {}
			if h.elements then
				for el, val in pairs(h.elements) do
					table.insert(elemParts, string.format('"%s":%d', el, val))
				end
			end

			local bestExp = math.max(0, player:getStorageValue(STORAGE_RECORD_EXP_BASE + h.id))
			local bestGp = math.max(0, player:getStorageValue(STORAGE_RECORD_GP_BASE + h.id))

			table.insert(
				huntsJsonParts,
				string.format(
					'{"id":%d,"name":%s,"tier":%s,"level":%d,"focus":%s,"desc":%s,"cost":%d,"req_lvl":%d,"req_atk":%d,"req_def":%d,"req_bank":%d,"potions":%s,"looktype":%d,"record_exp":%d,"record_gp":%d,"loot":[%s],"waves":[%s],"elements":{%s}}',
					h.id, escapeJsonString(h.name), escapeJsonString(h.tier), h.level, escapeJsonString(h.focus), escapeJsonString(h.desc), h.supplyCostPerTurn, h.reqLevel, h.reqAttack, h.reqDefense, h.reqBank, escapeJsonString(h.reqPotions), h.lookType or 0, bestExp, bestGp, table.concat(lootParts, ","), table.concat(wavesParts, ","), table.concat(elemParts, ",")
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
				'{"action":"requirements","hunt_id":%d,"hunt_name":%s,"meets_all":%s,' ..
				'"p_lvl":%d,"r_lvl":%d,"ok_lvl":%s,' ..
				'"p_atk":%d,"r_atk":%d,"ok_atk":%s,' ..
				'"p_def":%d,"r_def":%d,"ok_def":%s,' ..
				'"p_bank":%d,"r_bank":%d,"ok_bank":%s,' ..
				'"potions":%s}',
				hunt.id, escapeJsonString(hunt.name), meetsAll and "true" or "false",
				details.level.player, details.level.required, details.level.ok and "true" or "false",
				details.attack.player, details.attack.required, details.attack.ok and "true" or "false",
				details.defense.player, details.defense.required, details.defense.ok and "true" or "false",
				details.bank.player, details.bank.required, details.bank.ok and "true" or "false",
				escapeJsonString(details.potions)
			)
			player:sendExtendedOpcode(OPCODE_IDLE_HUNT, response)
		end

	-- 3. INICIAR / ENCERRAR CAÇADA
	elseif buffer:find("start_hunt") then
		local huntId = tonumber(buffer:match('"hunt_id"%s*:%s*(%d+)')) or 1
		local pull = buffer:match('"pull"%s*:%s*"(%a+)"') or "bold"
		startIdleHunt(player, huntId, pull)

	elseif buffer:find("stop_hunt") then
		stopIdleHunt(playerId, "Caçada IDLE encerrada pelo jogador.", false, false)

	-- 4. CONSULTAR DROPS E CONFIGURAÇÕES DE LOOT
	elseif buffer:find("get_hunt_loot") or buffer:find("get_loot") then
		local huntId = tonumber(buffer:match('"hunt_id"%s*:%s*(%d+)'))
		local session = _G.OnIdleHunt[playerId]
		if (not huntId or huntId == 0) and session then
			huntId = session.huntId
		end
		huntId = huntId or 1

		sendLootUpdateOpcode(player, huntId)

	-- 5. DEFINIR REGRA DE LOOT (MANTER vs VENDER) - PERSISTENTE NO BANCO DE DADOS
	-- DEFINIR REGRA DE AUTO LOOT (COLETAR vs IGNORAR) - PERSISTENTE NO BANCO
	elseif buffer:find("set_autoloot_rule") then
		local itemId = tonumber(buffer:match('"item_id"%s*:%s*(%d+)'))
		local enabled = buffer:find('"enabled"%s*:%s*true') ~= nil
		if itemId then
			setPlayerAutoLootRule(player, itemId, enabled)
			player:sendExtendedOpcode(
				OPCODE_IDLE_HUNT,
				string.format('{"action":"autoloot_rule_updated","item_id":%d,"enabled":%s}', itemId, enabled and "true" or "false")
			)
			local itType = ItemType(itemId)
			local itName = (itType and itType:getName() ~= "") and itType:getName() or "Item"
			if enabled then
				player:sendTextMessage(MESSAGE_STATUS_SMALL, string.format("[IDLE Auto-Loot]: %s sera coletado automaticamente.", itName))
			else
				player:sendTextMessage(MESSAGE_STATUS_SMALL, string.format("[IDLE Auto-Loot]: %s sera ignorado (nao entra na mochila).", itName))
			end
			local session = _G.OnIdleHunt[playerId]
			local huntId = session and session.huntId or 1
			sendLootUpdateOpcode(player, huntId)
		end

	elseif buffer:find("set_loot_rule") then
		local itemId = tonumber(buffer:match('"item_id"%s*:%s*(%d+)'))
		local rule = buffer:match('"rule"%s*:%s*"(%a+)"') or "keep"

		if itemId then
			setPlayerLootRule(player, itemId, rule)
			player:sendExtendedOpcode(
				OPCODE_IDLE_HUNT,
				string.format('{"action":"loot_rule_updated","item_id":%d,"rule":%q}', itemId, rule)
			)
			local session = _G.OnIdleHunt[playerId]
			local huntId = session and session.huntId or 1
			sendLootUpdateOpcode(player, huntId)
		end

	-- 6. BOTÃO DE VENDA RÁPIDA (QUICK SELL) - COOLDOWN 0 EM VENDA VAZIA, 5S EM SUCESSO
	elseif buffer:find("quick_sell") then
		local session = _G.OnIdleHunt[playerId]
		local huntId = session and session.huntId or 1

		local now = os.time()
		local lastQ = session and session.lastQuickSell or (player:getStorageValue(STORAGE_LAST_QUICK_SELL) > 0 and player:getStorageValue(STORAGE_LAST_QUICK_SELL) or 0)
		local elapsed = now - lastQ

		if elapsed < 120 then
			local remaining = 120 - elapsed
			local remMins = math.floor(remaining / 60)
			local remSecs = remaining % 60
			player:sendTextMessage(
				MESSAGE_FAILURE,
				string.format("Aguarde %02dm %02ds para usar o Quick Sell novamente.", remMins, remSecs)
			)
			player:sendExtendedOpcode(
				OPCODE_IDLE_HUNT,
				string.format('{"action":"quick_sell_cooldown","remaining":%d}', remaining)
			)
			return
		end

		local gold, count = sellPlayerLootFromInventory(player, huntId, "quick")

		if gold > 0 then
			if session then
				session.lastQuickSell = now
			end
			player:setStorageValue(STORAGE_LAST_QUICK_SELL, now)

			player:sendExtendedOpcode(
				OPCODE_IDLE_HUNT,
				string.format(
					'{"action":"quick_sell_result","gold":%d,"count":%d,"cooldown":120}',
					gold, count
				)
			)
		else
			-- NENHUM ITEM VENDIDO: COOLDOWN É ZERO!
			player:sendTextMessage(
				MESSAGE_FAILURE,
				"[QUICK SELL]: Nenhum item desbloqueado para venda foi encontrado na sua backpack. Marque os itens como [UNLOCKED] no menu Loot & Sell primeiro."
			)
			player:sendExtendedOpcode(
				OPCODE_IDLE_HUNT,
				'{"action":"quick_sell_result","gold":0,"count":0,"cooldown":0}'
			)
		end

		sendLootUpdateOpcode(player, huntId)

	-- 7. TELEPORTE RÁPIDO PARA A CASA (HOUSE)
	elseif buffer:find("teleport_house") then
		local house = player:getHouse()
		if not house then
			player:sendTextMessage(MESSAGE_FAILURE, "[HOUSE]: You do not own a house.")
			return
		end

		if _G.OnIdleHunt[playerId] then
			stopIdleHunt(playerId, "Teleportado para a casa pelo IDLE Hunt Menu.", false, true)
		end

		player:removeCondition(CONDITION_INFIGHT)
		player:removeCondition(CONDITION_HUNTING)

		local exitPos = house:getExitPosition()
		if exitPos then
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:teleportTo(exitPos)
			exitPos:sendMagicEffect(CONST_ME_TELEPORT)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[HOUSE]: You were successfully teleported to your house!")
		end

	-- 8. TELEPORTE RÁPIDO PARA O TEMPLO (TEMPLE)
	elseif buffer:find("teleport_temple") then
		local templePos = player:getTown():getTemplePosition()
		if not templePos then
			player:sendTextMessage(MESSAGE_FAILURE, "[TEMPLE]: Your home town temple was not found.")
			return
		end

		if _G.OnIdleHunt[playerId] then
			stopIdleHunt(playerId, "Teleportado para o templo pelo IDLE Hunt Menu.", false, true)
		end

		player:removeCondition(CONDITION_INFIGHT)
		player:removeCondition(CONDITION_HUNTING)

		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		player:teleportTo(templePos)
		templePos:sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[TEMPLE]: You were safely teleported to the Temple!")

	-- 9. SUPRIMENTO HÍBRIDO IDLE (MOCHILA OU DÉBITO DIRETO DO BANCO)
	elseif buffer:find("use_idle_supply") then
		local itemId = tonumber(buffer:match('"item_id"%s*:%s*(%d+)'))
		local cost = tonumber(buffer:match('"cost"%s*:%s*(%d+)')) or 0

		if not itemId then return end

		local DEFAULT_ITEM_COSTS = {
			[268] = 56, [237] = 108, [238] = 158, [23373] = 488, -- Mana Potions
			[7876] = 20, [266] = 50, [236] = 115, [239] = 225, [7643] = 379, [23375] = 650, -- Health Potions
			[7642] = 254, [23374] = 488 -- Spirit Potions
		}
		if cost <= 0 then
			cost = DEFAULT_ITEM_COSTS[itemId] or 50
		end

		local curHp = player:getHealth()
		local maxHp = player:getMaxHealth()
		local curMp = player:getMana()
		local maxMp = player:getMaxMana()

		local consumed = false
		local countInBag = player:getItemCount(itemId)

		local usedFromBank = false
		if countInBag > 0 then
			player:removeItem(itemId, 1)
			consumed = true
		else
			if cost > 0 then
				local bank = player:getBankBalance()
				if bank >= cost then
					Bank.debit(player, cost)
					player:setBankBalance(bank - cost)
					player:sendBankBalance()
					consumed = true
					usedFromBank = true
				else
					player:sendTextMessage(MESSAGE_FAILURE, "[SUPPLIES]: Saldo insuficiente no banco para repor suprimento!")
				end
			end
		end

		if consumed then
			local pos = player:getPosition()
			pos:sendMagicEffect(CONST_ME_MAGIC_BLUE)

			local POTION_HEAL_RANGES = {
				[266] = { hpMin = 125, hpMax = 175 },
				[236] = { hpMin = 250, hpMax = 350 },
				[239] = { hpMin = 425, hpMax = 575 },
				[7643] = { hpMin = 675, hpMax = 875 },
				[23375] = { hpMin = 875, hpMax = 1125 },
				[268] = { mpMin = 75, mpMax = 125 },
				[237] = { mpMin = 115, mpMax = 185 },
				[238] = { mpMin = 150, mpMax = 250 },
				[23373] = { mpMin = 425, mpMax = 575 },
				[7642] = { hpMin = 250, hpMax = 350, mpMin = 100, mpMax = 200 },
				[23374] = { hpMin = 425, hpMax = 575, mpMin = 150, mpMax = 250 },
			}

			local range = POTION_HEAL_RANGES[itemId]
			if range then
				if range.hpMin and range.hpMax then
					local heal = math.random(range.hpMin, range.hpMax)
					player:addHealth(heal)
				end
				if range.mpMin and range.mpMax then
					local healMp = math.random(range.mpMin, range.mpMax)
					player:addMana(healMp)
				end
			end

			player:sendExtendedOpcode(
				OPCODE_IDLE_HUNT,
				string.format('{"action":"supply_used","item_id":%d,"cost":%d,"from_bank":%s}', itemId, cost, usedFromBank and "true" or "false")
			)
		end
	end
end

idleOpcodeEvent:register()

-- Registrador de Morte de Monstros para Contabilizar Loots da Caçada
local idleMonsterKillEvent = CreatureEvent("IdleHuntMonsterKill")

function idleMonsterKillEvent.onKill(player, target)
	if not player or not target or not target:isMonster() then
		return true
	end

	local playerId = player:getId()
	local session = _G.OnIdleHunt[playerId]
	if not session then
		return true
	end

	local hunt = getHuntById(session.huntId)
	if not hunt or not hunt.lootTable then
		return true
	end

	local targetName = target:getName()
	session.droppedCounts = session.droppedCounts or {}

	for _, l in ipairs(hunt.lootTable) do
		if math.random(1, 100) <= l.chance then
			local count = math.random(l.countMin or 1, l.countMax or 1)
			if l.isMoney then
				local earned = count * l.price
				player:addMoneyBank(earned)
				player:sendBankBalance()
				session.goldEarned = (session.goldEarned or 0) + earned
			else
				local autoLoot = getPlayerAutoLootRule(player, l.id)
				if autoLoot then
					player:addItem(l.id, count)
					session.droppedCounts[l.id] = (session.droppedCounts[l.id] or 0) + count
				end
			end
		end
	end

	sendLootUpdateOpcode(player, session.huntId)

	return true
end

idleMonsterKillEvent:register()

-- Interrupção e Limpeza Imediata da Arena ao Morrer
local idleDeathEvent = CreatureEvent("IdleHuntPlayerDeath")

function idleDeathEvent.onDeath(player, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	local playerId = player:getId()
	local session = _G.OnIdleHunt[playerId]
	if session then
		stopIdleHunt(playerId, "Morte durante caçada IDLE. Arena resetada.", false, true)
	end
	return true
end

idleDeathEvent:register()

-- Desconectar com Limpeza Segura
local idleLogoutEvent = CreatureEvent("IdleHuntPlayerLogout")

function idleLogoutEvent.onLogout(player)
	local playerId = player:getId()
	if _G.OnIdleHunt[playerId] then
		stopIdleHunt(playerId, "Logout durante caçada IDLE.", false, false)
	end
	return true
end

idleLogoutEvent:register()

-- Inicialização das Arenas IDLE no Startup do Servidor
local arenaStartupEvent = GlobalEvent("IdleHuntArenaInit")

function arenaStartupEvent.onStartup()
	addEvent(function()
		ensureArenaTiles(ROOM_POS_EASY, 6, 104, 602)
		ensureArenaTiles(ROOM_POS_MEDIUM, 6, 104, 602)
		ensureArenaTiles(ROOM_POS_HARD, 6, 104, 602)
		logger.info("[IDLE HUNT ARENAS]: 3 dynamic arenas initialized at Easy (385,754,8), Medium (421,301,11), Hard (440,785,11).")
	end, 1000)
	return true
end

arenaStartupEvent:register()

print("[IDLE HUNT SYSTEM]: Loaded successfully with 3 difficulty tiers (Easy/Medium/Hard) and persistent Global Quick Sell.")