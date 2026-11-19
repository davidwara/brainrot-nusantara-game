-- ci/create-place.lua — Plan C: buat experience "Brainrot Nusantara" dari headless Studio.
-- Dijalankan via: run-in-roblox --place game.rbxl --script ci/create-place.lua
-- (run-in-roblox 0.3.0 WAJIB --place; tanpa itu panic "not implemented" di main.rs:54.)
-- Input lewat environment (diset workflow): PLAN_C_PLACE_NAME, PLAN_C_TEMPLATE_ID.
-- Output (dicetak ke stdout, di-grep workflow): BRAINROT_PLACE_ID=<n> dan
-- BRAINROT_UNIVERSE_ID=<n> (bila lookup HTTP berhasil). Parent juga bisa resolve
-- universeId dari placeId via GET https://apis.roblox.com/universes/v1/places/{placeId}/universe
-- memakai Open Cloud key.
-- TIDAK mengubah file repo, TIDAK upload .rbxl, TIDAK mengubah konfigurasi experience.
-- Hanya membuat SATU experience baru (start place dari template Baseplate).

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")

local placeName = os.getenv("PLAN_C_PLACE_NAME") or "Brainrot Nusantara"
local templateId = tonumber(os.getenv("PLAN_C_TEMPLATE_ID") or "95206881") or 95206881

print("[plan-c] Creating place '" .. placeName .. "' from template " .. tostring(templateId))

local ok, placeId = pcall(function()
	return AssetService:CreatePlaceAsync(placeName, templateId, placeName)
end)

if not ok then
	print("[plan-c] ERROR CreatePlaceAsync failed: " .. tostring(placeId))
	print("BRAINROT_CREATE_FAILED=" .. tostring(placeId))
	return
end

placeId = tonumber(placeId)
print("[plan-c] placeId=" .. tostring(placeId))
print("BRAINROT_PLACE_ID=" .. tostring(placeId))

-- Resolve universeId lewat endpoint publik (tanpa auth). Bila HttpService
-- dimatikan di place kosong ini, lookup gagal tapi placeId tetap valid —
-- parent bisa resolve sendiri dengan Open Cloud key.
local ok2, body = pcall(function()
	return HttpService:GetAsync("https://apis.roblox.com/universes/v1/places/" .. tostring(placeId) .. "/universe")
end)
if ok2 then
	local ok3, data = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if ok3 and data and data.universeId then
		print("BRAINROT_UNIVERSE_ID=" .. tostring(data.universeId))
	else
		print("[plan-c] WARN universe lookup: respons tidak bisa di-decode: " .. tostring(body))
	end
else
	print("[plan-c] WARN universe lookup gagal (bukan fatal): " .. tostring(body))
end

print("[plan-c] DONE")
