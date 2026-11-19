-- ci/smoke-test.lua — Plan C smoke test TANPA auth.
-- Membuktikan rantai headless Studio jalan di runner (install + run-in-roblox).
-- Tidak memanggil API Roblox apa pun yang butuh login. Tidak membuat apa pun.

print("[plan-c smoke] Hello from headless Studio")
print("[plan-c smoke] game.PlaceId = " .. tostring(game.PlaceId))
local ok, ver = pcall(version)
if ok then
	print("[plan-c smoke] Studio version: " .. tostring(ver))
else
	print("[plan-c smoke] version() tidak tersedia di konteks ini")
end
print("BRAINROT_SMOKE_OK=1")
print("[plan-c smoke] DONE")
