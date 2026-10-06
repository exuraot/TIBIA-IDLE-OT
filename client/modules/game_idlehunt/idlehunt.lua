g_ui.importStyle('idlehunt_styles')

local OPCODE_IDLE_HUNT = 106

local idleButton = nil

-- Tabela Oficial Fallback de 21 Hunts (3 Dificuldades: Facil, Medio, Dificil)
local DEFAULT_HUNTS_CATALOG = {
	-- =========================================================================
	-- FACIL (EASY) - Sala: Position(385, 754, 8) - 3 Monstros por Onda
	-- =========================================================================
	{
		id = 1,
		name = "Rotworms (Facil)",
		tier = "easy",
		level = 8,
		focus = "Equilibrado",
		desc = "Sala de treino inicial com 3 Rotworms. Ideal para iniciantes.",
		monster = "Rotworm",
		looktype = 26,
		elements = { physical = 0, fire = 0, earth = 0, energy = 0, ice = 0, holy = 0, death = 0 },
		baseExp = 40,
		cost = 10,
		req_lvl = 8,
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
		loot = {
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
		name = "Amazons (Facil)",
		tier = "easy",
		level = 15,
		focus = "Mais Loot",
		desc = "3 Amazons ageis com drops frequentes de Protective Charm.",
		monster = "Amazon",
		looktype = 137,
		elements = { physical = 0, fire = 10, earth = -10, energy = 0, ice = 10, holy = 0, death = 10 },
		baseExp = 80,
		cost = 15,
		req_lvl = 15,
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
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 80, countMin = 15, countMax = 60, isMoney = true },
			{ id = 11444, name = "Protective Charm", price = 150, chance = 30, countMin = 1, countMax = 2 },
			{ id = 3277, name = "Dagger", price = 5, chance = 40, countMin = 1, countMax = 1 },
			{ id = 3360, name = "Brown Bread", price = 3, chance = 35, countMin = 1, countMax = 3 },
			{ id = 3298, name = "Skull Staff", price = 500, chance = 2, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 3,
		name = "Cyclops (Facil)",
		tier = "easy",
		level = 25,
		focus = "Mais EXP",
		desc = "3 Cyclops corpulentos com bom ganho de experiencia e Cyclops Toes.",
		monster = "Cyclops",
		looktype = 22,
		elements = { physical = 0, fire = 0, earth = 10, energy = -10, ice = 0, holy = -10, death = 20 },
		baseExp = 150,
		cost = 30,
		req_lvl = 25,
		reqAttack = 28,
		reqDefense = 22,
		reqBank = 3000,
		reqPotions = "Health / Mana Potion",
		damageMin = 18,
		damageMax = 55,
		healAmount = 60,
		waves = {
			{ name = "Cyclops", count = 3 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 20, countMax = 80, isMoney = true },
			{ id = 9657, name = "Cyclops Toe", price = 120, chance = 30, countMin = 1, countMax = 2 },
			{ id = 3269, name = "Halberd", price = 400, chance = 8, countMin = 1, countMax = 1 },
			{ id = 3577, name = "Meat", price = 2, chance = 50, countMin = 2, countMax = 5 },
			{ id = 3297, name = "Battle Axe", price = 80, chance = 15, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 4,
		name = "Minotaurs (Facil)",
		tier = "easy",
		level = 20,
		focus = "Mais Loot",
		desc = "3 Minotaurs com alto rendimento de Minotaur Leather.",
		monster = "Minotaur",
		looktype = 25,
		elements = { physical = 0, fire = 10, earth = 0, energy = 0, ice = 10, holy = 0, death = 10 },
		baseExp = 110,
		cost = 25,
		req_lvl = 20,
		reqAttack = 24,
		reqDefense = 18,
		reqBank = 2500,
		reqPotions = "Health / Mana Potion",
		damageMin = 12,
		damageMax = 35,
		healAmount = 45,
		waves = {
			{ name = "Minotaur", count = 3 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 85, countMin = 15, countMax = 70, isMoney = true },
			{ id = 11472, name = "Minotaur Leather", price = 80, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3305, name = "Mace", price = 30, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3267, name = "Chain Armor", price = 70, chance = 12, countMin = 1, countMax = 1 },
			{ id = 3374, name = "Brass Helmet", price = 30, chance = 15, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 5,
		name = "Undeads (Facil)",
		tier = "easy",
		level = 22,
		focus = "Equilibrado",
		desc = "3 Skeletons antigos para treino rapido.",
		monster = "Skeleton",
		looktype = 18,
		elements = { physical = 0, fire = 0, earth = 20, energy = 0, ice = 0, holy = -20, death = 100 },
		baseExp = 95,
		cost = 25,
		req_lvl = 22,
		reqAttack = 25,
		reqDefense = 20,
		reqBank = 3000,
		reqPotions = "Health / Mana Potion",
		damageMin = 10,
		damageMax = 32,
		healAmount = 40,
		waves = {
			{ name = "Skeleton", count = 3 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 75, countMin = 10, countMax = 50, isMoney = true },
			{ id = 11476, name = "Pelvis Bone", price = 30, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3274, name = "Bone Club", price = 20, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3412, name = "Bone Shield", price = 80, chance = 8, countMin = 1, countMax = 1 },
			{ id = 3375, name = "Viking Helmet", price = 66, chance = 10, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 6,
		name = "Dragons (Facil)",
		tier = "easy",
		level = 35,
		focus = "Mais EXP",
		desc = "3 Dragons classicos. Excelente avanco de experiencia intermediaria.",
		monster = "Dragon",
		looktype = 34,
		elements = { physical = 0, fire = 100, earth = 20, energy = -10, ice = -10, holy = 0, death = 0 },
		baseExp = 700,
		cost = 50,
		req_lvl = 35,
		reqAttack = 38,
		reqDefense = 30,
		reqBank = 5000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 35,
		damageMax = 110,
		healAmount = 120,
		waves = {
			{ name = "Dragon", count = 3 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 40, countMax = 150, isMoney = true },
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 20, countMin = 1, countMax = 2, isMoney = true },
			{ id = 9665, name = "Dragon Tail", price = 100, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3416, name = "Dragon Shield", price = 4000, chance = 3, countMin = 1, countMax = 1 },
			{ id = 3283, name = "Dragon Hammer", price = 2000, chance = 4, countMin = 1, countMax = 1 },
			{ id = 3386, name = "Dragon Slayer", price = 15000, chance = 1, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 7,
		name = "Demons (Facil)",
		tier = "easy",
		level = 60,
		focus = "Avancado",
		desc = "3 Demons ferozes. Alto risco e grandes recompensas.",
		monster = "Demon",
		looktype = 35,
		elements = { physical = 0, fire = 100, earth = 20, energy = 10, ice = -15, holy = -15, death = 20 },
		baseExp = 6000,
		cost = 100,
		req_lvl = 60,
		reqAttack = 55,
		reqDefense = 45,
		reqBank = 10000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 80,
		damageMax = 250,
		healAmount = 280,
		waves = {
			{ name = "Demon", count = 3 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 98, countMin = 80, countMax = 250, isMoney = true },
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 60, countMin = 1, countMax = 5, isMoney = true },
			{ id = 6499, name = "Demonic Essence", price = 1000, chance = 40, countMin = 1, countMax = 2 },
			{ id = 3420, name = "Demon Shield", price = 30000, chance = 2, countMin = 1, countMax = 1 },
			{ id = 3356, name = "Devil Helmet", price = 1000, chance = 10, countMin = 1, countMax = 1 },
			{ id = 3306, name = "Golden Sickle", price = 1000, chance = 8, countMin = 1, countMax = 1 },
		},
	},

	-- =========================================================================
	-- MEDIO (MEDIUM) - Sala: Position(421, 301, 11) - 4 a 5 Monstros por Onda
	-- =========================================================================
	{
		id = 8,
		name = "Rotworms (Medio)",
		tier = "medium",
		level = 20,
		focus = "Equilibrado",
		desc = "Sala intermediaria com 3 Rotworms e 2 Carrion Worms.",
		monster = "Carrion Worm",
		looktype = 194,
		elements = { physical = 0, fire = 0, earth = 0, energy = 0, ice = 0, holy = 0, death = 0 },
		baseExp = 70,
		cost = 25,
		req_lvl = 20,
		reqAttack = 25,
		reqDefense = 20,
		reqBank = 3000,
		reqPotions = "Health / Mana Potion",
		damageMin = 12,
		damageMax = 35,
		healAmount = 45,
		waves = {
			{ name = "Rotworm", count = 3 },
			{ name = "Carrion Worm", count = 2 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 25, countMax = 90, isMoney = true },
			{ id = 3492, name = "Worm", price = 1, chance = 50, countMin = 2, countMax = 8 },
			{ id = 3577, name = "Meat", price = 2, chance = 45, countMin = 2, countMax = 4 },
			{ id = 3286, name = "Mace", price = 30, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3264, name = "Sword", price = 25, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3374, name = "Legion Helmet", price = 22, chance = 15, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 9,
		name = "Amazons (Medio)",
		tier = "medium",
		level = 30,
		focus = "Mais Loot",
		desc = "3 Amazons e 2 Valkyries armadas.",
		monster = "Valkyrie",
		looktype = 139,
		elements = { physical = 0, fire = 10, earth = -10, energy = 0, ice = 10, holy = 0, death = 10 },
		baseExp = 140,
		cost = 35,
		req_lvl = 30,
		reqAttack = 32,
		reqDefense = 25,
		reqBank = 4000,
		reqPotions = "Health / Mana Potion",
		damageMin = 20,
		damageMax = 50,
		healAmount = 65,
		waves = {
			{ name = "Amazon", count = 3 },
			{ name = "Valkyrie", count = 2 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 85, countMin = 30, countMax = 100, isMoney = true },
			{ id = 11444, name = "Protective Charm", price = 150, chance = 45, countMin = 1, countMax = 3 },
			{ id = 3277, name = "Dagger", price = 5, chance = 45, countMin = 1, countMax = 2 },
			{ id = 3360, name = "Brown Bread", price = 3, chance = 40, countMin = 2, countMax = 5 },
			{ id = 3298, name = "Skull Staff", price = 500, chance = 5, countMin = 1, countMax = 1 },
			{ id = 3275, name = "Double Axe", price = 260, chance = 8, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 10,
		name = "Cyclops (Medio)",
		tier = "medium",
		level = 45,
		focus = "Mais EXP",
		desc = "3 Cyclops e 2 Cyclops Drones enfurecidos.",
		monster = "Cyclops Drone",
		looktype = 281,
		elements = { physical = 0, fire = 0, earth = 10, energy = -10, ice = 0, holy = -10, death = 20 },
		baseExp = 280,
		cost = 55,
		req_lvl = 45,
		reqAttack = 42,
		reqDefense = 34,
		reqBank = 6000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 35,
		damageMax = 95,
		healAmount = 110,
		waves = {
			{ name = "Cyclops", count = 3 },
			{ name = "Cyclops Drone", count = 2 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 40, countMax = 140, isMoney = true },
			{ id = 9657, name = "Cyclops Toe", price = 120, chance = 45, countMin = 1, countMax = 3 },
			{ id = 3269, name = "Halberd", price = 400, chance = 14, countMin = 1, countMax = 1 },
			{ id = 3577, name = "Meat", price = 2, chance = 60, countMin = 3, countMax = 8 },
			{ id = 3297, name = "Battle Axe", price = 80, chance = 22, countMin = 1, countMax = 1 },
			{ id = 3364, name = "Heavy Metal", price = 320, chance = 8, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 11,
		name = "Minotaurs (Medio)",
		tier = "medium",
		level = 35,
		focus = "Mais Loot",
		desc = "3 Minotaurs, 1 Minotaur Archer e 1 Minotaur Mage.",
		monster = "Minotaur Guard",
		looktype = 29,
		elements = { physical = 0, fire = 10, earth = 0, energy = 0, ice = 10, holy = 0, death = 10 },
		baseExp = 180,
		cost = 45,
		req_lvl = 35,
		reqAttack = 35,
		reqDefense = 28,
		reqBank = 4500,
		reqPotions = "Health / Mana Potion",
		damageMin = 22,
		damageMax = 65,
		healAmount = 75,
		waves = {
			{ name = "Minotaur", count = 3 },
			{ name = "Minotaur Archer", count = 1 },
			{ name = "Minotaur Mage", count = 1 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 30, countMax = 120, isMoney = true },
			{ id = 11472, name = "Minotaur Leather", price = 80, chance = 50, countMin = 1, countMax = 3 },
			{ id = 11474, name = "Minotaur Horn", price = 75, chance = 40, countMin = 1, countMax = 2 },
			{ id = 3305, name = "Mace", price = 30, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3267, name = "Chain Armor", price = 70, chance = 18, countMin = 1, countMax = 1 },
			{ id = 3374, name = "Brass Helmet", price = 30, chance = 20, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 12,
		name = "Undeads (Medio)",
		tier = "medium",
		level = 40,
		focus = "Equilibrado",
		desc = "3 Skeletons e 2 Ghouls famintos.",
		monster = "Ghoul",
		looktype = 18,
		elements = { physical = 0, fire = -10, earth = 30, energy = 0, ice = 0, holy = -30, death = 100 },
		baseExp = 160,
		cost = 40,
		req_lvl = 40,
		reqAttack = 36,
		reqDefense = 30,
		reqBank = 5000,
		reqPotions = "Health / Mana Potion",
		damageMin = 18,
		damageMax = 55,
		healAmount = 65,
		waves = {
			{ name = "Skeleton", count = 3 },
			{ name = "Ghoul", count = 2 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 85, countMin = 25, countMax = 95, isMoney = true },
			{ id = 11476, name = "Pelvis Bone", price = 30, chance = 35, countMin = 1, countMax = 2 },
			{ id = 11478, name = "Ghoul Snack", price = 60, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3274, name = "Bone Club", price = 20, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3412, name = "Bone Shield", price = 80, chance = 12, countMin = 1, countMax = 1 },
			{ id = 3375, name = "Viking Helmet", price = 66, chance = 16, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 13,
		name = "Dragons (Medio)",
		tier = "medium",
		level = 65,
		focus = "Mais EXP",
		desc = "3 Dragons e 2 Dragon Hatchlings barulhentos.",
		monster = "Dragon Hatchling",
		looktype = 286,
		elements = { physical = 0, fire = 100, earth = 20, energy = -10, ice = -10, holy = 0, death = 0 },
		baseExp = 1200,
		cost = 90,
		req_lvl = 65,
		reqAttack = 52,
		reqDefense = 42,
		reqBank = 9000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 50,
		damageMax = 170,
		healAmount = 190,
		waves = {
			{ name = "Dragon", count = 3 },
			{ name = "Dragon Hatchling", count = 2 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 98, countMin = 60, countMax = 220, isMoney = true },
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 35, countMin = 1, countMax = 3, isMoney = true },
			{ id = 9665, name = "Dragon Tail", price = 100, chance = 40, countMin = 1, countMax = 2 },
			{ id = 3416, name = "Dragon Shield", price = 4000, chance = 5, countMin = 1, countMax = 1 },
			{ id = 3283, name = "Dragon Hammer", price = 2000, chance = 6, countMin = 1, countMax = 1 },
			{ id = 3386, name = "Dragon Slayer", price = 15000, chance = 2, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 14,
		name = "Demons (Medio)",
		tier = "medium",
		level = 100,
		focus = "Avancado",
		desc = "3 Demons e 2 Fire Devils ardentes.",
		monster = "Fire Devil",
		looktype = 40,
		elements = { physical = 0, fire = 100, earth = 20, energy = 10, ice = -15, holy = -15, death = 20 },
		baseExp = 8500,
		cost = 170,
		req_lvl = 100,
		reqAttack = 70,
		reqDefense = 58,
		reqBank = 18000,
		reqPotions = "Ultimate Health / Mana Potion",
		damageMin = 110,
		damageMax = 340,
		healAmount = 380,
		waves = {
			{ name = "Demon", count = 3 },
			{ name = "Fire Devil", count = 2 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 99, countMin = 120, countMax = 350, isMoney = true },
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 75, countMin = 2, countMax = 8, isMoney = true },
			{ id = 6499, name = "Demonic Essence", price = 1000, chance = 55, countMin = 1, countMax = 3 },
			{ id = 3420, name = "Demon Shield", price = 30000, chance = 3, countMin = 1, countMax = 1 },
			{ id = 3356, name = "Devil Helmet", price = 1000, chance = 15, countMin = 1, countMax = 1 },
			{ id = 3306, name = "Golden Sickle", price = 1000, chance = 12, countMin = 1, countMax = 1 },
			{ id = 3281, name = "Giant Sword", price = 17000, chance = 2, countMin = 1, countMax = 1 },
		},
	},

	-- =========================================================================
	-- DIFICIL (HARD) - Sala: Position(440, 785, 11) - 6 a 7 Monstros por Onda
	-- =========================================================================
	{
		id = 15,
		name = "Rotworms (Dificil)",
		tier = "hard",
		level = 35,
		focus = "Equilibrado",
		desc = "Sala intensa com 3 Rotworms, 2 Carrion Worms e 1 Rotworm Queen.",
		monster = "Rotworm Queen",
		looktype = 340,
		elements = { physical = 0, fire = 0, earth = 0, energy = 0, ice = 0, holy = 0, death = 0 },
		baseExp = 120,
		cost = 45,
		req_lvl = 35,
		reqAttack = 35,
		reqDefense = 28,
		reqBank = 5000,
		reqPotions = "Health / Mana Potion",
		damageMin = 20,
		damageMax = 55,
		healAmount = 65,
		waves = {
			{ name = "Rotworm", count = 3 },
			{ name = "Carrion Worm", count = 2 },
			{ name = "Rotworm Queen", count = 1 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 40, countMax = 140, isMoney = true },
			{ id = 3492, name = "Worm", price = 1, chance = 60, countMin = 3, countMax = 12 },
			{ id = 3577, name = "Meat", price = 2, chance = 55, countMin = 3, countMax = 6 },
			{ id = 3286, name = "Mace", price = 30, chance = 30, countMin = 1, countMax = 1 },
			{ id = 3264, name = "Sword", price = 25, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3374, name = "Legion Helmet", price = 22, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3413, name = "Battle Shield", price = 95, chance = 10, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 16,
		name = "Amazons (Dificil)",
		tier = "hard",
		level = 50,
		focus = "Mais Loot",
		desc = "3 Amazons, 2 Valkyries e 1 Witch conjuradora de fogo.",
		monster = "Witch",
		looktype = 54,
		elements = { physical = 0, fire = 20, earth = -10, energy = 0, ice = 10, holy = 0, death = 10 },
		baseExp = 260,
		cost = 65,
		req_lvl = 50,
		reqAttack = 46,
		reqDefense = 36,
		reqBank = 7500,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 35,
		damageMax = 90,
		healAmount = 105,
		waves = {
			{ name = "Amazon", count = 3 },
			{ name = "Valkyrie", count = 2 },
			{ name = "Witch", count = 1 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 50, countMax = 160, isMoney = true },
			{ id = 11444, name = "Protective Charm", price = 150, chance = 60, countMin = 2, countMax = 4 },
			{ id = 3277, name = "Dagger", price = 5, chance = 50, countMin = 1, countMax = 3 },
			{ id = 3360, name = "Brown Bread", price = 3, chance = 45, countMin = 3, countMax = 6 },
			{ id = 3298, name = "Skull Staff", price = 500, chance = 8, countMin = 1, countMax = 1 },
			{ id = 3275, name = "Double Axe", price = 260, chance = 15, countMin = 1, countMax = 1 },
			{ id = 3302, name = "Silver Brooch", price = 150, chance = 12, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 17,
		name = "Cyclops (Dificil)",
		tier = "hard",
		level = 70,
		focus = "Mais EXP",
		desc = "3 Cyclops, 2 Drones e 1 Cyclops Smith mestre da forja.",
		monster = "Cyclops Smith",
		looktype = 282,
		elements = { physical = 0, fire = 0, earth = 10, energy = -10, ice = 0, holy = -10, death = 20 },
		baseExp = 550,
		cost = 95,
		req_lvl = 70,
		reqAttack = 56,
		reqDefense = 45,
		reqBank = 11000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 55,
		damageMax = 145,
		healAmount = 165,
		waves = {
			{ name = "Cyclops", count = 3 },
			{ name = "Cyclops Drone", count = 2 },
			{ name = "Cyclops Smith", count = 1 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 98, countMin = 70, countMax = 220, isMoney = true },
			{ id = 9657, name = "Cyclops Toe", price = 120, chance = 60, countMin = 2, countMax = 4 },
			{ id = 3269, name = "Halberd", price = 400, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3577, name = "Meat", price = 2, chance = 70, countMin = 4, countMax = 10 },
			{ id = 3297, name = "Battle Axe", price = 80, chance = 30, countMin = 1, countMax = 1 },
			{ id = 3364, name = "Heavy Metal", price = 320, chance = 15, countMin = 1, countMax = 1 },
			{ id = 3369, name = "Warrior Helmet", price = 5000, chance = 2, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 18,
		name = "Minotaurs (Dificil)",
		tier = "hard",
		level = 55,
		focus = "Mais Loot",
		desc = "3 Minotaurs, 2 Archers, 1 Mage e 1 Minotaur Guard.",
		monster = "Minotaur Guard",
		looktype = 29,
		elements = { physical = 0, fire = 10, earth = 0, energy = 0, ice = 10, holy = 0, death = 10 },
		baseExp = 320,
		cost = 75,
		req_lvl = 55,
		reqAttack = 48,
		reqDefense = 38,
		reqBank = 8500,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 35,
		damageMax = 95,
		healAmount = 110,
		waves = {
			{ name = "Minotaur", count = 3 },
			{ name = "Minotaur Archer", count = 2 },
			{ name = "Minotaur Mage", count = 1 },
			{ name = "Minotaur Guard", count = 1 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 95, countMin = 50, countMax = 180, isMoney = true },
			{ id = 11472, name = "Minotaur Leather", price = 80, chance = 65, countMin = 2, countMax = 4 },
			{ id = 11474, name = "Minotaur Horn", price = 75, chance = 55, countMin = 1, countMax = 3 },
			{ id = 3305, name = "Mace", price = 30, chance = 30, countMin = 1, countMax = 1 },
			{ id = 3267, name = "Chain Armor", price = 70, chance = 24, countMin = 1, countMax = 1 },
			{ id = 3374, name = "Brass Helmet", price = 30, chance = 25, countMin = 1, countMax = 1 },
			{ id = 3275, name = "Double Axe", price = 260, chance = 12, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 19,
		name = "Undeads (Dificil)",
		tier = "hard",
		level = 60,
		focus = "Equilibrado",
		desc = "3 Skeletons, 2 Ghouls e 1 Crypt Shambler petrificante.",
		monster = "Crypt Shambler",
		looktype = 100,
		elements = { physical = 0, fire = -20, earth = 40, energy = 0, ice = 0, holy = -40, death = 100 },
		baseExp = 340,
		cost = 70,
		req_lvl = 60,
		reqAttack = 50,
		reqDefense = 40,
		reqBank = 9000,
		reqPotions = "Strong Health / Mana Potion",
		damageMin = 30,
		damageMax = 88,
		healAmount = 100,
		waves = {
			{ name = "Skeleton", count = 3 },
			{ name = "Ghoul", count = 2 },
			{ name = "Crypt Shambler", count = 1 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 90, countMin = 40, countMax = 150, isMoney = true },
			{ id = 11476, name = "Pelvis Bone", price = 30, chance = 45, countMin = 1, countMax = 3 },
			{ id = 11478, name = "Ghoul Snack", price = 60, chance = 35, countMin = 1, countMax = 2 },
			{ id = 3274, name = "Bone Club", price = 20, chance = 30, countMin = 1, countMax = 1 },
			{ id = 3412, name = "Bone Shield", price = 80, chance = 18, countMin = 1, countMax = 1 },
			{ id = 3375, name = "Viking Helmet", price = 66, chance = 22, countMin = 1, countMax = 1 },
			{ id = 3367, name = "Two Handed Sword", price = 450, chance = 8, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 20,
		name = "Dragons (Dificil)",
		tier = "hard",
		level = 90,
		focus = "Mais EXP",
		desc = "3 Dragons, 2 Hatchlings e 1 Dragon Lord soberano.",
		monster = "Dragon Lord",
		looktype = 39,
		elements = { physical = 0, fire = 100, earth = 20, energy = -10, ice = -15, holy = 0, death = 0 },
		baseExp = 2500,
		cost = 150,
		req_lvl = 90,
		reqAttack = 66,
		reqDefense = 54,
		reqBank = 15000,
		reqPotions = "Great Health / Mana Potion",
		damageMin = 85,
		damageMax = 270,
		healAmount = 300,
		waves = {
			{ name = "Dragon", count = 3 },
			{ name = "Dragon Hatchling", count = 2 },
			{ name = "Dragon Lord", count = 1 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 99, countMin = 90, countMax = 300, isMoney = true },
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 50, countMin = 1, countMax = 5, isMoney = true },
			{ id = 9665, name = "Dragon Tail", price = 100, chance = 55, countMin = 1, countMax = 3 },
			{ id = 3416, name = "Dragon Shield", price = 4000, chance = 8, countMin = 1, countMax = 1 },
			{ id = 3283, name = "Dragon Hammer", price = 2000, chance = 10, countMin = 1, countMax = 1 },
			{ id = 3386, name = "Dragon Slayer", price = 15000, chance = 4, countMin = 1, countMax = 1 },
			{ id = 3428, name = "Tower Shield", price = 8000, chance = 3, countMin = 1, countMax = 1 },
			{ id = 3392, name = "Royal Helmet", price = 30000, chance = 1, countMin = 1, countMax = 1 },
		},
	},
	{
		id = 21,
		name = "Demons (Dificil)",
		tier = "hard",
		level = 150,
		focus = "Avancado",
		desc = "3 Demons, 2 Fire Devils e 1 Demon Lord infernal.",
		monster = "Demon",
		looktype = 35,
		elements = { physical = 0, fire = 100, earth = 20, energy = 10, ice = -15, holy = -15, death = 20 },
		baseExp = 15000,
		cost = 250,
		req_lvl = 150,
		reqAttack = 85,
		reqDefense = 72,
		reqBank = 30000,
		reqPotions = "Ultimate Health / Mana Potion",
		damageMin = 160,
		damageMax = 480,
		healAmount = 520,
		waves = {
			{ name = "Demon", count = 3 },
			{ name = "Fire Devil", count = 2 },
			{ name = "Demon", count = 1 }
		},
		loot = {
			{ id = 3031, name = "Gold Coin", price = 1, chance = 100, countMin = 150, countMax = 450, isMoney = true },
			{ id = 3035, name = "Platinum Coin", price = 100, chance = 85, countMin = 3, countMax = 12, isMoney = true },
			{ id = 6499, name = "Demonic Essence", price = 1000, chance = 70, countMin = 2, countMax = 5 },
			{ id = 3420, name = "Demon Shield", price = 30000, chance = 5, countMin = 1, countMax = 1 },
			{ id = 3356, name = "Devil Helmet", price = 1000, chance = 20, countMin = 1, countMax = 1 },
			{ id = 3306, name = "Golden Sickle", price = 1000, chance = 15, countMin = 1, countMax = 1 },
			{ id = 3281, name = "Giant Sword", price = 17000, chance = 4, countMin = 1, countMax = 1 },
			{ id = 3414, name = "Mastermind Shield", price = 50000, chance = 2, countMin = 1, countMax = 1 },
		},
	},
}

-- As 7 Masmorras Base do Catalogo
local DUNGEON_THEMES = {
	{
		id = 1,
		name = "Rotworms",
		desc = "Cavernas umidas com vermes e carniceiros. Otimo para avancar niveis iniciais.",
		level = 8,
		focus = "[Equilibrado]",
		looktype = 26,
		easyId = 1,
		mediumId = 8,
		hardId = 15
	},
	{
		id = 2,
		name = "Amazons",
		desc = "Guerreiras selvagens no acampamento da floresta. Ricas em Protective Charms.",
		level = 15,
		focus = "[Mais Loot]",
		looktype = 137,
		easyId = 2,
		mediumId = 9,
		hardId = 16
	},
	{
		id = 3,
		name = "Cyclops",
		desc = "Gigantes corpulentos com alto ganho de experiencia e Cyclops Toes.",
		level = 25,
		focus = "[Mais EXP]",
		looktype = 22,
		easyId = 3,
		mediumId = 10,
		hardId = 17
	},
	{
		id = 4,
		name = "Minotaurs",
		desc = "Labirintos de minotauros arqueiros e magos. Alto rendimento de Minotaur Leather.",
		level = 20,
		focus = "[Mais Loot]",
		looktype = 25,
		easyId = 4,
		mediumId = 11,
		hardId = 18
	},
	{
		id = 5,
		name = "Undeads",
		desc = "Catacumbas repletas de esqueletos e ghouls para treino de combate rapido.",
		level = 22,
		focus = "[Equilibrado]",
		looktype = 18,
		easyId = 5,
		mediumId = 12,
		hardId = 19
	},
	{
		id = 6,
		name = "Dragons",
		desc = "Dragoes e filhotes cuspidas de fogo. Excelente evolucao de nivel intermediario.",
		level = 35,
		focus = "[Mais EXP]",
		looktype = 34,
		easyId = 6,
		mediumId = 13,
		hardId = 20
	},
	{
		id = 7,
		name = "Demons",
		desc = "Covis infernais para cacadores de alto nivel. Ganhos massivos de experiencia e joias.",
		level = 60,
		focus = "[Avancado]",
		looktype = 35,
		easyId = 7,
		mediumId = 14,
		hardId = 21
	}
}

local function formatNumber(n)
	local left, num, right = string.match(tostring(n), "^([^%d]*%d)(%d*)(.-)$")
	if not left then return tostring(n) end
	return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

local function trimString(s)
	if not s then return "" end
	return s:match("^%s*(.-)%s*$") or ""
end

local function getThemeByHuntId(huntId)
	for _, t in ipairs(DUNGEON_THEMES) do
		if t.easyId == huntId or t.mediumId == huntId or t.hardId == huntId then
			local tier = (t.easyId == huntId) and "easy" or ((t.mediumId == huntId) and "medium" or "hard")
			return t, tier
		end
	end
	return DUNGEON_THEMES[1], "easy"
end

-- Cache e Estado
local currentView = "dashboard"
local huntsCache = {}
local inHunt = false
local currentHuntId = 0
local selectedHuntId = 1
local activeDifficulty = "easy" -- "easy", "medium", "hard"
local selectedPull = "bold"
local quickSellCooldownTimer = 0
local quickSellEvent = nil
local autoCombatEvent = nil
local targetLockCreature = nil

local itemRulesCache = {}

local function setItemLootRule(itemId, rule)
	itemRulesCache[itemId] = rule
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"set_loot_rule","item_id":%d,"rule":%q}', itemId, rule))
	end
end

-- =========================================================================
-- CONTROLLER PRINCIPAL
-- =========================================================================
idleHuntController = Controller:new()

function idleHuntController:init()
	self:onInit()
end

function idleHuntController:terminate()
	self:onTerminate()
end

function idleHuntController:onInit()
	ProtocolGame.registerExtendedOpcode(OPCODE_IDLE_HUNT, function(protocol, opcode, buffer)
		self:onOpcodeReceived(protocol, opcode, buffer)
	end)

	connect(g_game, {
		onGameStart = function() self:onGameStart() end,
		onGameEnd = function() self:onGameEnd() end
	})

	self.ui = g_ui.displayUI('idlehunt')
	if self.ui then
		self.ui:hide()
		self:setupTopMenuButton()
		self:setupDashboardUI()
		self:setupCatalogUI()
		self:setupDetailsUI()
	end

	if g_game.isOnline() then
		self:onGameStart()
	end
end

function idleHuntController:onTerminate()
	ProtocolGame.unregisterExtendedOpcode(OPCODE_IDLE_HUNT)
	disconnect(g_game, {
		onGameStart = function() self:onGameStart() end,
		onGameEnd = function() self:onGameEnd() end
	})

	if autoCombatEvent then
		removeEvent(autoCombatEvent)
		autoCombatEvent = nil
	end
	if quickSellEvent then
		removeEvent(quickSellEvent)
		quickSellEvent = nil
	end

	if self.ui then
		self.ui:destroy()
		self.ui = nil
	end
end

function idleHuntController:setupTopMenuButton()
	if modules.client_topmenu and not idleButton then
		idleButton = modules.client_topmenu.addLeftGameButton(
			'idleHuntButton',
			tr('Sistema de Cacadas IDLE'),
			'/images/topbuttons/minimap',
			function() self:toggle() end
		)
	end
end

function idleHuntController:onGameStart()
	self:requestHunts()
end

function idleHuntController:onGameEnd()
	inHunt = false
	currentHuntId = 0
	targetLockCreature = nil
	self:stopAutoCombat()
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
-- GERENCIADOR DE TELAS
-- =========================================================================
function idleHuntController:switchView(viewName, param, paramTier)
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
		self:showDetails(param or selectedHuntId, paramTier or activeDifficulty)
	end
end

-- =========================================================================
-- 1. SETUP TELA 1: DASHBOARD
-- =========================================================================
function idleHuntController:setupDashboardUI()
	local dView = self.ui.dashboardView
	if not dView then return end

	local openCatBtn = dView.idleModeCard and dView.idleModeCard.openCatalogButton
	if openCatBtn then
		openCatBtn.onClick = function()
			self:switchView("catalog")
		end
	end

	local stopBtn = dView.huntingCard and dView.huntingCard.emergencyStopButton
	if stopBtn then
		stopBtn.onClick = function()
			self:stopHunt()
		end
	end

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
	local huntCard = dView.huntingCard

	if inHunt then
		if idleCard then idleCard:setVisible(false) end
		if huntCard then
			huntCard:setVisible(true)
			local hunt = self:getHuntById(currentHuntId)
			if hunt and huntCard.huntingHeader and huntCard.huntingHeader.activeMonsterFrame and huntCard.huntingHeader.activeMonsterFrame.activeMonsterCreature then
				if hunt.looktype and hunt.looktype > 0 then
					huntCard.huntingHeader.activeMonsterFrame.activeMonsterCreature:setOutfit({ type = hunt.looktype })
					local cr = huntCard.huntingHeader.activeMonsterFrame.activeMonsterCreature:getCreature()
					if cr then cr:setStaticWalking(1000) end
				end
				huntCard.huntingHeader.activeHuntName:setText(string.format("Cacando: %s", hunt.name))
			end
		end
	else
		if idleCard then idleCard:setVisible(true) end
		if huntCard then huntCard:setVisible(false) end
	end

	if dView.idleModeCard and dView.idleModeCard.dashboardTipBox and dView.idleModeCard.dashboardTipBox.tipText then
		dView.idleModeCard.dashboardTipBox.tipText:setText(tr("Use o botao Quick Sell para converter seus drops em saldo bancario. Ao encerrar a cacada, o restante sera vendido automaticamente."))
	end
end

-- =========================================================================
-- 2. SETUP TELA 2: CATALOGO (7 MASMORRAS BASE)
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

	if topBar and topBar.huntSearchInput then
		topBar.huntSearchInput.onTextChange = function()
			self:filterHunts()
		end
	end

	if cView.catalogTipBox and cView.catalogTipBox.tipText then
		cView.catalogTipBox.tipText:setText(tr("Selecione uma masmorra e clique em [Configurar] para ajustar a dificuldade (Facil, Medio, Dificil) e itens de loot."))
	end
end

function idleHuntController:filterHunts()
	local cView = self.ui and self.ui.catalogView
	if not cView or not cView.huntList then return end
	local huntList = cView.huntList
	huntList:destroyChildren()

	local searchText = ""
	if cView.catalogTopBar and cView.catalogTopBar.huntSearchInput then
		local rawSearch = cView.catalogTopBar.huntSearchInput:getText() or ""
		searchText = string.lower(trimString(rawSearch))
	end

	for _, theme in ipairs(DUNGEON_THEMES) do
		local nameMatch = true
		if searchText ~= "" then
			local n = string.lower(theme.name)
			local d = string.lower(theme.desc)
			nameMatch = (string.find(n, searchText, 1, true) ~= nil or string.find(d, searchText, 1, true) ~= nil)
		end

		if nameMatch then
			local card = g_ui.createWidget("HuntCard", huntList)
			if card then
				if card.monsterFrame and card.monsterFrame.monsterCreature then
					if theme.looktype and theme.looktype > 0 then
						card.monsterFrame.monsterCreature:setOutfit({ type = theme.looktype })
						local cr = card.monsterFrame.monsterCreature:getCreature()
						if cr then cr:setStaticWalking(1000) end
					end
				end

				card.huntTitle:setText(theme.name)
				card.focusTag:setText(theme.focus)
				card.huntDesc:setText(theme.desc)
				card.huntCost:setText(string.format("Nivel Minimo: %d", theme.level))

				-- Melhor recorde da masmorra
				local hEasy = self:getHuntById(theme.easyId)
				local hMed = self:getHuntById(theme.mediumId)
				local hHard = self:getHuntById(theme.hardId)
				local bestExp = math.max(hEasy and hEasy.record_exp or 0, hMed and hMed.record_exp or 0, hHard and hHard.record_exp or 0)

				if bestExp > 0 then
					card.recordLabel:setText(string.format("Recorde: %s XP/h (10m)", formatNumber(bestExp)))
					card.recordLabel:setColor("#00ddff")
				else
					card.recordLabel:setText("Recorde: Sem registro ainda (10m)")
					card.recordLabel:setColor("#777777")
				end

				card.configButton.onClick = function()
					self:showDetails(theme.id, "easy")
				end
			end
		end
	end
end

-- =========================================================================
-- 3. SETUP TELA 3: CONFIGURAR CACADA (2 COLUNAS: DIFICULDADE + LOOT COM CHECKBOX)
-- =========================================================================
function idleHuntController:setupDetailsUI()
	local dtView = self.ui.detailsView
	if not dtView then return end

	if dtView.detailsTopBar and dtView.detailsTopBar.backToCatalogBtn then
		dtView.detailsTopBar.backToCatalogBtn.onClick = function()
			self:switchView("catalog")
		end
	end

	if dtView.detailsTipBox and dtView.detailsTipBox.tipText then
		dtView.detailsTipBox.tipText:setText(tr("Selecione [PEGAR] para guardar na mochila ou [VENDER] para enviar o ouro direto ao banco."))
	end
end

function idleHuntController:showDetails(themeOrHuntId, tier)
	local theme = nil
	local currentTier = tier or activeDifficulty or "easy"

	if type(themeOrHuntId) == "number" and themeOrHuntId <= 7 then
		theme = DUNGEON_THEMES[themeOrHuntId] or DUNGEON_THEMES[1]
	else
		local detectedTier = "easy"
		theme, detectedTier = getThemeByHuntId(themeOrHuntId)
		if not tier then currentTier = detectedTier end
	end

	activeDifficulty = currentTier

	-- Mapear dificuldade para o ID da hunt correta
	local targetHuntId = theme.easyId
	if currentTier == "medium" then
		targetHuntId = theme.mediumId
	elseif currentTier == "hard" then
		targetHuntId = theme.hardId
	end

	selectedHuntId = targetHuntId
	local hunt = self:getHuntById(targetHuntId)
	if not hunt then return end

	local dtView = self.ui and self.ui.detailsView
	if not dtView then return end

	self:switchView("details")

	-- Header
	if dtView.detailsTopBar and dtView.detailsTopBar.detailsTitle then
		dtView.detailsTopBar.detailsTitle:setText(string.format("Configurar Cacada: %s", theme.name))
	end

	if dtView.detailsTopBar and dtView.detailsTopBar.detailRecordLabel then
		if (hunt.record_exp or 0) > 0 then
			dtView.detailsTopBar.detailRecordLabel:setText(string.format("Recorde: %s XP/h | %s GP/h", formatNumber(hunt.record_exp), formatNumber(hunt.record_gp or 0)))
			dtView.detailsTopBar.detailRecordLabel:setColor("#00ddff")
		else
			dtView.detailsTopBar.detailRecordLabel:setText("Recorde: Sem registro ainda (10m)")
			dtView.detailsTopBar.detailRecordLabel:setColor("#777777")
		end
	end

	local header = dtView.detailCreatureHeader
	if header then
		if header.detailCreatureFrame and header.detailCreatureFrame.detailCreature then
			if theme.looktype and theme.looktype > 0 then
				header.detailCreatureFrame.detailCreature:setOutfit({ type = theme.looktype })
				local cr = header.detailCreatureFrame.detailCreature:getCreature()
				if cr then cr:setStaticWalking(1000) end
			end
		end
		header.detailHuntName:setText(string.format("%s (%s)", theme.name, currentTier == "easy" and "Facil" or (currentTier == "medium" and "Medio" or "Dificil")))
		header.detailFocusTag:setText(theme.focus)
		header.detailHuntDesc:setText(hunt.desc or theme.desc)
	end

	-- Painel Esquerdo: Dificuldade (3 Botoes)
	local leftPanel = dtView.leftConfigPanel
	if leftPanel and leftPanel.diffButtonsRow then
		local bEasy = leftPanel.diffButtonsRow.diffEasyBtn
		local bMed = leftPanel.diffButtonsRow.diffMediumBtn
		local bHard = leftPanel.diffButtonsRow.diffHardBtn

		bEasy:setColor(currentTier == "easy" and "#00ff88" or "#888888")
		bMed:setColor(currentTier == "medium" and "#ffd700" or "#888888")
		bHard:setColor(currentTier == "hard" and "#ff5555" or "#888888")

		bEasy.onClick = function() self:showDetails(theme.id, "easy") end
		bMed.onClick = function() self:showDetails(theme.id, "medium") end
		bHard.onClick = function() self:showDetails(theme.id, "hard") end
	end

	-- Painel Esquerdo: Criaturas da Onda e Custos
	if leftPanel and leftPanel.wavesBox then
		local waveSummary = {}
		if hunt.waves then
			for _, w in ipairs(hunt.waves) do
				table.insert(waveSummary, string.format("%dx %s", w.count, w.name))
			end
		end
		local summaryText = #waveSummary > 0 and table.concat(waveSummary, " + ") or hunt.monster or "Criaturas"
		leftPanel.wavesBox.wavesSummaryLabel:setText(string.format("Onda: %s", summaryText))
		leftPanel.wavesBox.suppliesLabel:setText(string.format("Suprimentos: ~%d gp / turno", tonumber(hunt.cost) or 10))
	end

	-- Painel Esquerdo: Fraquezas e Resistencias Elementais (7 Elementos - Sem Mojibake)
	local elemGrid = leftPanel and leftPanel.elementsGrid
	if elemGrid then
		elemGrid:destroyChildren()
		local ELEM_DEFS = {
			{ key = "physical", name = "Fisico",  color = "#cccccc" },
			{ key = "fire",     name = "Fogo",    color = "#ff5533" },
			{ key = "ice",      name = "Gelo",    color = "#66ccff" },
			{ key = "earth",    name = "Terra",   color = "#88cc44" },
			{ key = "energy",   name = "Energia", color = "#cc88ff" },
			{ key = "holy",     name = "Sagrado", color = "#ffee66" },
			{ key = "death",    name = "Morte",   color = "#cc44ff" },
		}

		for _, el in ipairs(ELEM_DEFS) do
			local val = (hunt.elements and hunt.elements[el.key]) or 0
			local badge = g_ui.createWidget("ElementBadge", elemGrid)
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

	-- Painel Direito: Loot Possivel com Checkboxes (SEM MOEDAS!)
	local rightPanel = dtView.rightLootPanel
	local dropsList = rightPanel and rightPanel.detailDropsList
	if dropsList then
		dropsList:destroyChildren()
		local hasDrops = false

		if hunt.loot and #hunt.loot > 0 then
			for _, item in ipairs(hunt.loot) do
				-- Omitir todas as moedas (cai direto no banco)
				local isCoin = (item.id == 3031 or item.id == 3035 or item.id == 3043 or (item.name and item.name:lower():find("coin")))
				if not isCoin then
					hasDrops = true
					local row = g_ui.createWidget("DropRowCheckItem", dropsList)
					if row then
						row.itemWidget:setItemId(item.id)
						row.itemNameLabel:setText(item.name or "Item")
						row.itemInfoLabel:setText(string.format("Valor: %s gp | Chance: %d%%", formatNumber(item.price or 0), item.chance or 0))

						local tip = item.look or (item.name or "Item")
						tip = tip .. string.format("\n------------------------\nChance de Drop: %d%%\nPreco de Venda: %s gp", item.chance or 0, formatNumber(item.price or 0))
						row:setTooltip(tip)
						row.itemWidget:setTooltip(tip)

						local currentRule = itemRulesCache[item.id] or "keep"
						row.keepCheckBox:setChecked(currentRule == "keep")
						row.sellCheckBox:setChecked(currentRule == "sell")

						local updating = false
						row.keepCheckBox.onCheckChange = function(w, checked)
							if updating then return end
							updating = true
							row.sellCheckBox:setChecked(not checked)
							local newRule = checked and "keep" or "sell"
							itemRulesCache[item.id] = newRule
							self:setLootRule(item.id, newRule)
							updating = false
						end

						row.sellCheckBox.onCheckChange = function(w, checked)
							if updating then return end
							updating = true
							row.keepCheckBox:setChecked(not checked)
							local newRule = checked and "sell" or "keep"
							itemRulesCache[item.id] = newRule
							self:setLootRule(item.id, newRule)
							updating = false
						end
					end
				end
			end
		end

		if not hasDrops then
			local empty = g_ui.createWidget("Label", dropsList)
			empty:setText("Apenas moedas de ouro caem nesta hunt.")
			empty:setColor("#777777")
		end
	end

	-- Requisitos
	self:requestRequirements(hunt.id)

	-- Botao Iniciar Cacada
	if dtView.startHuntButton then
		dtView.startHuntButton.onClick = function()
			self:startHunt(hunt.id, "bold")
		end
	end
end

function idleHuntController:getHuntById(huntId)
	for _, h in ipairs(huntsCache or {}) do
		if h.id == huntId then return h end
	end
	for _, h in ipairs(DEFAULT_HUNTS_CATALOG) do
		if h.id == huntId then return h end
	end
	return DEFAULT_HUNTS_CATALOG[1]
end

-- =========================================================================
-- COMUNICACAO COM O SERVIDOR (OPCODES)
-- =========================================================================
function idleHuntController:requestHunts()
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"get_hunts"}')
	end
end

function idleHuntController:requestRequirements(huntId)
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"get_requirements","hunt_id":%d}', huntId))
	end
end

function idleHuntController:startHunt(huntId, pull)
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, string.format('{"action":"start_hunt","hunt_id":%d,"pull":%q}', huntId, pull or "bold"))
	end
end

function idleHuntController:stopHunt()
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"stop_hunt"}')
	end
end

function idleHuntController:teleportHouse()
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"teleport_house"}')
	end
end

function idleHuntController:teleportTemple()
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"teleport_temple"}')
	end
end

function idleHuntController:quickSell()
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(OPCODE_IDLE_HUNT, '{"action":"quick_sell"}')
	end
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
		modules.game_textmessage.displayStatusMessage(string.format("Cacada IDLE iniciada: %s!", data.hunt_name or ""))

		self:switchView("dashboard")
		self:startAutoCombat()

	elseif action == "hunt_ended" then
		inHunt = false
		currentHuntId = 0
		targetLockCreature = nil
		self:stopAutoCombat()
		modules.game_textmessage.displayStatusMessage(data.reason or "Cacada IDLE finalizada.")

		self:switchView("dashboard")

	elseif action == "hunt_status" then
		local dView = self.ui and self.ui.dashboardView
		local hCard = dView and dView.huntingCard
		if hCard and hCard.metricsGrid then
			local mg = hCard.metricsGrid
			if mg.xpSessionLabel then mg.xpSessionLabel:setText(string.format("EXP Sessao: +%s", formatNumber(data.xp_session or 0))) end
			if mg.goldEarnedLabel then mg.goldEarnedLabel:setText(string.format("Lucro Estimado: %s gp", formatNumber(data.pending_gold or 0))) end
			if mg.suppliesSpentLabel then mg.suppliesSpentLabel:setText(string.format("Suprimentos: %s gp", formatNumber(data.supplies_spent or 0))) end

			local rExp = data.rate_exp or 0
			if mg.xpRateLabel then mg.xpRateLabel:setText(string.format("Taxa: %s XP/h", formatNumber(rExp))) end

			local elSec = data.elapsed or 0
			local elMins = math.floor(elSec / 60)
			local elRest = elSec % 60
			if hCard.huntingHeader and hCard.huntingHeader.durationLabel then
				hCard.huntingHeader.durationLabel:setText(string.format("Tempo: %02dm %02ds", elMins, elRest))
			end
			if hCard.huntingHeader and hCard.huntingHeader.hpLabel then
				hCard.huntingHeader.hpLabel:setText(string.format("HP Jogador: %d%%", data.hp_percent or 100))
			end
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
				rPanel.reqSummaryLabel:setText("Requisitos de Sobrevivencia: [REQUISITOS ATENDIDOS - Resgate 10% HP Ativo]")
				rPanel.reqSummaryLabel:setColor("#00ff88")
			else
				rPanel.reqSummaryLabel:setText("Requisitos de Sobrevivencia: [ABAIXO DO RECOMENDADO - Risco de Morte]")
				rPanel.reqSummaryLabel:setColor("#ff5555")
			end

			local lvlStr = string.format("Level: %d/%d [%s]", data.p_lvl or 0, data.r_lvl or 0, data.ok_lvl and "OK" or "FALTA")
			local atkStr = string.format("Atk: %d/%d [%s]", data.p_atk or 0, data.r_atk or 0, data.ok_atk and "OK" or "FALTA")
			local defStr = string.format("Def: %d/%d [%s]", data.p_def or 0, data.r_def or 0, data.ok_def and "OK" or "FALTA")
			local bankStr = string.format("Banco: %s/%s [%s]", formatNumber(data.p_bank or 0), formatNumber(data.r_bank or 0), data.ok_bank and "OK" or "FALTA")

			rPanel.reqDetailsLabel:setText(string.format("%s | %s | %s | %s", lvlStr, atkStr, defStr, bankStr))
		end

	elseif action == "quick_sell_result" then
		if (data.gold or 0) > 0 then
			local msg = string.format("Quick Sell concluido! Vendido(s) %d item(ns) por %s gold (creditado no banco).", data.count or 0, formatNumber(data.gold or 0))
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
	if not bBar or not bBar.quickSellButton then return end

	local btn = bBar.quickSellButton
	if quickSellCooldownTimer <= 0 then
		btn:setEnabled(true)
		btn:setText("Quick Sell")
		btn:setColor("#00ff88")
		return
	end

	btn:setEnabled(false)
	btn:setText(string.format("Quick Sell (%ds)", quickSellCooldownTimer))
	btn:setColor("#888888")

	quickSellEvent = scheduleEvent(function()
		quickSellCooldownTimer = quickSellCooldownTimer - 1
		if quickSellCooldownTimer > 0 then
			btn:setText(string.format("Quick Sell (%ds)", quickSellCooldownTimer))
			self:startQuickSellCooldown(quickSellCooldownTimer)
		else
			btn:setEnabled(true)
			btn:setText("Quick Sell")
			btn:setColor("#00ff88")
		end
	end, 1000)
end

-- =========================================================================
-- ENGINE DE AUTO-COMBATE COM AVALIACAO PRECISA DE CONDICOES IDLE
-- =========================================================================
local function isHotkeyConditionMet(hk, hpPercent, mpPercent, inCombat)
	if not hk then return false end
	if hk.combatOnly and not inCombat then
		return false
	end

	local res = hk.resource or "HP"
	local op = hk.operator or "<="
	local targetVal = tonumber(hk.percent) or 80

	if res == "Combat" or res == "In Combat" then
		return inCombat
	elseif res == "Always" then
		return true
	elseif res == "HP" then
		if op == "<=" then
			return hpPercent <= targetVal
		elseif op == ">=" then
			return hpPercent >= targetVal
		elseif op == "<" then
			return hpPercent < targetVal
		elseif op == ">" then
			return hpPercent > targetVal
		elseif op == "=" or op == "==" then
			return hpPercent == targetVal
		end
	elseif res == "MP" then
		if op == "<=" then
			return mpPercent <= targetVal
		elseif op == ">=" then
			return mpPercent >= targetVal
		elseif op == "<" then
			return mpPercent < targetVal
		elseif op == ">" then
			return mpPercent > targetVal
		elseif op == "=" or op == "==" then
			return mpPercent == targetVal
		end
	end
	return false
end

function idleHuntController:startAutoCombat()
	if autoCombatEvent then
		removeEvent(autoCombatEvent)
		autoCombatEvent = nil
	end

	local lastPotionTime = 0
	local lastHealTime = 0
	local lastAttackSpellTime = 0

	local function combatLoop()
		if not inHunt then
			return
		end

		local player = g_game.getLocalPlayer()
		if not player then
			autoCombatEvent = scheduleEvent(combatLoop, 400)
			return
		end

		local pPos = player:getPosition()
		local maxHp = player:getMaxHealth() or 1
		local curHp = player:getHealth() or 1
		local hpPercent = math.floor((curHp / maxHp) * 100)

		local maxMp = player:getMaxMana() or 1
		local curMp = player:getMana() or 1
		local mpPercent = math.floor((curMp / maxMp) * 100)

		-- Alvo / Target Lock
		local currentTarget = g_game.getAttackingCreature()
		local inCombat = (currentTarget ~= nil and not currentTarget:isDead())

		if not inCombat then
			local spectators = g_map.getSpectators(pPos, false)
			local nearestMonster = nil
			local minDist = 999

			for _, spec in ipairs(spectators) do
				if spec:isMonster() and not spec:isDead() then
					local dist = getDistanceBetween(pPos, spec:getPosition())
					if dist < minDist then
						minDist = dist
						nearestMonster = spec
					end
				end
			end

			if nearestMonster and not nearestMonster:isDead() then
				g_game.attack(nearestMonster)
				currentTarget = nearestMonster
				inCombat = true
			end
		end

		-- Leitura das Hotkeys IDLE configuradas
		local idleHotkeys = nil
		if modules.game_actionbar and modules.game_actionbar.getIdleHotkeys then
			idleHotkeys = modules.game_actionbar.getIdleHotkeys()
		end

		local now = g_clock.millis()

		if idleHotkeys and #idleHotkeys > 0 then
			-- Trilha 1: Pocoes / Suprimentos (a cada 1000ms)
			if (now - lastPotionTime) >= 1000 then
				for _, hk in ipairs(idleHotkeys) do
					if hk.type == "object" and hk.itemId and hk.itemId > 0 then
						if isHotkeyConditionMet(hk, hpPercent, mpPercent, inCombat) then
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

			-- Trilha 2: Magias de Cura (a cada 1000ms)
			if (now - lastHealTime) >= 1000 then
				for _, hk in ipairs(idleHotkeys) do
					if hk.type == "spell" and hk.words and hk.words ~= "" then
						local wLower = string.lower(hk.words)
						local isHeal = string.find(wLower, "cura") or string.find(wLower, "exura") or string.find(wLower, "heal") or string.find(wLower, "vita") or not hk.offensive
						if isHeal and isHotkeyConditionMet(hk, hpPercent, mpPercent, inCombat) then
							lastHealTime = now
							g_game.talk(hk.words)
							break
						end
					end
				end
			end

			-- Trilha 3: Magias Ofensivas (a cada 2000ms, em combate)
			if (now - lastAttackSpellTime) >= 2000 and inCombat then
				for _, hk in ipairs(idleHotkeys) do
					if hk.type == "spell" and hk.words and hk.words ~= "" then
						local wLower = string.lower(hk.words)
						local isHeal = string.find(wLower, "cura") or string.find(wLower, "exura") or string.find(wLower, "heal") or string.find(wLower, "vita") or not hk.offensive
						if not isHeal and isHotkeyConditionMet(hk, hpPercent, mpPercent, inCombat) then
							lastAttackSpellTime = now
							g_game.talk(hk.words)
							break
						end
					end
				end
			end
		end

		-- Movimentacao em direcao ao monstro mais proximo se necessario
		if currentTarget and not currentTarget:isDead() then
			local mPos = currentTarget:getPosition()
			local dist = getDistanceBetween(pPos, mPos)
			if dist > 1 and dist < 8 then
				local path = g_map.findPath(pPos, mPos, 10, 0)
				if path and #path > 0 then
					local dir = path[1]
					g_game.walk(dir)
				end
			end
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
	if g_game.isAttacking() then
		g_game.cancelAttack()
	end
end