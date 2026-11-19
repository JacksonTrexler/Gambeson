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
	ok(dense[0] - plain[0] == 2 + v(3).mods(haluca).check, "Density: + 4 on the save, not + 2, less its check shift %d (%s vs %s)" % [v(3).mods(haluca).check, dense, plain])
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
	h.costs = ""  # hand-priced as Haluca was (4 AP, 2): its payoff would price it up past what v(3) has (w2-cost)
	h.ap = 4.0
	h.cost = 2
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
	var dc := Difficulty.dc(wildfire.difficulty, 4) + v(1).mods(wildfire).check  # less its check shift: easier to dodge
	ok(dcs.size() > 0 and dcs[0] == dc and v(1).mods(wildfire).check < 0, "Density: the dodge's DC at rank 4, less its check shift (%s)" % [dcs])
	ok("DC %d" % dc in wildfire.describe(2, v(1)), wildfire.describe(2, v(1)))
	var solar: Skill = load("res://Skills/solar.tres").duplicate()  # a rank impact to trade, so Diluted fits it (docs/plans/w4-density.md)
	solar.turns_per_rank = 1
	SkillTerms.forget(solar)
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
	glow.turns_per_rank = 1  # a rank impact for Diluted to trade against its reach
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


class Miss extends Behaviour:
	var landed := 0
	var missed_on := 0

	func apply(_c: Cast) -> void:
		landed += 1

	func missed(c: Cast) -> void:
		missed_on += 1
		c.caster.energy += 1  # a rider on a miss: a refund


# The one `missed` hook: every path of cast() that fails runs the skill's behaviours' missed() instead of
# apply() - a missed roll, a lost contest, a chain that hits nothing - and none that lands does.
func test_missed() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	var spy := Miss.new()
	var h: Skill = haluca.duplicate()
	h.behaviours = [spy] as Array[Behaviour]
	learn(v(3), h, 1)
	v(1).wisdom = 1
	v(3).charisma = 60  # it wins: it lands
	contest_total(v(3), h, v(1))
	ok(spy.landed == 1 and spy.missed_on == 0, "a save lost by its foe: apply(), no missed()")
	v(1).wisdom = 60
	v(3).charisma = 1
	var before := v(3).energy
	contest_total(v(3), h, v(1))
	ok(spy.landed == 1 and spy.missed_on == 1 and v(3).energy == before - v(3).price(h) + 1, "a save its foe passes: missed() only, and its refund ran (%d)" % v(3).energy)
	var chain: Skill = strike.duplicate()
	chain.behaviours = [Miss.new()] as Array[Behaviour]
	var hit: Miss = chain.behaviours[0]
	learn(v(3), chain, 1)
	v(1).trinket = null
	v(1).afflict(effect("defense", 500), 9)  # only a natural 20 touches it
	var casts := 0
	for i in 5:
		v(3).refresh()
		casts += int(b.cast(v(3), chain, v(1)))
	ok(casts == 5 and hit.landed + hit.missed_on == 5 and hit.missed_on >= 3, "Strike's chain: a miss runs missed(), a landing apply() (%d landed, %d missed)" % [hit.landed, hit.missed_on])


# Rift's difficulty and turns are rank impact; so is a practised look's rank (Alluring).
func test_rift_look() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(1, 3), v(3): Vector2i(8, 6)})
	var rift := sk("rift")
	v(1).level = 4
	v(1).energy = 99
	learn(v(1), rift, 2)
	ok(b.cast_at(v(1), rift, Vector2i(3, 3), false) and b.pockets[-1].turns == 3, "Rift II unchanneled: 3 x 1.0 turns")
	v(1).trinket = emblem(&"rho_up", &"insignia", 3)  # rank 2 -> 4: difficulty 1.5, ceil(4.5) = 5
	ok("5 turns" in rift.describe(2, v(1)) and "3 turns" in rift.describe(2), "described as held: %s" % rift.describe(2, v(1)))
	v(1).energy = 99
	v(1).refresh()
	var again := b.cast_at(v(1), rift, Vector2i(2, 4), false)
	ok(again and b.pockets[-1].turns == 5, "Density: 5 turns (%s, %d pockets, %d)" % [again, b.pockets.size(), b.pockets[-1].turns])
	var look: Skill = sk("alluring").duplicate()  # not a trait: Density trades on a slotted look (docs/plans/w4-density.md)
	look.tags = look.tags.filter(func(x): return x != &"trait")
	SkillTerms.forget(look)
	v(1).trinket = null
	v(1).extra_dissonance = 20
	learn(v(1), look, 2)
	var plain := v(1).dissonance_penalty()
	v(1).trinket = emblem(&"rho_up", &"badge", 3)
	ok(plain - v(1).dissonance_penalty() == 2 and "counts 4 less" in look.describe(2, v(1)) and "counts 2 less" in look.describe(2),
			"a practised look at rank impact: 4 off, not 2 (%d -> %d)" % [plain, v(1).dissonance_penalty()])


# Strike's element bonus (imbued: the highest mental mod, the first hit) is stat impact.
func test_strike_element() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	learn(v(1), strike, 1)
	v(1).strength = 10
	v(1).intelligence = 20  # +5
	var dealt := func() -> int:
		soak(v(3), 999)
		v(1).imbued = 1
		v(1).element = &"fire"
		v(1).refresh()
		v(3).afflict(effect("defense", -50), 9)  # it hits
		b.rng.seed = 11
		b.cast(v(1), strike, v(3))
		return 999 - v(3).hp
	var plain: int = dealt.call()
	v(1).trinket = emblem(&"sigma_down", &"sigil")  # stat impact x1.75: +5 -> +9
	var dense: int = dealt.call()
	ok(plain > 0 and dense - plain == 4, "Concentrated: the element's mental mod x1.75 (%d -> %d)" % [plain, dense])


# The text of reserves (size, resting rate, a switch's carry), of the tiers a skill opens and of a
# Downed rule reads what the mechanics read: the holder's mod and rank through its modifiers.
func test_reserve_text() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(3, 3)})  # Mana and Stamina each stand in for Energy: one unit has one
	var sweet := sk("sweet_nothings")
	var stamina := sk("stamina")
	var mana := sk("mana")
	var tenacity := sk("tenacity")
	v(1).charisma = 14  # +2
	v(1).constitution = 14
	v(2).constitution = 14
	for s in [sweet, mana, tenacity]:
		v(1).learned.append(slot(s, 2))
	v(2).learned.append(slot(stamina, 2))
	v(1).refresh()
	v(2).refresh()
	v(1).energy = v(1).max_energy
	var kept := v(1).carry(&"energy", mana, 1)
	var plain := {&"sweet": sweet.markup(2, false, v(1)), &"stamina": stamina.markup(2, false, v(2)), &"mana": mana.markup(2, false, v(1)), &"tenacity": tenacity.markup(2, false, v(1))}
	print("POOLS ", v(1).pools()[sweet.reserve], " ", v(2).giver_rank(stamina.reserve), " ", v(1).opened(mana.opens), " ", v(1).charisma)
	ok(v(1).pools()[sweet.reserve] == 4 and v(2).giver_rank(stamina.reserve) == 2 and v(1).opened(mana.opens) == 2, "unmodified: Sweet Nothings 2 x 2, rank 2, tier 2")
	ok("({o:cha mod}) x {r:2}" in plain[&"sweet"] and "T2" in plain[&"mana"] and tenacity.downed.markup(2) in plain[&"tenacity"] and tenacity.downed.markup(2) in tenacity.markup(2), "unmodified text is the base's: %s" % plain[&"sweet"])
	v(1).trinket = emblem(&"rho_up", &"insignia", 1)  # rank impact x1.5: 2 -> 3
	v(2).trinket = v(1).trinket
	var dense := {&"sweet": sweet.markup(2, false, v(1)), &"stamina": stamina.markup(2, false, v(2)), &"mana": mana.markup(2, false, v(1)), &"tenacity": tenacity.markup(2, false, v(1))}
	ok(v(1).pools()[sweet.reserve] == 6 and "x {r:3}" in dense[&"sweet"], "Density: the reserve's size and its text read rank 3 (%s)" % dense[&"sweet"])
	ok(v(2).giver_rank(stamina.reserve) == 3 and "{r:6} more on a turn it rests" in dense[&"stamina"] and "{r:4} more" in plain[&"stamina"], "the resting rate: 2 x rank, mechanic and text (%s)" % dense[&"stamina"])
	ok(kept == floori(v(1).max_energy * 0.2 + 0.0001) and v(1).carry(&"energy", mana, 1) == floori(v(1).max_energy * 0.3 + 0.0001), "a switch carries 10%% x rank of the Energy it leaves: rank 3 under Density (%d -> %d)" % [kept, v(1).carry(&"energy", mana, 1)])
	ok(v(1).opened(mana.opens) == 3 and "{r:T3}" in dense[&"mana"] and "{r:30}%" in dense[&"mana"] and "{r:20}%" in plain[&"mana"], "Mana opens tier 3, and a switch carries 30%% a turn (%s)" % dense[&"mana"])
	ok(tenacity.downed.markup(3) in dense[&"tenacity"] and dense[&"tenacity"] != plain[&"tenacity"], "the Downed rule is described at rank 3, as Downed.takes() reads it")
	v(1).trinket = emblem(&"sigma_down", &"insignia", 1)  # stat impact x1.5: cha mod 2 -> 3
	ok(v(1).pools()[sweet.reserve] == 6 and "{o:1.5 x cha mod}" in sweet.markup(2, false, v(1)), "Concentrated: the mod is 1.5 x, in size and text (%s)" % sweet.markup(2, false, v(1)))
