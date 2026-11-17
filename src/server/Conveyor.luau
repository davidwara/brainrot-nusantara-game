-- Conveyor.luau — the belt that brings the brainrots to the players.
-- Brainrots spawn at the west end, walk east along the belt and vanish at
-- the east end if nobody buys them. Buying is a RemoteFunction the server
-- answers: it checks the money, takes the brainrot off the belt and puts it
-- on the buyer's base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

-- The belt's top surface: brainrots stand on it with their feet here.
local BELT_TOP_Y = 2.5

local Conveyor = {}
Conveyor.__index = Conveyor

-- `folder` is a Folder in Workspace that holds the walking brainrots.
-- `onBought` is called with (player, entry) after a successful buy.
function Conveyor.new(folder: Folder, onBought)
	local self = setmetatable({}, Conveyor)
	self.Folder = folder
	self.OnBought = onBought
	self.Entries = {} -- { Model, Def, Mutation, Income, Bought }
	self.NextSpawn = 0
	self.Running = false
	return self
end

-- Pick a random character of a rolled rarity, then roll its mutation.
function Conveyor.rollBrainrot()
	local rarity = Brainrots.rollRarity()
	local pool = Brainrots.getByRarity(rarity)
	local def = pool[math.random(1, #pool)]
	local mutation = Brainrots.rollMutation()
	return def, mutation
end

function Conveyor.spawnOne(self)
	if #self.Entries >= Config.MAX_ON_CONVEYOR then
		return
	end
	local def, mutation = self.rollBrainrot()
	local model = BrainrotFactory.build(def, mutation)
	BrainrotFactory.place(model, Vector3.new(Config.CONVEYOR_START.X, BELT_TOP_Y, Config.CONVEYOR_START.Z))
	model.Parent = self.Folder
	table.insert(self.Entries, {
		Model = model,
		Def = def,
		Mutation = mutation,
		Income = def.Income * mutation.Multiplier,
		Bought = false,
	})
end

-- Walk every brainrot one step; despawn the ones that reach the east end.
function Conveyor.step(self, dt: number)
	for i = #self.Entries, 1, -1 do
		local entry = self.Entries[i]
		if entry.Bought then
			table.remove(self.Entries, i)
		else
			local pivot = entry.Model:GetPivot()
			local nextX = pivot.Position.X + Config.CONVEYOR_SPEED * dt
			if nextX >= Config.CONVEYOR_END.X then
				entry.Model:Destroy()
				table.remove(self.Entries, i)
			else
				BrainrotFactory.place(entry.Model, Vector3.new(nextX, BELT_TOP_Y, Config.CONVEYOR_START.Z))
			end
		end
	end
end

-- The buy: find the brainrot by its model, check the player can afford it
-- and has a free base slot, then hand it over.
-- Returns (true) or (false, reason).
function Conveyor.tryBuy(self, player: Player, model: Model, getMoney, takeMoney, freeSlot)
	for _, entry in ipairs(self.Entries) do
		if entry.Model == model and not entry.Bought then
			if getMoney(player) < entry.Def.Cost then
				return false, "Uangmu belum cukup! Butuh $" .. Brainrots.formatMoney(entry.Def.Cost)
			end
			if not freeSlot(player) then
				return false, "Basemu penuh! Rebirth untuk slot tambahan."
			end
			takeMoney(player, entry.Def.Cost)
			entry.Bought = true
			entry.Model.Parent = nil -- the base claims it next
			self.OnBought(player, entry)
			return true
		end
	end
	return false, "Brainrot itu sudah dibeli atau sudah lewat."
end

function Conveyor.start(self)
	self.Running = true
	local last = os.clock()
	RunService.Heartbeat:Connect(function()
		if not self.Running then
			return
		end
		local now = os.clock()
		local dt = now - last
		last = now
		if now >= self.NextSpawn then
			self.NextSpawn = now + Config.SPAWN_INTERVAL
			self:spawnOne()
		end
		self:step(dt)
	end)
end

return Conveyor
