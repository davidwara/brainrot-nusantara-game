# Plan C — Buat experience Roblox tanpa PC (GitHub Actions + Studio headless)

Branch `plan-c/create-experience`. File-file di branch ini TIDAK menyentuh `main`
(game, `PLAY.json`, kit) — hanya menambah workflow + skrip CI di bawah ini.

## Masalah
Roblox sudah tidak menyediakan tombol bikin experience di web (terbukti 20 Nov 2026:
Creator Dashboard hanya ada "Buat di Studio"). Open Cloud tidak punya endpoint
create universe. Studio hanya Windows/Mac. User tidak punya PC.

## Solusi
GitHub Actions `windows-latest` (gratis untuk repo publik):
1. Install Roblox Studio via `OrbitalOwen/roblox-win-installer-action@1.1`
   (butuh `.ROBLOSECURITY` cookie akun BorneoBrainrot sebagai repo secret).
2. Install `run-in-roblox` 0.3.0 via Foreman.
3. `run-in-roblox --script ci/create-place.lua` menjalankan
   `AssetService:CreatePlaceAsync("Brainrot Nusantara", 95206881)` (template Baseplate)
   di dalam Studio headless. Script mencetak `BRAINROT_PLACE_ID=<n>` dan
   (bila lookup HTTP jalan) `BRAINROT_UNIVERSE_ID=<n>` ke stdout; workflow
   mengekstrak keduanya ke `place-ids.txt` + artefak `plan-c-run-log`.

## File
- `.github/workflows/create-experience.yml` — workflow, trigger `workflow_dispatch`
  (mode `test` / `create`, input nama + template).
- `ci/create-place.lua` — skrip Luau yang membuat experience.
- `ci/smoke-test.lua` — smoke test tanpa auth (mode `test`).
- `foreman.toml` — definisi tool run-in-roblox untuk setup-foreman.

## Yang dibutuhkan sebelum mode=create
Repo secret `ROBLOSECURITY` = nilai cookie `.ROBLOSECURITY` sesi Roblox akun
BorneoBrainrot. Cara mengambil cookie (butuh browser desktop / DevTools — TIDAK
bisa dari HP Android biasa):
1. Di Chrome/Firefox desktop yang sudah login Roblox: DevTools (F12) → tab
   Application → Cookies → `https://www.roblox.com` → klik `.ROBLOSECURITY` →
   salin "Cookie Value".
2. Set sebagai secret (dari VM, PAT ada di `../.github-pat`, jangan print nilainya):
   `GH_TOKEN=$(cat ../.github-pat) gh secret set ROBLOSECURITY --repo davidwara/brainrot-nusantara-game`
   (paste cookie saat diminta; `gh` membaca dari stdin — nilai tidak masuk log/shell history).
3. Dispatch:
   `GH_TOKEN=$(cat ../.github-pat) gh workflow run create-experience.yml --repo davidwara/brainrot-nusantara-game --ref plan-c/create-experience -f mode=create`
4. Tunggu ±10–20 menit, cek tab Actions. Ambil `place_id`/`universe_id` dari
   log atau artefak `place-ids.txt`.
5. Verifikasi independen (Open Cloud key, endpoint publik):
   `curl -s "https://apis.roblox.com/universes/v1/places/{placeId}/universe" -H "x-api-key: $(cat ../.roblox-open-cloud-key)"`
   → harus mengembalikan `{"universeId": N}` yang cocok.

## Keamanan
- Cookie HANYA hidup sebagai GitHub Actions secret (terenkripsi, tidak tampil di
  log — GitHub otomatis me-mask secret di output). Jangan pernah paste cookie ke
  chat, file repo, atau issue.
- Setelah experience dibuat, SEGERA putar (rotate) sesi Roblox bila memungkinkan
  (logout semua sesi lain) — cookie yang bocor = akses penuh akun.
- Workflow ini TIDAK mengupload `game.rbxl`, TIDAK mengubah konfigurasi
  experience, TIDAK submit ke make.fun. Langkah-langkah itu dikerjakan parent
  sesudah `place_id`/`universe_id` didapat.

## Status pengujian
- Mode `test` (cookie dummy): _diisi setelah run pertama_.
- Mode `create`: _menunggu secret `ROBLOSECURITY`_.
