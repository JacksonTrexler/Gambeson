extends Test

# The engine routed through the modifier reader (docs/plans/route.md): each read below changes under a
# rho, sigma or lambda modifier, the same way in what the skill does and in its description as its
# holder has it (Skill.markup() given a unit); requirements reach every outcome path; behaviours run on
# every path that lands; the AI and the HUD estimate damage as cast() deals it (Battle.damage_range()).

var haluca: Skill = load("res://Skills/haluca.tres")


func emblem(word: StringName, scope: StringName, rank := 1) -> Item:
	var it := Item.new()
	it.name = "Test %s %s" % [word, scope]
	it.slot = "trinket"
	it.emblem = word
	it.scope = scope
	it.rank = rank
	return it


func learn(u: Unit, s: Skill, r: int) -> void:
	u.learned.append(slot(s, r))
	u.bar_place(s, 0)  # a Sigil's skill: the leftmost it fits
	u.refresh()


# The caster's contest totals for one cast of s on t from a fixed seed.
func contest_total(u: Unit, s: Skill, t: Unit) -> Array:
	var got := []
	var spy := func(_c: Unit, _t: Unit, total: int, against: int): got.append([total, against])
	b.contested.connect(spy)
	u.refresh()
	b.rng.seed = 7
	b.cast(u, s, t)
	b.contested.disconnect(spy)
	return got[0] if got else [0, 0]


# A save's + rank (Haluca: vs cha mod + rank) is rank impact; so is an execute's / rank.
func test_save_rank() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	learn(v(3), haluca, 2)
	v(1).wisdom = 30
	var plain := contest_total(v(3), haluca, v(1))
	ok("vs cha mod + 2" in haluca.describe(2, v(3)), haluca.describe(2, v(3)))
	v(3).trinket = emblem(&"rho_up", &"sigil")  # x1.75: rank 2 -> 4
	var dense := contest_total(v(3), haluca, v(1))
	ok(dense[0] - plain[0] == 2, "Density: + 4 on the save, not + 2 (%s vs %s)" % [dense, plain])
	ok("vs cha mod + 4" in haluca.describe(2, v(3)) and "vs cha mod + 2" in haluca.describe(2), "described as held: + 4; base: + 2")
	var exe: Skill = haluca.duplicate()
	exe.tags = haluca.tags + ([&"execute"] as Array[StringName])
	SkillTerms.forget(exe)
	v(3).trinket = null
	learn(v(3), exe, 2)
	v(1).max_hp = 100
	v(1).hp = 50
	var cut := contest_total(v(3), exe, v(1))
	v(3).trinket = emblem(&"rho_up", &"sigil")
	var cut_more := contest_total(v(3), exe, v(1))
	ok(cut_more[1] < cut[1], "an execute's / rank at rank impact: its foe's save is cut further (%s < %s)" % [cut_more[1], cut[1]])


# A contingency (Skill.requires) pays on a save as on an attack roll; lambda shows in its description.
func test_requirement_paths() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	var h: Skill = haluca.duplicate()
	h.requires = Requirement.new()
	h.requires.test = &"hp_above"
	h.requires.share = 0.5
	h.requires.hit = 3
	h.requires.turns = 2
	SkillTerms.forget(h)
	learn(v(3), h, 1)
	v(1).wisdom = 30
	v(3).hp = v(3).max_hp
	var met := contest_total(v(3), h, v(1))
	v(3).hp = 1
	var unmet := contest_total(v(3), h, v(1))
	ok(met[0] - unmet[0] == 3, "met: + 3 on its save (%s vs %s)" % [met, unmet])
	ok("At or above 50% HP: +3 to its check, its effects last +2 turns" in h.describe(1), h.describe(1))
	v(3).trinket = emblem(&"lambda_up", &"sigil")  # f 0.75: share 0.5^1.75 = 30%, payoff x1.75
	ok("At or above 70% HP: +5 to its check, its effects last +4 turns" in h.describe(1, v(3)), h.describe(1, v(3)))
	v(1).wisdom = 1  # it fails: Scrambled for its turns + the contingency's
	v(3).hp = v(3).max_hp
	v(3).trinket = null
	var tries := 0
	while v(1).scrambled() == null and tries < 20:
		v(3).refresh()
		b.cast(v(3), h, v(1))
		tries += 1
	ok(v(1).scrambled() != null and v(1).scrambled().total == h.lasts(1, v(3)) + 2, "its effects last + 2 turns while met")


# A heal: + to what it heals while met; sigma down (stat impact x) shows on its mods.
func test_heal() -> void:
	var mend := Skill.new()
	mend.name = "Mend ??"
	mend.heal_mods = [&"wisdom"] as Array[StringName]
	mend.hostile = false
	mend.radius = 3.0
	mend.ap = 1.0
	mend.requires = Requirement.new()
	mend.requires.test = &"hp_above"
	mend.requires.share = 0.5
	mend.requires.damage = 4
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(3, 3)})
	v(1).wisdom = 14  # +2
	learn(v(1), mend, 1)
	v(2).hp = 1
	b.cast(v(1), mend, v(2))
	ok(v(2).hp == 1 + 2 + 4, "met: heals wis mod + 4 (%d)" % v(2).hp)
	v(1).trinket = emblem(&"sigma_down", &"sigil")  # stat impact x1.75
	ok("Heals 1.75 x wis mod HP" in mend.describe(1, v(1)) and "Heals wis mod HP" in mend.describe(1), mend.describe(1, v(1)))
	v(2).hp = 1
	v(1).refresh()
	b.cast(v(1), mend, v(2))
	ok(v(2).hp == 1 + roundi(2 * 1.75) + 4, "Concentrated: heals 1.75 x its wis mod (%d)" % v(2).hp)


# Wildfire's imposed DC is at its rank impact; Solar's cone and Flamewall's width at its rank range.
func test_area() -> void:
	var wildfire: Skill = load("res://Skills/wildfire.tres")
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	learn(v(1), wildfire, 2)
	v(1).trinket = emblem(&"rho_up", &"sigil")
	v(1).max_energy = 99
	v(1).energy = 99
	var dcs := []
	b.evaded.connect(func(_u: Unit, _t: int, dc: int, _s: float): dcs.append(dc))
	v(1).refresh()
	v(1).ap.append(AP.new(20.0, &""))
	v(1).energy = 99
	b.cast_at(v(1), wildfire, v(3).cell)
	var dc := Difficulty.dc(wildfire.difficulty, 4)
	ok(dcs.size() > 0 and dcs[0] == dc and dc != Difficulty.dc(wildfire.difficulty, 2), "Density: the dodge's DC at rank 4 (%s)" % [dcs])
	ok("DC %d" % dc in wildfire.describe(2, v(1)), wildfire.describe(2, v(1)))
	var solar: Skill = load("res://Skills/solar.tres")
	v(1).trinket = emblem(&"rho_down", &"sigil")
	learn(v(1), solar, 2)
	var cone = solar.behaviour(&"cone")
	var wide: float = cone.width(2, v(1).mods(solar))
	ok(is_equal_approx(wide, cone.degrees + 15.0 * (2 * 1.75 - 1.0)) and wide > cone.width(2), "Diluted: Solar's cone + 15 a rank, its rank x1.75 (%s)" % wide)
	ok("A %d degree cone" % roundi(wide) in solar.describe(2, v(1)), solar.describe(2, v(1)))


func test_flamewall() -> void:
	var wall: Skill = load("res://Skills/flamewall.tres")
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(6, 6)})
	learn(v(1), wall, 2)
	b.flames.clear()
	v(1).energy = 99
	v(1).ap.append(AP.new(20.0, &""))
	b.cast_at(v(1), wall, Vector2i(3, 2))
	var plain := b.flames.size()
	v(1).trinket = emblem(&"rho_down", &"sigil")  # width rank 2 -> 4
	b.flames.clear()
	v(1).refresh()
	v(1).energy = 99
	v(1).ap.append(AP.new(20.0, &""))
	b.cast_at(v(1), wall, Vector2i(3, 2))
	ok(b.flames.size() > plain, "Diluted: a wider wall (%d tiles, from %d)" % [b.flames.size(), plain])
	ok("Sets the tile and 4 to either side" in wall.describe(2, v(1)) and "Sets the tile and 2 to either side" in wall.describe(2), wall.describe(2, v(1)))


# An aura's reach is rank range.
func test_aura() -> void:
	var glow := Skill.new()
	glow.name = "Glow ??"
	glow.behaviours = [load("res://Behaviours/aura.gd").new()] as Array[Behaviour]
	glow.hostile = false
	glow.self_only = true
	glow.turns = 2
	glow.ap = 1.0
	glow.effects = [effect("zz_glow", 1)] as Array[Effect]
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(4, 3)})
	learn(v(1), glow, 1)
	b.cast(v(1), glow, v(1))
	ok(is_zero_approx(v(2).stat(&"zz_glow")), "rank I: 1 tile, not 2")
	v(1).trinket = emblem(&"rho_down", &"sigil")  # rank range x1.75: 2
	v(1).refresh()
	b.cast(v(1), glow, v(1))
	ok(v(2).stat(&"zz_glow") > 0.0, "Diluted: reaches 2 tiles")
	ok("within 2 tiles" in glow.describe(1, v(1)) and "within 1 tile" in glow.describe(1), glow.describe(1, v(1)))


# hits_per_rank is rank impact, in the damage, its description and the shared estimate.
func test_hits() -> void:
	var flurry := Skill.new()
	flurry.name = "Flurry ??"
	flurry.hostile = true
	flurry.hits_per_rank = true
	flurry.radius = 1.5
	flurry.ap = 1.0
	var t := Tier.new()
	t.power = 1
	flurry.tiers = [t] as Array[Tier]
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	learn(v(1), flurry, 2)
	ok(Battle.damage_range(v(1), flurry).hi == 2, "rank II: 2 hits of 1")
	v(1).trinket = emblem(&"rho_up", &"sigil")
	ok(Battle.damage_range(v(1), flurry).hi == 4 and "4 hits of 1" in flurry.describe(2, v(1)), "Density: 4 hits (%s)" % flurry.describe(2, v(1)))
	var hits := [0]
	v(3).taking_hit.connect(func(_u: Unit, _blow: Dictionary): hits[0] += 1)
	soak(v(3), 99)
	for i in 6:
		if hits[0] > 0:
			break
		v(1).refresh()
		b.cast(v(1), flurry, v(3))
	ok(hits[0] == 4, "it lands 4 hits (%d)" % hits[0])
	var r := b.read(v(1), v(3))
	var dense := AI.score(v(1), flurry, r)
	v(1).trinket = null
	ok(dense > AI.score(v(1), flurry, r), "the AI's score reads it too")


# Its price as its holder pays it, in its description; the skills screen marks base values.
func test_price() -> void:
	var s := Skill.new()
	s.name = "Priced ??"
	s.hostile = true
	s.ap = 4.0
	s.cost = 4
	s.turns_per_rank = 1
	s.effects = [effect("luck", -1)] as Array[Effect]
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	learn(v(1), s, 3)
	ok("4 AP · 4 cost" in s.describe(3, v(1)), s.describe(3, v(1)))
	v(1).trinket = emblem(&"rho_up", &"insignia", 3)  # its turns a rank: rank impact x1.75
	var line := "%s AP · %d cost" % [Skill.num(v(1).ap_cost(s, null)), v(1).price(s)]
	ok(v(1).price(s) != 4 and line in s.describe(3, v(1)), "Density: priced anew, and it says so (%s / %s)" % [line, s.describe(3, v(1))])
	ok("4 AP · 4 cost" in s.describe(3) and "Base values: ρ↑" in Skill.base_note(v(1), s) and Skill.base_note(v(3), s) == "", "the base without a holder; a note where modifiers change it")


class Spy extends Behaviour:
	var landed := 0

	func apply(_c: Cast) -> void:
		landed += 1


# Behaviours run on Strike's chain and on the paths that return early once they land.
func test_behaviours_everywhere() -> void:
	var spy := Spy.new()
	var chain: Skill = strike.duplicate()
	chain.behaviours = [spy] as Array[Behaviour]
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	learn(v(1), chain, 1)
	soak(v(3), 99)
	for i in 8:
		if v(3).hp < 99:
			break
		v(1).refresh()
		b.cast(v(1), chain, v(3))
	ok(v(3).hp < 99 and spy.landed >= 1, "Strike's chain: its behaviours land with its first hit (%d)" % spy.landed)
	var spy2 := Spy.new()
	var glow := Skill.new()
	glow.name = "Glow ??"
	glow.hostile = false
	glow.self_only = true
	glow.ap = 1.0
	glow.behaviours = [load("res://Behaviours/aura.gd").new(), spy2] as Array[Behaviour]
	learn(v(1), glow, 1)
	b.cast(v(1), glow, v(1))
	ok(spy2.landed == 1, "an aura's early return runs them too")


# r-param's six deferred skills, whose reads live in Battle.gd: each now fits a modifier, and its
# description as held shows it.
func test_deferred_six() -> void:
	for id in ["beastshape", "burning_bag", "elemental_strike", "emergency_exit", "waltz_of_vapors", "relay"]:
		ok(Modifiers.words().slice(0, 6).any(func(w: StringName): return Modifiers.eligible(w, sk(id))), "%s fits a symbol" % id)
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(6, 6)})
	v(1).trinket = emblem(&"rho_up", &"insignia", 3)  # rank impact x1.75: rank 2 -> 4
	for id in ["beastshape", "burning_bag", "elemental_strike", "emergency_exit"]:
		learn(v(1), sk(id), 2)
	ok("at rank 4, for 5 turns" in sk("beastshape").describe(2, v(1)) and "at rank 2, for 3 turns" in sk("beastshape").describe(2), sk("beastshape").describe(2, v(1)))
	ok("puts it on, at rank 4" in sk("burning_bag").describe(2, v(1)), sk("burning_bag").describe(2, v(1)))
	ok("your next 4 Strikes" in sk("elemental_strike").describe(2, v(1)), sk("elemental_strike").describe(2, v(1)))
	ok("opens 4 turns sooner" in sk("emergency_exit").describe(2, v(1)) and "within 1 tiles" in sk("emergency_exit").describe(2, v(1)), sk("emergency_exit").describe(2, v(1)))
	v(1).trinket = emblem(&"rho_down", &"insignia", 3)  # rank range x1.75
	learn(v(1), sk("waltz_of_vapors"), 2)
	ok("radius 4 +" in sk("waltz_of_vapors").describe(2, v(1)), sk("waltz_of_vapors").describe(2, v(1)))
	v(1).trinket = null
	v(1).strength = 16  # +3
	learn(v(1), sk("relay"), 1)
	var plain := v(1).stat(&"relay")
	v(1).trinket = emblem(&"sigma_down", &"badge", 3)  # stat impact x(1 + 4/5)
	ok(is_equal_approx(plain, 0.3) and v(1).stat(&"relay") > plain, "Relay: 0.1 per str mod, its mod through Concentrated (%s -> %s)" % [plain, v(1).stat(&"relay")])
	var coordinate := sk("coordinate")
	v(1).trinket = emblem(&"sigma_up", &"crest", 1)
	learn(v(1), coordinate, 1)
	ok("within its 1.67 x cha mod in tiles" in coordinate.describe(1, v(1)), coordinate.describe(1, v(1)))
