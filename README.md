# Brainrot Nusantara

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/davidwara/brainrot-nusantara-game/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/davidwara/brainrot-nusantara-game/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

An entry for make.fun's "Make the best AI Roblox brainrot game" bounty
(roblox-brainrot-01): a 3D brainrot game built by a coding agent, played in
Roblox's 3D world under a 3D camera, with a ScreenGui HUD on top of it.

## The game

Kumpulkan brainrot paling absurd se-Indonesia! Brainrot berjalan di conveyor,
kamu klik untuk membeli, mereka berdiri di basemu dan menghasilkan uang tiap
detik. Naik ke rarity yang lebih tinggi, cari mutasi Golden / Diamond /
Rainbow / Lava, rebirth untuk +50% income selamanya — sambil lari pulang saat
Tsunami Cendol datang dan mengusir Maling Brainrot yang mengincar basemu.

- **18 karakter original Indonesia** — Komodo Kopi, Cendol Ceria, Nasi Goreng
  Ninja, Garuda Gacor, Rendang Raksasa, Nusantara Prime, dan lainnya. Bukan
  jiplakan karakter game lain.
- **6 rarity** — Common, Rare, Epic, Legendary, Mythic, Brainrot God — plus
  5 mutasi yang melipatgandakan income.
- **Loop lengkap** — beli di conveyor, taruh di base (10 slot), uang mengalir
  tiap detik, beli tier berikutnya, rebirth, kunci base, curi balik dari
  pemain lain.
- **Dua ancaman** — Tsunami Cendol menyapu map tiap beberapa menit (yang di
  luar base tersapu pulang ke spawn) dan Maling Brainrot yang menyelinap ke
  base untuk mencuri brainrot terbaikmu. Klik dia untuk mengusirnya.
- **Dunia 3D** — pulau dengan plaza, conveyor, 8 base berwarna, gunung
  berapi, sungai cendol, pohon palem, dan karakter pemain 3D yang berjalan
  dengan WASD di bawah kamera 3D Roblox.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy,
  unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `src/shared/` — `Brainrots.luau` (the cast, rarities, mutations) and
  `Config.luau` (every tuning number).
- `src/server/` — `init.server.luau` (wiring), `Conveyor.luau` (the belt),
  `PlayerData.luau` (money, bases, rebirth, stealing), `Events.luau`
  (Tsunami Cendol + Maling Brainrot), `BrainrotFactory.luau` (the 3D bodies),
  `Tour.luau` (the demo hooks `TOUR.json` calls).
- `src/client/Game.client.luau` — the HUD: money, income, brainrot index,
  base controls, event banner.
- `screenshots/` holds four renders of the game (1280x720); the first,
  `1-thumbnail.jpg`, is also the game's first thumbnail on Roblox.
- `PLAY.json` names the published place once the account owner publishes it
  (pending: the Roblox account is not available yet, see below).

## Publish status

The game is built and playable end-to-end, but it is not published yet: the
Roblox account that will own the experience is still being created, and only
its owner can create the experience, set it Public and upload its icon and
thumbnail. `PLAY.json` still names place 0 until then. Once the account is
ready, publish `game.rbxl` over the experience, put the play code in its
description, upload `1-thumbnail.jpg` as its first thumbnail, and fill in
`PLAY.json`.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the
kit's RULES.txt, which gives every command in order (Before you submit, then
Enter).
