-- Game.client.luau — the HUD over Brainrot Nusantara's 3D world.
-- The 3D world itself is the game: the player walks around the island with
-- the default Roblox character and camera, clicks brainrots on the conveyor
-- to buy them (the server answers the click), and watches them earn money
-- on their base. This script only draws the interface on top of it:
-- money and income at the top, the brainrot index on the left, base and
-- rebirth controls on the right, and the event banner in the middle.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Rebirth = Remotes:WaitForChild("Rebirth") :: RemoteFunction
local LockBase = Remotes:WaitForChild("LockBase") :: RemoteEvent
local EventBanner = Remotes:WaitForChild("EventBanner") :: RemoteEvent
local MoneyChanged = Remotes:WaitForChild("MoneyChanged") :: RemoteEvent

local money = Config.START_MONEY
local incomePerSecond = 0
local rebirths = 0

-- Small helper: one rounded label, since the HUD is built from many.
local function label(parent, name, text, size, position, textSize, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = textSize
	l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	l.Font = Enum.Font.SourceSansBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function button(parent, name, text, size, position, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = color
	b.Text = text
	b.TextSize = 18
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.SourceSansBold
	b.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b
	b.Parent = parent
	return b
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- Top bar: money, income, rebirths. Kept clear of the top-left corner,
-- where Roblox's own menu buttons sit.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 8)
topBar.Size = UDim2.fromOffset(520, 56)
topBar.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
topBar.BackgroundTransparency = 0.25
topBar.BorderSizePixel = 0
topBar.Parent = gui

local moneyLabel = label(topBar, "Money", "$250", UDim2.fromOffset(240, 32), UDim2.fromOffset(16, 4), 28, Color3.fromRGB(120, 255, 130))
local incomeLabel = label(topBar, "Income", "+$0/s", UDim2.fromOffset(240, 20), UDim2.fromOffset(16, 34), 18, Color3.fromRGB(200, 230, 255))
local rebirthLabel = label(topBar, "Rebirths", "Rebirth x0", UDim2.fromOffset(120, 24), UDim2.fromOffset(380, 16), 18, Color3.fromRGB(255, 215, 90))

local function refreshTopBar()
	moneyLabel.Text = "$" .. Brainrots.formatMoney(money)
	incomeLabel.Text = "+$" .. Brainrots.formatMoney(incomePerSecond) .. "/s"
	rebirthLabel.Text = "Rebirth x" .. tostring(rebirths)
end

-- Left panel: the brainrot index — all 18 characters, cheapest first, with
-- their rarity colour, cost and income. Affordable rows glow green.
local indexPanel = Instance.new("ScrollingFrame")
indexPanel.Name = "BrainrotIndex"
indexPanel.Position = UDim2.new(0, 12, 0, 80)
indexPanel.Size = UDim2.fromOffset(270, 420)
indexPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
indexPanel.BackgroundTransparency = 0.25
indexPanel.BorderSizePixel = 0
indexPanel.ScrollBarThickness = 6
indexPanel.CanvasSize = UDim2.new(0, 0, 0, #Brainrots.CAST * 34 + 40)
indexPanel.Parent = gui

label(indexPanel, "Title", "BRAINROT INDEX", UDim2.fromOffset(250, 28), UDim2.fromOffset(10, 4), 20, Color3.fromRGB(255, 215, 90))

local indexRows = {}
for i, def in ipairs(Brainrots.CAST) do
	local y = 36 + (i - 1) * 34
	local row = Instance.new("Frame")
	row.Name = def.Id
	row.Position = UDim2.fromOffset(6, y)
	row.Size = UDim2.fromOffset(252, 30)
	row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	row.BackgroundTransparency = 0.9
	row.BorderSizePixel = 0
	row.Parent = indexPanel
	label(row, "Name", def.Name, UDim2.fromOffset(150, 16), UDim2.fromOffset(6, 2), 15, Brainrots.RARITY_COLORS[def.Rarity])
	label(row, "Cost", "$" .. Brainrots.formatMoney(def.Cost), UDim2.fromOffset(90, 16), UDim2.fromOffset(160, 2), 15, Color3.fromRGB(120, 255, 130))
	label(row, "Detail", def.Rarity .. "  •  $" .. Brainrots.formatMoney(def.Income) .. "/s", UDim2.fromOffset(240, 12), UDim2.fromOffset(6, 17), 12, Color3.fromRGB(200, 200, 200))
	table.insert(indexRows, { Row = row, Def = def })
end

local function refreshIndex()
	for _, entry in ipairs(indexRows) do
		entry.Row.BackgroundColor3 = if money >= entry.Def.Cost
			then Color3.fromRGB(90, 220, 120)
			else Color3.fromRGB(255, 255, 255)
	end
end

-- Right panel: base controls — lock the base, and rebirth.
local sidePanel = Instance.new("Frame")
sidePanel.Name = "BasePanel"
sidePanel.AnchorPoint = Vector2.new(1, 0)
sidePanel.Position = UDim2.new(1, -12, 0, 80)
sidePanel.Size = UDim2.fromOffset(220, 190)
sidePanel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
sidePanel.BackgroundTransparency = 0.25
sidePanel.BorderSizePixel = 0
sidePanel.Parent = gui

label(sidePanel, "Title", "BASEKU", UDim2.fromOffset(200, 28), UDim2.fromOffset(10, 6), 20, Color3.fromRGB(255, 215, 90))
label(sidePanel, "Tip", "10 slot • Rebirth = +50% income", UDim2.fromOffset(200, 20), UDim2.fromOffset(10, 38), 16, Color3.fromRGB(200, 230, 255))

local lockButton = button(sidePanel, "LockBase", "🔒 Kunci Base (60 dtk)", UDim2.fromOffset(200, 36), UDim2.fromOffset(10, 66), Color3.fromRGB(70, 120, 220))
lockButton.MouseButton1Click:Connect(function()
	LockBase:FireServer()
	lockButton.Text = "🔒 Terkunci!"
	task.delay(60, function()
		lockButton.Text = "🔒 Kunci Base (60 dtk)"
	end)
end)

local rebirthCost = Config.REBIRTH_BASE_COST * (rebirths + 1)
local rebirthButton = button(sidePanel, "Rebirth", "⟳ Rebirth ($" .. Brainrots.formatMoney(rebirthCost) .. ")", UDim2.fromOffset(200, 36), UDim2.fromOffset(10, 112), Color3.fromRGB(200, 90, 220))
rebirthButton.MouseButton1Click:Connect(function()
	local ok, reason = Rebirth:InvokeServer()
	if not ok then
		rebirthButton.Text = reason
		task.wait(2)
		rebirthButton.Text = "⟳ Rebirth ($" .. Brainrots.formatMoney(Config.REBIRTH_BASE_COST * (rebirths + 1)) .. ")"
	end
end)

-- Bottom hint: how the loop works, in one line.
local hint = label(gui, "Hint", "Klik brainrot di conveyor untuk membeli • Klik brainrot orang lain untuk mencuri • Lari ke base saat tsunami!", UDim2.fromOffset(700, 24), UDim2.new(0.5, -350, 1, -36), 16)
hint.TextXAlignment = Enum.TextXAlignment.Center
hint.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
hint.BackgroundTransparency = 0.25

-- Event banner: big centre text for tsunami, thief and rebirth news.
local banner = Instance.new("Frame")
banner.Name = "EventBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 76)
banner.Size = UDim2.fromOffset(560, 72)
banner.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
banner.BackgroundTransparency = 0.15
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui

local bannerTitle = label(banner, "Title", "", UDim2.fromOffset(540, 32), UDim2.fromOffset(10, 6), 26, Color3.fromRGB(255, 255, 255))
bannerTitle.TextXAlignment = Enum.TextXAlignment.Center
local bannerDetail = label(banner, "Detail", "", UDim2.fromOffset(540, 24), UDim2.fromOffset(10, 40), 16, Color3.fromRGB(255, 230, 200))
bannerDetail.TextXAlignment = Enum.TextXAlignment.Center

local bannerHideAt = 0
EventBanner.OnClientEvent:Connect(function(title, detail, seconds)
	bannerTitle.Text = title
	bannerDetail.Text = detail
	banner.Visible = true
	bannerHideAt = os.clock() + (seconds or 4)
end)

-- Money updates from the server.
MoneyChanged.OnClientEvent:Connect(function(newMoney, newIncome, newRebirths)
	money = newMoney
	incomePerSecond = newIncome
	rebirths = newRebirths
	refreshTopBar()
	refreshIndex()
	rebirthButton.Text = "⟳ Rebirth ($" .. Brainrots.formatMoney(Config.REBIRTH_BASE_COST * (rebirths + 1)) .. ")"
end)

-- Hide the banner once its time is up.
task.spawn(function()
	while true do
		task.wait(0.5)
		if banner.Visible and os.clock() >= bannerHideAt then
			banner.Visible = false
		end
	end
end)

refreshTopBar()
refreshIndex()
gui.Parent = player:WaitForChild("PlayerGui")
