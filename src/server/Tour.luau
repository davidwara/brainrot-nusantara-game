-- Tour.luau — the demo hooks TOUR.json calls so reviewers can bring the
-- game to each screenshot's screen from Studio. Every function is safe to
-- call on the server with one argument.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))

local Tour = {}

-- Show the start screen: put a fresh Common brainrot on the conveyor's
-- spawn end so the first screenshot has something to look at.
function Tour.spawnStarter(_arg: string)
	local folder = workspace:FindFirstChild("ConveyorBrainrots")
	if not folder then
		return "no conveyor folder"
	end
	local factory = require(script.Parent:WaitForChild("BrainrotFactory"))
	local def = Brainrots.getById("komodo-kopi")
	local model = factory.build(def, Brainrots.MUTATIONS[1])
	factory.place(model, Vector3.new(-40, 2.5, -35))
	model.Parent = folder
	return "Komodo Kopi is walking the conveyor"
end

-- Show the base screen: fill base 1 with three brainrots of rising rarity.
function Tour.fillBase(_arg: string)
	local folder = workspace:FindFirstChild("Bases")
	if not folder then
		return "no bases folder"
	end
	local factory = require(script.Parent:WaitForChild("BrainrotFactory"))
	local ids = { "komodo-kopi", "nasi-goreng-ninja", "garuda-gacor" }
	for i, id in ipairs(ids) do
		local def = Brainrots.getById(id)
		local model = factory.build(def, Brainrots.MUTATIONS[1])
		factory.place(model, Vector3.new(-51 + (i - 1) * 3, 1.5, 25))
		model.Parent = folder
	end
	return "Base 1 now holds 3 brainrots"
end

-- Show the tsunami screen: slide the wave to the middle of the map.
function Tour.tsunami(_arg: string)
	local wave = workspace:FindFirstChild("TsunamiWave")
	if not wave then
		return "no wave part"
	end
	wave.Transparency = 0.25
	wave.CFrame = CFrame.new(0, 4, 10)
	return "The cendol wave is mid-map"
end

return Tour
