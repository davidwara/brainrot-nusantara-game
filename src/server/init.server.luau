-- init.server.luau — Brainrot Nusantara's server entry point.
-- Wires the conveyor, the player data, the events and the remotes together:
--   * a brainrot walks the conveyor every few seconds
--   * clicking one buys it onto your base (if you can afford it)
--   * every brainrot on your base pays its income every second
--   * clicking another player's brainrot tries to steal it (unless locked)
--   * rebirth trades your money and brainrots for +50% income, forever
--   * Tsunami Cendol and Maling Brainrot keep everyone running home

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Events = require(script.Parent:WaitForChild("Events"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyBrainrot = Remotes:WaitForChild("BuyBrainrot") :: RemoteFunction
local StealBrainrot = Remotes:WaitForChild("StealBrainrot") :: RemoteFunction
local Rebirth = Remotes:WaitForChild("Rebirth") :: RemoteFunction
local LockBase = Remotes:WaitForChild("LockBase") :: RemoteEvent
local EventBanner = Remotes:WaitForChild("EventBanner") :: RemoteEvent
local MoneyChanged = Remotes:WaitForChild("MoneyChanged") :: RemoteEvent

local conveyorFolder = workspace:WaitForChild("ConveyorBrainrots")
local basesFolder = workspace:WaitForChild("Bases")
local thiefFolder = workspace:WaitForChild("ThiefFolder")
local wave = workspace:WaitForChild("TsunamiWave")

-- The player data owns money and bases; income payouts also refresh the HUD.
local data = PlayerData.new(Remotes, function(_player, _amount) end)

-- When a brainrot is bought, put it on the buyer's base.
-- `conveyor` is forward-declared so doBuy can use it before it is built.
local conveyor
local function doBuy(player: Player, model: Model)
	local ok, reason = conveyor:tryBuy(
		player,
		model,
		function(p) return data:getMoney(p) end,
		function(p, amount) data:takeMoney(p, amount) end,
		function(p) return data:freeSlots(p) > 0 end
	)
	if ok then
		EventBanner:FireClient(player, "Brainrot dibeli!", "Brainrot barumu sudah di base.", 3)
	end
	return ok, reason
end

conveyor = Conveyor.new(conveyorFolder, function(player, entry)
	local slot = data:placeOnBase(player, entry)
	if slot == 0 then
		-- Base full after all: refund and drop the brainrot back.
		data:addMoney(player, entry.Def.Cost)
		entry.Model:Destroy()
		local state = data:get(player)
		MoneyChanged:FireClient(player, data:getMoney(player), data:incomePerSecond(player), state and state.Rebirths or 0)
	end
end)

-- The two threats, on their timers.
local events = Events.new(wave, thiefFolder, data, EventBanner)
events:start()
conveyor:start()

-- Income ticks once a second.
task.spawn(function()
	while true do
		task.wait(Config.INCOME_TICK)
		data:tickIncome()
	end
end)

-- Bobbing: every brainrot on a base gently bobs up and down.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, state in pairs(data.States) do
		for i, entry in ipairs(state.Brainrots) do
			if entry.Model then
				BrainrotFactory.bob(entry.Model, now, i * 1.3)
			end
		end
	end
end)

-- Buy: the client sends the brainrot model it clicked on the conveyor.
BuyBrainrot.OnServerInvoke = function(player: Player, model: Model)
	return doBuy(player, model)
end

-- Clicks: every brainrot carries a ClickDetector, so a click in the 3D
-- world is the buy and steal button. A click on the conveyor buys; a click
-- on a brainrot standing on someone else's base tries to steal it.
workspace.DescendantAdded:Connect(function(descendant)
	if not descendant:IsA("ClickDetector") or descendant.Name ~= "BrainrotClick" then
		return
	end
	descendant.MouseClick:Connect(function(player: Player)
		local body = descendant.Parent
		local model = body and body.Parent
		if not model or not model:IsA("Model") then
			return
		end
		if model.Parent == conveyorFolder then
			doBuy(player, model)
		elseif model.Parent == basesFolder then
			local victim = data:findOwnerOfModel(model)
			if victim and victim ~= player then
				local ok, result = data:stealFrom(player, victim)
				if ok then
					EventBanner:FireClient(player, "Berhasil mencuri!", "Kamu mencuri " .. result.Def.Name .. "!", 4)
					EventBanner:FireClient(victim, "Brainrot dicuri!", player.DisplayName .. " mencuri " .. result.Def.Name .. "!", 5)
				else
					EventBanner:FireClient(player, "Gagal mencuri!", tostring(result), 3)
				end
			elseif victim == player then
				EventBanner:FireClient(player, "Itu brainrotmu!", "Brainrot ini sudah di basemu.", 3)
			end
		end
	end)
end)

-- Steal: the client sends the victim player whose brainrot it clicked.
StealBrainrot.OnServerInvoke = function(player: Player, victim: Player)
	if typeof(victim) ~= "Instance" or not victim:IsA("Player") then
		return false, "Pemain tidak valid."
	end
	-- The thief must be standing near the victim's base to grab.
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local victimState = data:get(victim)
	if root and victimState and victimState.PlotIndex > 0 then
		local plot = Config.BASE_PLOTS[victimState.PlotIndex]
		if (root.Position - plot.Position).Magnitude > Config.STEAL_RANGE + 12 then
			return false, "Terlalu jauh dari base itu! Dekati dulu."
		end
	end
	local ok, result = data:stealFrom(player, victim)
	if ok then
		EventBanner:FireClient(player, "Berhasil mencuri!", "Kamu mencuri " .. result.Def.Name .. "!", 4)
		EventBanner:FireClient(victim, "Brainrot dicuri!", player.DisplayName .. " mencuri " .. result.Def.Name .. "!", 5)
		return true, "Mencuri " .. result.Def.Name
	end
	return false, result
end

-- Rebirth: trade everything for +50% income.
Rebirth.OnServerInvoke = function(player: Player)
	local ok, reason = data:tryRebirth(player)
	if ok then
		EventBanner:FireClient(player, "REBIRTH!", "Pendapatanmu naik +50% selamanya!", 5)
	end
	return ok, reason
end

-- Lock: the client asks to lock its base for a minute.
LockBase.OnServerEvent:Connect(function(player: Player)
	data:lockBase(player)
	EventBanner:FireClient(player, "Base terkunci!", "Tidak ada yang bisa mencuri selama 60 detik.", 3)
end)

-- Players join: give them a base plot and a spawn point on the plaza.
Players.PlayerAdded:Connect(function(player)
	local plotIndex = data:addPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local root = character:WaitForChild("HumanoidRootPart")
		root.CFrame = CFrame.new(Config.SPAWN_POSITION)
		if plotIndex > 0 then
			EventBanner:FireClient(player, "Selamat datang di Brainrot Nusantara!", "Basemu: " .. Config.BASE_PLOTS[plotIndex].Name .. ". Beli brainrot di conveyor!", 6)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	data:removePlayer(player)
end)

-- Players already in the game when this script starts (Studio play solo).
for _, player in ipairs(Players:GetPlayers()) do
	data:addPlayer(player)
end

print("[Brainrot Nusantara] Server siap — 18 brainrot, 8 base, conveyor jalan.")
