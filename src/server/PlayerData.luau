-- PlayerData.luau — one player's money, base, rebirths and lock, in one place.
-- The server owns this state; the client only ever sees it through the
-- MoneyChanged remote. Income ticks once a second from every brainrot that
-- stands on the player's base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local PlayerData = {}
PlayerData.__index = PlayerData

-- `remotes` is the Remotes folder (MoneyChanged lives there).
-- `onIncome` is called with (player, amount) on every payout, for the HUD.
function PlayerData.new(remotes: Folder, onIncome)
	local self = setmetatable({}, PlayerData)
	self.Remotes = remotes
	self.OnIncome = onIncome
	self.States = {} -- [Player] = state
	self.BaseOwners = {} -- [plotIndex] = Player
	return self
end

function PlayerData.newState(plotIndex: number)
	return {
		Money = Config.START_MONEY,
		Rebirths = 0,
		PlotIndex = plotIndex,
		Brainrots = {}, -- { Model, Def, Mutation, Income, Slot }
		LockUntil = 0,
		LastStealAttempt = 0,
		TotalEarned = 0,
	}
end

-- Give the joining player the first free base plot.
function PlayerData.addPlayer(self, player: Player)
	for i, _plot in ipairs(Config.BASE_PLOTS) do
		if self.BaseOwners[i] == nil then
			self.BaseOwners[i] = player
			self.States[player] = self.newState(i)
			self:pushMoney(player)
			return i
		end
	end
	-- All eight plots taken: the player watches until one frees up.
	self.States[player] = self.newState(0)
	self:pushMoney(player)
	return 0
end

function PlayerData.removePlayer(self, player: Player)
	local state = self.States[player]
	if state and state.PlotIndex > 0 then
		self.BaseOwners[state.PlotIndex] = nil
	end
	if state then
		for _, entry in ipairs(state.Brainrots) do
			if entry.Model then
				entry.Model:Destroy()
			end
		end
	end
	self.States[player] = nil
end

function PlayerData.get(self, player: Player)
	return self.States[player]
end

function PlayerData.getMoney(self, player: Player): number
	local state = self.States[player]
	return state and state.Money or 0
end

function PlayerData.addMoney(self, player: Player, amount: number)
	local state = self.States[player]
	if not state then
		return
	end
	state.Money += amount
	state.TotalEarned += math.max(amount, 0)
	self:pushMoney(player)
end

function PlayerData.takeMoney(self, player: Player, amount: number): boolean
	local state = self.States[player]
	if not state or state.Money < amount then
		return false
	end
	state.Money -= amount
	self:pushMoney(player)
	return true
end

-- Tell the client its new balance (and income per second) in one event.
function PlayerData.pushMoney(self, player: Player)
	local state = self.States[player]
	if not state then
		return
	end
	local remote = self.Remotes:FindFirstChild("MoneyChanged")
	if remote then
		remote:FireClient(player, state.Money, self:incomePerSecond(player), state.Rebirths)
	end
end

-- Free base slots left for this player.
function PlayerData.freeSlots(self, player: Player): number
	local state = self.States[player]
	if not state then
		return 0
	end
	return Config.BASE_SLOTS - #state.Brainrots
end

function PlayerData.incomePerSecond(self, player: Player): number
	local state = self.States[player]
	if not state then
		return 0
	end
	local total = 0
	for _, entry in ipairs(state.Brainrots) do
		total += entry.Income
	end
	return total * self:rebirthMultiplier(player)
end

-- Each rebirth adds +50% income, forever.
function PlayerData.rebirthMultiplier(self, player: Player): number
	local state = self.States[player]
	if not state then
		return 1
	end
	return 1 + state.Rebirths * Config.REBIRTH_MULTIPLIER
end

-- Place a bought brainrot on the next free slot of the player's base pad.
-- Returns the slot index, or 0 when the base is full.
function PlayerData.placeOnBase(self, player: Player, entry): number
	local state = self.States[player]
	if not state or state.PlotIndex == 0 then
		return 0
	end
	if #state.Brainrots >= Config.BASE_SLOTS then
		return 0
	end
	local plot = Config.BASE_PLOTS[state.PlotIndex]
	local slot = #state.Brainrots + 1
	-- Slots fan out in two rows of five across the 18x18 pad.
	local col = (slot - 1) % 5
	local row = math.floor((slot - 1) / 5)
	local x = plot.Position.X - 6 + col * 3
	local z = plot.Position.Z - 3 + row * 6
	-- The pad's top is 0.5 above its centre, so the feet go there.
	BrainrotFactory.place(entry.Model, Vector3.new(x, plot.Position.Y + 0.5, z))
	entry.Model.Parent = workspace:FindFirstChild("Bases")
	entry.Slot = slot
	table.insert(state.Brainrots, entry)
	self:pushMoney(player)
	return slot
end

-- Rebirth: pay the cost, lose the money and the brainrots, gain +50% income.
-- Returns (true) or (false, reason).
function PlayerData.tryRebirth(self, player: Player)
	local state = self.States[player]
	if not state then
		return false, "Kamu belum punya data."
	end
	local cost = Config.REBIRTH_BASE_COST * (state.Rebirths + 1)
	if state.Money < cost then
		return false, "Butuh $" .. Brainrots.formatMoney(cost) .. " untuk rebirth."
	end
	if #state.Brainrots < Config.REBIRTH_MIN_BRAINROTS then
		return false, "Rebirth butuh minimal " .. tostring(Config.REBIRTH_MIN_BRAINROTS) .. " brainrot di base."
	end
	for _, entry in ipairs(state.Brainrots) do
		if entry.Model then
			entry.Model:Destroy()
		end
	end
	state.Brainrots = {}
	state.Money = Config.START_MONEY
	state.Rebirths += 1
	self:pushMoney(player)
	return true
end

-- Lock the base: while locked, nobody can steal from it.
function PlayerData.lockBase(self, player: Player)
	local state = self.States[player]
	if not state then
		return
	end
	state.LockUntil = os.time() + Config.BASE_LOCK_SECONDS
end

function PlayerData.isLocked(self, player: Player): boolean
	local state = self.States[player]
	return state ~= nil and os.time() < state.LockUntil
end

-- Pay every player's income once a second. Called from the server loop.
function PlayerData.tickIncome(self)
	for player, _state in pairs(self.States) do
		local income = self:incomePerSecond(player)
		if income > 0 then
			self:addMoney(player, income)
			if self.OnIncome then
				self.OnIncome(player, income)
			end
		end
	end
end

-- Which player owns the brainrot model standing on a base, if any.
-- The click handler uses this to work out whose base is being stolen from.
function PlayerData.findOwnerOfModel(self, model: Model): Player?
	for player, state in pairs(self.States) do
		for _, entry in ipairs(state.Brainrots) do
			if entry.Model == model then
				return player
			end
		end
	end
	return nil
end

-- Steal one brainrot from `victim`'s base to `thief`'s base.
-- Returns (true, entry) or (false, reason).
function PlayerData.stealFrom(self, thief: Player, victim: Player)
	local thiefState = self.States[thief]
	local victimState = self.States[victim]
	if not thiefState or not victimState then
		return false, "Pemain tidak ditemukan."
	end
	if thief == victim then
		return false, "Itu basemu sendiri!"
	end
	if self:isLocked(victim) then
		return false, "Base itu terkunci! Coba lagi nanti."
	end
	if os.time() - thiefState.LastStealAttempt < Config.STEAL_COOLDOWN then
		return false, "Tunggu dulu sebelum mencuri lagi."
	end
	if #victimState.Brainrots == 0 then
		return false, "Base itu kosong, tidak ada yang bisa dicuri."
	end
	if #thiefState.Brainrots >= Config.BASE_SLOTS then
		return false, "Basemu penuh, tidak ada tempat untuk curian."
	end
	thiefState.LastStealAttempt = os.time()
	-- The rarest brainrot on the victim's base is the prize.
	local bestIndex = 1
	local bestIncome = -1
	for i, entry in ipairs(victimState.Brainrots) do
		if entry.Income > bestIncome then
			bestIncome = entry.Income
			bestIndex = i
		end
	end
	local stolen = table.remove(victimState.Brainrots, bestIndex)
	-- Renumber the victim's remaining slots.
	for i, entry in ipairs(victimState.Brainrots) do
		entry.Slot = i
	end
	self:placeOnBase(thief, stolen)
	self:pushMoney(victim)
	return true, stolen
end

return PlayerData
