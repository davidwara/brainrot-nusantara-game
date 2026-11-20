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
- Mode `test` (cookie dummy): GAGAL 20 Nov 06:42 WITA (run 44630191409, 5m53s) — langkah Install Roblox Studio timeout ~5 menit setelah launch; penyebab hampir pasti cookie dummy (action installer selalu login ke Studio, cookie tidak valid = login gagal). Test mode TANPA cookie asli TIDAK BISA memvalidasi rantai ini. Mode `create` dengan cookie asli adalah validasi sesungguhnya — jangan buang waktu memperbaiki test dummy.
- Mode `create`: GAGAL 20 Nov 06:59 WITA (run 44632765648, 5m51s) — langkah Install Roblox Studio timeout 5 menit LAGI, padahal cookie ASLI sudah dipakai. Jadi bukan cookie dummy penyebabnya. Diagnosis: action `roblox-win-installer-action@1.1` membunuh `install.py` setelah 5 menit (`COMMAND_TIMEOUT` di `src/index.ts`); `install.py` menunggu `RobloxStudioBeta.exe` muncul tanpa batas waktu. Tool ini tidak terawat (workflow self-check-nya `disabled_inactivity`, repo terakhir di-push 2021-07-21). Issue upstream #13 "Hangs on Studio startup" (2022, tanpa perbaikan) — maintainer sendiri menduga autentikasi Roblox sudah berubah. Mode `diag` SELESAI 20 Nov 07:15 WITA (run 44634254755, 12 menit polling): launcher jalan terus tapi `RobloxStudioBeta.exe` TIDAK PERNAH muncul dan folder `Versions` tetap KOSONG — launcher-nya sendiri tidak pernah download Studio. Jadi Plan C (Studio headless) GUGUR. `run-in-roblox` TIDAK punya mekanisme auth sendiri (tidak ada flag cookie) — Studio HARUS sudah login lewat installer.
- Plan D (endpoint web) GUGUR 20 Nov 07:19 WITA: `api.roblox.com` TIDAK resolve dari runner GitHub (DNS gagal, curl exit 6) dan dari VM balas empty reply — host itu sudah mati. `www.roblox.com/ide/places/createV2` 404. Skrip `test-create-endpoint.sh` tersimpan di entry dir (untuk arsip).
- Plan E (mode `studio-zip`, run 44637510921, SEDANG JALAN): Studio di-download langsung sebagai zip dari `setup.roblox.com` (versi via `versionQTStudio`, WAJIB HTTP — HTTPS kena `RemoteCertificateNameMismatch` di runner), di-extract ke `%LOCALAPPDATA%\Roblox\Versions\<version>\`, cookie ditulis ke registry dengan format CEF yang sama seperti `install.py`, lalu `run-in-roblox` menjalankan `ci/create-place.lua`. Run pertama (44637297105) gagal cepat: `run-in-roblox` panic exit 101 — `not implemented: run-in-roblox with no place argument` (main.rs:54). Jadi `--place` WAJIB; diperbaiki dengan `--place game.rbxl` (file ada di kedua branch). Run 44637510921 gagal: `run-in-roblox` timeout 60 dtk (`recv_timeout(Duration::from_secs(60))` di `place_runner.rs:66`) — Studio tidak pernah online. Run 44637964521 (dengan cek cookie + pre-warm) menemukan penyebabnya: cookie di secret TIDAK VALID — `GET users.roblox.com/v1/users/authenticated` balas 401 `User is not authenticated`. Penyebab: gw salah potong cookie saat set secret — gw hanya ambil bagian `_CAEQ` (1066 char), padahal prefix peringatan `_|WARNING...|_` adalah BAGIAN dari nilai cookie (total 1186 byte). Jadi Studio tidak bisa login. Perbaikan: minta file cookie baru dari user, set secret dengan SELURUH isi file (tanpa potong, buang newline saja), verifikasi 200 dulu baru jalankan Studio.
- Run 44643963724 (cookie SUDAH benar, 20 Nov 08:13 WITA): cookie check 200, pre-warm Studio hidup 60 dtk, TAPI `run-in-roblox` tetap timeout 60 dtk (main.rs:75) — Studio tidak pernah online. Bukti kunci dari log pre-warm: TIDAK ADA file log Studio di `%LOCALAPPDATA%\Roblox\logs` — Studio jalan tapi tidak pernah menyelesaikan inisialisasi. Diagnosis (bandingkan dengan `install.py` referensi OrbitalOwen/roblox-win-installer): format registry cookie + ContentFolder + Plugins + AutoSaves SEMUA sudah sama persis dengan referensi — SATU-SATUNYA yang beda: `GlobalSettings_13.xml`. Referensi SELALU menulis template itu (`createSettingsFile`) karena "settings file isn't created until the settings window is closed" — tanpa file itu, first-run Studio macet di setup awal dan tidak pernah load place/plugin. Perbaikan: `ci/GlobalSettings_13.xml` (template referensi, 10.819 byte) + langkah tulis file itu di install studio-zip (`%UserProfile%` diganti user dir runner).
- Run 44645610292 (GlobalSettings SUDAH ditulis, 20 Nov 08:27 WITA): file GlobalSettings_13.xml TERKONFIRMASI tertulis di log install — TAPI hasil IDENTIK: pre-warm Studio hidup 60 dtk, tetap TIDAK ADA file log Studio, `run-in-roblox` tetap timeout 60 dtk. Jadi GlobalSettings BUKAN penyebabnya (hipotesis GUGUR). Verifikasi mekanisme plugin dari source `roblox_install` 0.2.2 (crates.io): `locate()` baca registry `ContentFolder` → root = folder versi, application = `RobloxStudioBeta.exe`, plugins = `%USERPROFILE%\AppData\Local\Roblox\Plugins` — SEMUA sudah benar di workflow kita, jadi plugin ditulis ke tempat yang benar dan Studio di-spawn dengan benar. Kesimpulan: Studio SENDIRI tidak menyelesaikan startup di runner. Dugaan terkuat sekarang: Studio macet di layar login (cookie registry format 2021 mungkin sudah tidak dibaca Studio modern — CEF modern simpan cookie di DB, bukan registry; issue upstream #13 2022 juga menduga autentikasi berubah) ATAU dialog first-run lain. Langkah berikut: pre-warm diperluas jadi diagnostik (daftar proses Roblox + CPU + judul jendela + seluruh file di `%LOCALAPPDATA%\Roblox` + registry) untuk melihat Studio sedang apa selama 60 dtk itu.
- Run 44646953690 (diagnostik pre-warm, 20 Nov 08:32 WITA): BUKTI MENENTUKAN — setelah 60 dtk, `RobloxStudioBeta pid=9136 cpu=0s ws=4MB title=''` (CPU NOL, RAM cuma 4 MB, TIDAK ADA jendela) dan Studio TIDAK membuat file apa pun (hanya GlobalSettings_13.xml yang kita tulis + file hasil extract zip). Jadi prosesnya BUKAN lambat — melainkan TIDAK BERJALAN SAMA SEKALI (macet sebelum/saat loader, atau menunggu sesuatu tanpa eksekusi). GlobalSettings, cookie, plugin path, ContentFolder semua sudah benar. Langkah berikut: mode baru `diag-studio` — Test 0 cek Mark of the Web + Unblock-File, Test A launch tanpa place (30 dtk), Test B launch dengan place + WorkingDirectory=folder Studio (60 dtk), Test C launcher (120 dtk), + dump event log Application. Tujuannya menentukan metode launch mana (kalau ada) yang membuat Studio benar-benar jalan.
- Run 44647765767 (diag-studio pertama, 20 Nov 08:41 WITA): GAGAL di langkah installer LAMA (Plan C) — kondisi langkah itu tidak mengecualikan mode diag-studio, jadi action roblox-win-installer yang sudah mati ikut jalan. Perbaikan: kondisi installer lama ditambah `&& inputs.mode != 'diag-studio'`.
- Run 44648613292 (diag-studio, 20 Nov 08:47 WITA): **TEROBOSAN.** Test 0: MOTW tidak ada. Test A (tanpa place, 30 dtk): `RobloxStudioBeta cpu=0.015625s ws=4MB title=''` — mati. Test B (dengan place + CWD, 60 dtk): `cpu=0.03125s ws=4MB` — mati. Jadi BUKAN place, BUKAN CWD, BUKAN MOTW. **Test C (launcher, 120 dtk): LAUNCHER HIDUP — `RobloxStudioLauncherBeta pid=3264 cpu=3.5625s ws=36MB title='Roblox Studio'` + proses ke-2 pid=4140 (0.47s, 20MB).** Tapi setelah 120 dtk BELUM ada proses RobloxStudioBeta dan folder Versions masih hanya version-d0e8cfcd943d4ae2. Jadi launcher adalah SATU-SATUNYA komponen yang berfungsi; direct-exe mati total. Langkah berikut: Test C diperpanjang jadi 10x60 dtk dengan pantau koneksi jaringan launcher (Get-NetTCPConnection) + folder Versions tiap menit — untuk tahu apakah launcher sedang download (progres) atau macet (mis. menunggu login).
