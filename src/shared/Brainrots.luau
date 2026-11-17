-- Brainrots.luau — the cast of Brainrot Nusantara.
-- Every character is an original Indonesian meme creature, invented for this
-- game. Nothing here copies a character from another game.
-- Each entry: the display name, its rarity, what it costs, what it earns per
-- second, its body colour, how tall it stands and one joke line the HUD shows.

local Brainrots = {}

export type RarityName = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Brainrot God"

export type BrainrotDef = {
	Id: string,
	Name: string,
	Rarity: RarityName,
	Cost: number,
	Income: number,
	Color: Color3,
	Height: number,
	Quirk: string,
}

-- Rarity colours, as the HUD and the name labels paint them.
Brainrots.RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(80, 180, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 70, 90),
	["Brainrot God"] = Color3.fromRGB(255, 230, 90),
}

-- How often a rarity walks down the conveyor (weights, not percents).
Brainrots.RARITY_WEIGHTS = {
	Common = 45,
	Rare = 27,
	Epic = 15,
	Legendary = 8,
	Mythic = 4,
	["Brainrot God"] = 1,
}

-- Mutations: a brainrot can spawn mutated, multiplying its income.
-- Chance is rolled per spawn; Lava only ever appears while the volcano smokes.
Brainrots.MUTATIONS = {
	{ Name = "Normal", Multiplier = 1, Chance = 86, Color = Color3.fromRGB(255, 255, 255) },
	{ Name = "Golden", Multiplier = 2, Chance = 8, Color = Color3.fromRGB(255, 215, 0) },
	{ Name = "Lava", Multiplier = 8, Chance = 2, Color = Color3.fromRGB(255, 80, 20) },
	{ Name = "Diamond", Multiplier = 5, Chance = 3, Color = Color3.fromRGB(140, 230, 255) },
	{ Name = "Rainbow", Multiplier = 10, Chance = 1, Color = Color3.fromRGB(255, 120, 220) },
}

Brainrots.CAST = {
	{ Id = "komodo-kopi", Name = "Komodo Kopi", Rarity = "Common", Cost = 100, Income = 2, Color = Color3.fromRGB(120, 90, 60), Height = 3, Quirk = "Ngopi dulu, baru ngejar mangsa." },
	{ Id = "cendol-ceria", Name = "Cendol Ceria", Rarity = "Common", Cost = 250, Income = 5, Color = Color3.fromRGB(90, 200, 120), Height = 3, Quirk = "Manisnya bikin ketagihan, gulanya bikin lari." },
	{ Id = "bakso-bulat", Name = "Bakso Bulat", Rarity = "Common", Cost = 500, Income = 10, Color = Color3.fromRGB(200, 170, 140), Height = 3, Quirk = "Bulatan sempurna, kuahnya rahasia negara." },
	{ Id = "nasi-goreng-ninja", Name = "Nasi Goreng Ninja", Rarity = "Rare", Cost = 1500, Income = 28, Color = Color3.fromRGB(220, 140, 60), Height = 4, Quirk = "Wok-nya berapi, gerakannya tak terlihat." },
	{ Id = "sate-silet", Name = "Sate Silet", Rarity = "Rare", Cost = 3000, Income = 55, Color = Color3.fromRGB(180, 90, 50), Height = 4, Quirk = "Setusuk sate, seribu rahasia." },
	{ Id = "gudeg-gembul", Name = "Gudeg Gembul", Rarity = "Rare", Cost = 6000, Income = 100, Color = Color3.fromRGB(150, 110, 60), Height = 4, Quirk = "Manis legit, perut pun tunduk." },
	{ Id = "kancil-kencang", Name = "Kancil Kencang", Rarity = "Epic", Cost = 12000, Income = 190, Color = Color3.fromRGB(160, 120, 70), Height = 4, Quirk = "Si kecil yang selalu menang lomba lari." },
	{ Id = "durian-duar", Name = "Durian Duar", Rarity = "Epic", Cost = 25000, Income = 380, Color = Color3.fromRGB(220, 200, 60), Height = 5, Quirk = "Bau menyengat, ledakan lebih menyengat." },
	{ Id = "ondel-ondel-oke", Name = "Ondel-Ondel Oke", Rarity = "Epic", Cost = 50000, Income = 750, Color = Color3.fromRGB(230, 60, 60), Height = 5, Quirk = "Goyangannya bikin satu kampung ikut joget." },
	{ Id = "garuda-gacor", Name = "Garuda Gacor", Rarity = "Legendary", Cost = 120000, Income = 1600, Color = Color3.fromRGB(255, 200, 40), Height = 6, Quirk = "Sayap emas, suara merdu, harga selangit." },
	{ Id = "banteng-boba", Name = "Banteng Boba", Rarity = "Legendary", Cost = 250000, Income = 3200, Color = Color3.fromRGB(120, 60, 140), Height = 6, Quirk = "Ngamuk kalau bobanya habis." },
	{ Id = "elang-es-teh", Name = "Elang Es Teh", Rarity = "Legendary", Cost = 500000, Income = 6000, Color = Color3.fromRGB(120, 200, 255), Height = 6, Quirk = "Terbang tinggi, es tehnya tetap dingin." },
	{ Id = "barong-beringas", Name = "Barong Beringas", Rarity = "Mythic", Cost = 1000000, Income = 12000, Color = Color3.fromRGB(200, 40, 40), Height = 7, Quirk = "Topengnya tersenyum, tapi jangan didekati." },
	{ Id = "wayang-wibu", Name = "Wayang Wibu", Rarity = "Mythic", Cost = 2500000, Income = 28000, Color = Color3.fromRGB(90, 60, 160), Height = 7, Quirk = "Dalangnya nonton anime semalaman." },
	{ Id = "kujang-kilat", Name = "Kujang Kilat", Rarity = "Mythic", Cost = 5000000, Income = 55000, Color = Color3.fromRGB(220, 220, 230), Height = 7, Quirk = "Sekali tebas, petir pun iri." },
	{ Id = "rendang-raksasa", Name = "Rendang Raksasa", Rarity = "Brainrot God", Cost = 12000000, Income = 130000, Color = Color3.fromRGB(140, 70, 30), Height = 9, Quirk = "Dimasak 8 jam, disembah selamanya." },
	{ Id = "komodo-raja-kopi", Name = "Komodo Raja Kopi", Rarity = "Brainrot God", Cost = 30000000, Income = 300000, Color = Color3.fromRGB(80, 50, 30), Height = 9, Quirk = "Raja segala warung kopi di nusantara." },
	{ Id = "nusantara-prime", Name = "Nusantara Prime", Rarity = "Brainrot God", Cost = 75000000, Income = 700000, Color = Color3.fromRGB(255, 230, 90), Height = 10, Quirk = "Satu pulau, satu legenda, satu harga gila." },
}

-- Look a character up by id; returns nil for an unknown id.
function Brainrots.getById(id: string): BrainrotDef?
	for _, def in ipairs(Brainrots.CAST) do
		if def.Id == id then
			return def
		end
	end
	return nil
end

-- All characters of one rarity, in cost order.
function Brainrots.getByRarity(rarity: RarityName): { BrainrotDef }
	local out = {}
	for _, def in ipairs(Brainrots.CAST) do
		if def.Rarity == rarity then
			table.insert(out, def)
		end
	end
	return out
end

-- Roll a rarity from the weights above.
function Brainrots.rollRarity(): RarityName
	local total = 0
	for _, w in pairs(Brainrots.RARITY_WEIGHTS) do
		total += w
	end
	local roll = math.random(1, total)
	local acc = 0
	for rarity, w in pairs(Brainrots.RARITY_WEIGHTS) do
		acc += w
		if roll <= acc then
			return rarity :: RarityName
		end
	end
	return "Common"
end

-- Roll a mutation; returns the mutation row.
function Brainrots.rollMutation()
	local total = 0
	for _, m in ipairs(Brainrots.MUTATIONS) do
		total += m.Chance
	end
	local roll = math.random(1, total)
	local acc = 0
	for _, m in ipairs(Brainrots.MUTATIONS) do
		acc += m.Chance
		if roll <= acc then
			return m
		end
	end
	return Brainrots.MUTATIONS[1]
end

-- Format money the way the HUD shows it: 1.2K, 3.4M, 5.6B, 7.8T.
function Brainrots.formatMoney(amount: number): string
	if amount >= 1e12 then
		return string.format("%.1fT", amount / 1e12)
	elseif amount >= 1e9 then
		return string.format("%.1fB", amount / 1e9)
	elseif amount >= 1e6 then
		return string.format("%.1fM", amount / 1e6)
	elseif amount >= 1e3 then
		return string.format("%.1fK", amount / 1e3)
	else
		return tostring(math.floor(amount))
	end
end

return Brainrots
