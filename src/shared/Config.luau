-- Config.luau — every tuning number of Brainrot Nusantara in one place.
-- The server and the client both read this, so a balance change is one edit.

local Config = {}

-- What a new player starts with.
Config.START_MONEY = 250

-- How many brainrots one base holds before it is full.
Config.BASE_SLOTS = 10

-- The conveyor: where brainrots spawn, how fast they walk, where they vanish.
Config.CONVEYOR_START = Vector3.new(-52, 3, -35)
Config.CONVEYOR_END = Vector3.new(52, 3, -35)
Config.CONVEYOR_SPEED = 6 -- studs per second
Config.SPAWN_INTERVAL = 4 -- seconds between spawns
Config.MAX_ON_CONVEYOR = 12

-- Money: how often the server pays out each brainrot's income.
Config.INCOME_TICK = 1 -- seconds

-- Stealing: how long a base stays locked after its owner locks it, and the
-- cooldown between two steal attempts on the same brainrot.
Config.BASE_LOCK_SECONDS = 60
Config.STEAL_COOLDOWN = 30
Config.STEAL_RANGE = 12 -- studs: the thief must stand this close to grab

-- Rebirth: each rebirth wipes money and brainrots but multiplies all income.
-- Cost grows with the rebirth count; the multiplier is +50% per rebirth.
Config.REBIRTH_BASE_COST = 100000
Config.REBIRTH_MULTIPLIER = 0.5
-- A rebirth needs at least this many brainrots standing on the base, so a
-- player cannot rebirth on an empty base for free progress.
Config.REBIRTH_MIN_BRAINROTS = 3

-- Tsunami Cendol: a sweet wave sweeps the map on a timer. Anyone caught
-- outside their base is knocked back to the spawn pad and drops the brainrot
-- they are carrying. The wave itself is a part the server moves.
Config.TSUNAMI_INTERVAL = 150 -- seconds between waves
Config.TSUNAMI_WARNING = 10 -- seconds of warning before the wave hits
Config.TSUNAMI_SPEED = 25 -- studs per second across the map

-- Maling Brainrot: the thief NPC. He spawns on a timer, walks to a random
-- base and tries to carry one brainrot away. Click him to chase him off, or
-- lock your base before he arrives.
Config.THIEF_INTERVAL = 120 -- seconds between thief visits
Config.THIEF_SPEED = 10
Config.THIEF_STEAL_TIME = 5 -- seconds he needs standing at a base to grab

-- The eight base plots around the plaza, in order. Each pad is 18x18 studs;
-- the server matches a player to a plot when they join.
Config.BASE_PLOTS = {
	{ Name = "Base 1", Position = Vector3.new(-45, 1, 25), Color = Color3.fromRGB(255, 90, 90) },
	{ Name = "Base 2", Position = Vector3.new(-15, 1, 25), Color = Color3.fromRGB(90, 160, 255) },
	{ Name = "Base 3", Position = Vector3.new(15, 1, 25), Color = Color3.fromRGB(90, 220, 120) },
	{ Name = "Base 4", Position = Vector3.new(45, 1, 25), Color = Color3.fromRGB(255, 200, 60) },
	{ Name = "Base 5", Position = Vector3.new(-45, 1, 52), Color = Color3.fromRGB(200, 90, 255) },
	{ Name = "Base 6", Position = Vector3.new(-15, 1, 52), Color = Color3.fromRGB(90, 230, 230) },
	{ Name = "Base 7", Position = Vector3.new(15, 1, 52), Color = Color3.fromRGB(255, 140, 90) },
	{ Name = "Base 8", Position = Vector3.new(45, 1, 52), Color = Color3.fromRGB(160, 220, 90) },
}

-- Where players spawn when they join (the plaza, facing the conveyor).
Config.SPAWN_POSITION = Vector3.new(0, 3, 5)

-- The volcano at the map's north edge. While it smokes, Lava mutations can
-- roll; it is scenery the rest of the time.
Config.VOLCANO_POSITION = Vector3.new(0, 0, -70)

return Config
