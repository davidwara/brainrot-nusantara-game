-- BrainrotFactory.luau — builds the 3D body of a brainrot from parts.
-- Every brainrot is a little blocky creature: a coloured body, a head with two
-- eyes, a rarity-coloured glow and a floating name label that shows its name,
-- rarity and money per second. Mutations tint the whole body.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))

local BrainrotFactory = {}

-- A small floating label above the brainrot: name, rarity, $/s.
local function makeLabel(def, mutation, incomePerSecond): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(140, 64)
	gui.StudsOffset = Vector3.new(0, def.Height + 2, 0)
	gui.AlwaysOnTop = true

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.new(0, 0, 0, 22)
	rarityLabel.Size = UDim2.new(1, 0, 0, 18)
	rarityLabel.BackgroundTransparency = 1
	local rarityText = def.Rarity
	if mutation.Name ~= "Normal" then
		rarityText = mutation.Name .. " " .. rarityText
	end
	rarityLabel.Text = rarityText
	rarityLabel.TextColor3 = Brainrots.RARITY_COLORS[def.Rarity]
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.Parent = gui

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "Income"
	incomeLabel.Position = UDim2.new(0, 0, 0, 40)
	incomeLabel.Size = UDim2.new(1, 0, 0, 20)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "$" .. Brainrots.formatMoney(incomePerSecond) .. "/s"
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.SourceSansBold
	incomeLabel.Parent = gui

	return gui
end

-- Build the model. `mutation` is one row of Brainrots.MUTATIONS.
-- Returns the Model; the caller parents it and sets its position.
function BrainrotFactory.build(def, mutation): Model
	local incomePerSecond = def.Income * mutation.Multiplier
	local tint = mutation.Color
	local bodyColor = def.Color
	if mutation.Name ~= "Normal" then
		-- A mutated brainrot keeps its own colour but glows with the mutation.
		bodyColor = bodyColor:Lerp(tint, 0.45)
	end

	local model = Instance.new("Model")
	model.Name = def.Id
	-- The model's height, so place() can put its feet on a surface.
	model:SetAttribute("Height", height)

	local height = def.Height
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(3, height * 0.6, 2.4)
	body.Position = Vector3.new(0, height * 0.3, 0)
	body.Color = bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Block
	head.Size = Vector3.new(3.4, height * 0.4, 2.8)
	head.Position = Vector3.new(0, height * 0.8, 0)
	head.Color = bodyColor
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- Two big meme eyes on the front of the head.
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.9, 1.1, 0.5)
		eye.Position = Vector3.new(side * 0.8, height * 0.85, 1.5)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model

		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = Vector3.new(0.45, 0.55, 0.3)
		pupil.Position = Vector3.new(side * 0.8, height * 0.85, 1.75)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Material = Enum.Material.SmoothPlastic
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Parent = model
	end

	-- A rarity glow: a thin neon frame under the body.
	local glow = Instance.new("Part")
	glow.Name = "RarityGlow"
	glow.Size = Vector3.new(3.6, 0.25, 3)
	glow.Position = Vector3.new(0, 0.15, 0)
	glow.Color = Brainrots.RARITY_COLORS[def.Rarity]
	glow.Material = Enum.Material.Neon
	glow.Anchored = true
	glow.CanCollide = false
	glow.Parent = model

	-- The click target: buying and stealing both start from a click.
	local click = Instance.new("ClickDetector")
	click.Name = "BrainrotClick"
	click.MaxActivationDistance = 32
	click.Parent = body

	local label = makeLabel(def, mutation, incomePerSecond)
	label.Parent = head

	model.PrimaryPart = body
	return model
end

-- Put a brainrot down so its feet stand on `position` (a surface point).
-- A model's pivot sits at its bounding-box centre, about Height/2 above its
-- feet, so the pivot goes that much higher. The base spot is remembered so
-- bob() can keep the brainrot over it.
function BrainrotFactory.place(model: Model, position: Vector3)
	local height = model:GetAttribute("Height") or 3
	model:PivotTo(CFrame.new(position.X, position.Y + height / 2, position.Z))
	model:SetAttribute("BaseX", position.X)
	model:SetAttribute("BaseFootY", position.Y)
	model:SetAttribute("BaseZ", position.Z)
end

-- Bobbing animation for a brainrot standing on a base: called every frame
-- from the server's heartbeat with a per-brainrot phase. The whole model
-- moves (PivotTo), never just one part, so the body, head and label stay
-- together.
function BrainrotFactory.bob(model: Model, time: number, phase: number)
	local height = model:GetAttribute("Height") or 3
	local baseX = model:GetAttribute("BaseX")
	local baseFootY = model:GetAttribute("BaseFootY")
	local baseZ = model:GetAttribute("BaseZ")
	if baseX == nil or baseFootY == nil or baseZ == nil then
		return
	end
	local offset = math.sin(time * 2 + phase) * 0.25
	model:PivotTo(CFrame.new(baseX, baseFootY + height / 2 + offset, baseZ))
end

return BrainrotFactory
