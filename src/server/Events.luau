-- Events.luau — the two threats that keep players running home.
-- Tsunami Cendol: a sweet wave sweeps the map from north to south. Anyone
-- caught outside their base is knocked back to the spawn pad.
-- Maling Brainrot: a thief NPC who walks to a random base and tries to carry
-- one brainrot away. Click him to chase him off before he grabs it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Events = {}
Events.__index = Events

-- `wave` is the big cendol-coloured part in Workspace that sweeps the map.
-- `thiefFolder` holds the thief NPC while he is out.
-- `playerData` is the PlayerData module; `banner` is the EventBanner remote.
function Events.new(wave: BasePart, thiefFolder: Folder, playerData, banner: RemoteEvent)
	local self = setmetatable({}, Events)
	self.Wave = wave
	self.ThiefFolder = thiefFolder
	self.PlayerData = playerData
	self.Banner = banner
	self.NextTsunami = os.time() + Config.TSUNAMI_INTERVAL
	self.NextThief = os.time() + Config.THIEF_INTERVAL
	self.TsunamiRunning = false
	self.Thief = nil
	return self
end

function Events.announce(self, title: string, detail: string, seconds: number)
	self.Banner:FireAllClients(title, detail, seconds)
end

-- Is this position inside any base plot? The wave spares players at home.
local function insideAnyBase(position: Vector3): boolean
	for _, plot in ipairs(Config.BASE_PLOTS) do
		if math.abs(position.X - plot.Position.X) <= 9
			and math.abs(position.Z - plot.Position.Z) <= 9 then
			return true
		end
	end
	return false
end

-- Send a player back to the spawn pad.
local function sendHome(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(Config.SPAWN_POSITION)
	end
end

-- One tsunami: warn, then sweep the wave from north (z=-70) to south (z=+70).
function Events.runTsunami(self)
	if self.TsunamiRunning then
		return
	end
	self.TsunamiRunning = true
	self:announce("TSUNAMI CENDOL!", "Gelombang cendol datang! Lari ke basemu!", Config.TSUNAMI_WARNING)
	task.wait(Config.TSUNAMI_WARNING)
	self.Wave.Transparency = 0.25
	local z = -70
	local hit = {} -- players already knocked by this wave
	while z <= 70 do
		z += Config.TSUNAMI_SPEED * 0.05
		self.Wave.CFrame = CFrame.new(0, 4, z)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and not hit[player] and not insideAnyBase(root.Position) then
				if math.abs(root.Position.Z - z) < 6 then
					hit[player] = true
					sendHome(player)
					self.Banner:FireClient(player, "Kena tsunami!", "Kamu tersapu kembali ke spawn.", 4)
				end
			end
		end
		task.wait(0.05)
	end
	self.Wave.Transparency = 1
	self.Wave.CFrame = CFrame.new(0, 4, -70)
	self.TsunamiRunning = false
	self.NextTsunami = os.time() + Config.TSUNAMI_INTERVAL
end

-- Build the thief: a shifty black-clad blocky character with a sack.
local function buildThief(): Model
	local model = Instance.new("Model")
	model.Name = "MalingBrainrot"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 4, 2)
	body.Position = Vector3.new(0, 2, 0)
	body.Color = Color3.fromRGB(40, 40, 45)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.6, 2.4, 2.4)
	head.Position = Vector3.new(0, 5, 0)
	head.Color = Color3.fromRGB(230, 200, 170)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- The mask: a black band across the eyes.
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Size = Vector3.new(2.7, 0.8, 0.4)
	mask.Position = Vector3.new(0, 5.3, 1.2)
	mask.Color = Color3.fromRGB(20, 20, 20)
	mask.Material = Enum.Material.SmoothPlastic
	mask.Anchored = true
	mask.CanCollide = false
	mask.Parent = model

	local sack = Instance.new("Part")
	sack.Name = "Sack"
	sack.Shape = Enum.PartType.Ball
	sack.Size = Vector3.new(2.4, 2.4, 2.4)
	sack.Position = Vector3.new(2.2, 2.5, 0)
	sack.Color = Color3.fromRGB(150, 110, 60)
	sack.Material = Enum.Material.Fabric
	sack.Anchored = true
	sack.CanCollide = false
	sack.Parent = model

	local click = Instance.new("ClickDetector")
	click.Name = "ThiefClick"
	click.MaxActivationDistance = 32
	click.Parent = body

	model.PrimaryPart = body
	return model
end

-- One thief visit: pick a random occupied base, walk there, wait, then grab
-- the best brainrot on it unless someone clicked him away first.
function Events.runThief(self)
	if self.Thief then
		return
	end
	local candidates = {}
	for player, state in pairs(self.PlayerData.States) do
		if state.PlotIndex > 0 and #state.Brainrots > 0 then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		self.NextThief = os.time() + Config.THIEF_INTERVAL
		return
	end
	local victim = candidates[math.random(1, #candidates)]
	local plot = Config.BASE_PLOTS[self.PlayerData.States[victim].PlotIndex]

	local thief = buildThief()
	-- The thief's pivot sits about 3 studs above his feet (body centre 2,
	-- head top 6.2), so the pivot goes at y=3 for feet on the ground.
	thief:PivotTo(CFrame.new(0, 3, -60))
	thief.Parent = self.ThiefFolder
	self.Thief = thief
	self:announce("MALING BRAINROT!", "Maling mengincar " .. victim.DisplayName .. "! Klik dia untuk mengusir!", 8)

	-- Walk to the victim's base, one step at a time, staying at pivot height.
	local target = Vector3.new(plot.Position.X, 3, plot.Position.Z - 12)
	local arrived = false
	local chasedAway = false
	thief.Body:FindFirstChild("ThiefClick").MouseClick:Connect(function(_player)
		chasedAway = true
	end)
	while not arrived and not chasedAway do
		local pivot = thief:GetPivot()
		local toTarget = target - pivot.Position
		local distance = toTarget.Magnitude
		if distance < 2 then
			arrived = true
			break
		end
		local step = toTarget.Unit * math.min(Config.THIEF_SPEED * 0.1, distance)
		thief:PivotTo(CFrame.new(pivot.Position + step))
		task.wait(0.1)
	end

	if chasedAway then
		self:announce("Maling kabur!", "Bagus! Malingnya diusir sebelum mencuri.", 4)
	elseif arrived then
		-- He needs a few seconds at the base to grab a brainrot.
		self:announce("Maling di basemu!", "Usir dia sebelum dia mengambil brainrot!", Config.THIEF_STEAL_TIME)
		local waited = 0
		while waited < Config.THIEF_STEAL_TIME and not chasedAway do
			task.wait(0.5)
			waited += 0.5
		end
		if not chasedAway then
			local state = self.PlayerData.States[victim]
			if state and #state.Brainrots > 0 and not self.PlayerData:isLocked(victim) then
				local bestIndex = 1
				local bestIncome = -1
				for i, entry in ipairs(state.Brainrots) do
					if entry.Income > bestIncome then
						bestIncome = entry.Income
						bestIndex = i
					end
				end
				local stolen = table.remove(state.Brainrots, bestIndex)
				if stolen.Model then
					stolen.Model:Destroy()
				end
				self.Banner:FireClient(victim, "Brainrot dicuri!", "Maling membawa kabur " .. stolen.Def.Name .. "!", 6)
				self.PlayerData:pushMoney(victim)
			else
				self:announce("Maling gagal!", "Base terkunci atau sudah kosong.", 4)
			end
		else
			self:announce("Maling kabur!", "Bagus! Malingnya diusir sebelum mencuri.", 4)
		end
	end

	thief:Destroy()
	self.Thief = nil
	self.NextThief = os.time() + Config.THIEF_INTERVAL
end

-- The event loop: tsunami and thief on their own timers.
function Events.start(self)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			if now >= self.NextTsunami and not self.TsunamiRunning then
				task.spawn(function()
					self:runTsunami()
				end)
			end
			if now >= self.NextThief and not self.Thief then
				task.spawn(function()
					self:runThief()
				end)
			end
		end
	end)
end

return Events
