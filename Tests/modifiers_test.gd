extends Test

# Skill modifiers (docs/plans/skill-modifiers.md): skill terms (SkillTerms), the cost calculator
# (Pricing), modifiers and their eligibility (Modifiers), !RSC, and emblems (Item.emblem, scope).

var stoneskin: Skill = load("res://Skills/stoneskin.tres")
var hide: Skill = load("res://Skills/hide.tres")


# A skill scaling every way: range 1 + rank + int mod, turns rank + cha mod, damage d6 + int mod.
func scaler() -> Skill:
	var s := Skill.new()
	s.name = "Scaler"
	s.ap = 4.0
	s.cost = 4
	s.tags = [&"magical"]
	s.radius = 1.0
	s.radius_per_rank = 1.0
	s.radius_mod = &"intelligence"
	s.turns_per_rank = 1
	s.turns_mod = &"charisma"
	var t := Tier.new()
	t.dice = Vector2i(1, 6)
	t.stat = &"intelligence"
	s.tiers = [t]
	s.effects = [effect("luck", -1)]
	return s


func emblem(word: StringName, scope: StringName, rank := 1) -> Item:
	var it := Item.new()
	it.name = "Test %s %s" % [word, scope]
	it.slot = "trinket"
	it.emblem = word
	it.scope = scope
	it.rank = rank
	return it


func test_rsc() -> void:
	ok(is_equal_approx(Modifiers.rsc(1, &"one"), 0.75) and is_equal_approx(Modifiers.rsc(1, &"some"), 2.0 / 3.0) and is_equal_approx(Modifiers.rsc(1, &"all"), 0.5),
			"!RSC at rank I: one skill (2+r)/(3+r) 0.75, some (1+r)/(2+r) 0.67, all r/(1+r) 0.5")
	ok(Modifiers.rsc(3, &"one") > Modifiers.rsc(3, &"some") and Modifiers.rsc(3, &"some") > Modifiers.rsc(3, &"all"), "the fewer skills it reaches, the less it loses")
	ok(Modifiers.rsc(50, &"all") < 1.0 and Modifiers.rsc(50, &"all") > 0.97 and Modifiers.rsc(5, &"all") > Modifiers.rsc(1, &"all"), "it grows with rank and approaches 1: a boost approaching x2")
	var m := Modifiers.new()
	m.add(&"rho_up", 1, &"one")
	m.add(&"rho_up", 1, &"all")
	ok(is_equal_approx(m.k[&"rank_impact"], 1.75 * 1.5), "two on one skill multiply: %s" % m.k[&"rank_impact"])


func test_terms() -> void:
	var s := scaler()
	var t := SkillTerms.of(s)
	ok(t.has(&"rank_range") and t.has(&"rank_impact") and t.has(&"stat_range") and t.has(&"stat_impact"), "derived from its fields: all four channels %s" % [t.channels])
	ok(t.intensity == &"mild" and t.damage and t.check and t.impact == &"tame", "d6: mild (the user's moderate low); it attacks; its effect is tame")
	ok(SkillTerms.INTENSITY[&"extreme"] == &"severe" and SkillTerms.INTENSITY[&"low"] == &"faint", "the user's intensities on Difficulty.MAGNITUDE")
	var ts := SkillTerms.of(stoneskin)
	ok(ts.beneficial_contingency() and is_equal_approx(ts.contingencies[0][1], 0.15), "Stoneskin's above 85% HP is a contingency, share 0.15")
	var kick: Skill = load("res://Skills/kick.tres")
	ok("push" in SkillTerms.of(kick).channels[&"rank_impact"], "a behaviour declares its own terms (Kick's push)")


func test_cost() -> void:
	var weak := Skill.new()
	var t := Tier.new()
	t.dice = Vector2i(1, 4)
	weak.tiers = [t]
	weak.radius = 3.0
	var hard := weak.duplicate()
	hard.intensity = &"severe"
	var wild := weak.duplicate()
	wild.intensity = &"overwhelming"
	var a := Pricing.points(weak, 1)
	var b2 := Pricing.points(hard, 1)
	var c := Pricing.points(wild, 1)
	var mild := weak.duplicate()
	mild.intensity = &"mild"
	ok(b2 > a and c - b2 > Pricing.points(mild, 1) - a, "damage is the base cost, each rung costing more toward the extremes: %s %s %s" % [a, b2, c])
	var ranked := hard.duplicate()
	ranked.roll_per_rank = 1
	ok(Pricing.points(ranked, 3) - Pricing.points(ranked, 1) == 2.0 * Pricing.TABLE[&"hit_rank"], "+ rank to hit costs per rank")
	var close := hard.duplicate()
	close.radius = 1.0
	ok(Pricing.points(close, 1) == b2 - Pricing.TABLE[&"adjacent"], "adjacent is cheaper")
	var far := hard.duplicate()
	far.radius_per_rank = 2.0
	ok(Pricing.points(far, 3) == b2, "rank range is neutral")
	var bad := hard.duplicate()
	bad.penalty = &"severe"
	var worse := hard.duplicate()
	worse.intensity = &"overwhelming"
	worse.penalty = &"severe"
	ok(b2 - Pricing.points(bad, 1) == 3.0 and c - Pricing.points(worse, 1) == 3.0, "a penalty takes off a flat amount, even at the extreme")
	var odd := hard.duplicate()
	odd.impact = &"impactful"
	var picky := odd.duplicate()
	picky.requires = Requirement.new()
	picky.requires.test = &"hp_below"
	picky.requires.share = 0.1
	ok(Pricing.points(odd, 1) > Pricing.points(picky, 1) and Pricing.points(picky, 1) > b2, "a unique effect costs, tapered by a hard requirement")
	var tame := odd.duplicate()
	tame.impact = &"tame"
	ok(Pricing.points(odd, 1) > Pricing.points(tame, 1), "impactful costs more than tame")


func test_priced() -> void:
	var s := scaler()
	s.priced = true
	s.roll_per_rank = 1
	var hand := scaler()
	hand.roll_per_rank = 1
	v(1).learned.append(slot(s, 2))
	v(1).learned.append(slot(hand, 2))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	ok(v(1).price(s) == Pricing.energy(s, 2) and is_equal_approx(v(1).ap_cost(s, null), Pricing.ap(s, 2)), "a priced skill costs the calculator's price")
	ok(v(1).price(hand) == 4 and v(1).ap_cost(hand, null) == 4.0, "a hand-priced one keeps its own")
	v(1).trinket = emblem(&"rho_down", &"insignia", 3)
	ok(v(1).price(hand) < 4 and v(1).price(s) <= Pricing.energy(s, 2), "modifiers change the price of both: Diluted nullifies its rank impact (%d)" % v(1).price(hand))
	ok(Pricing.points(s, 2, v(1).mods(s)) < Pricing.points(s, 2), "...so it comes to fewer points")


func test_eligibility() -> void:
	var s := scaler()
	ok(Modifiers.eligible(&"fire", s) and not Modifiers.eligible(&"fire", hide), "a damage tag needs damage")
	ok(Modifiers.eligible(&"execute", s) and Modifiers.eligible(&"taps", s) and not Modifiers.eligible(&"execute", stoneskin), "a check tag needs a check")
	ok(not Modifiers.eligible(&"magical", s), "not a tag it has already")
	ok(not Modifiers.eligible(&"foe", s) and not Modifiers.eligible(&"standard", s) and not Modifiers.eligible(&"nonsense", s), "never a target word, a difficulty, or a word the Glossary doesn't know")
	ok(Modifiers.eligible(&"rho_up", s) and Modifiers.eligible(&"sigma_up", s), "symbols need the channel they boost")
	ok(not Modifiers.eligible(&"rho_up", Skill.new()) and not Modifiers.eligible(&"lambda_up", s), "...and lambda a contingency that helps")
	ok(Modifiers.eligible(&"rho_up", hide), "Hide's per-rank effect is rank impact")
	ok(Modifiers.eligible(&"lambda_down", stoneskin), "Stoneskin's HP threshold is one")


func test_symbols() -> void:
	var s := scaler()
	v(1).learned.append(slot(s, 2))
	v(1).intelligence = 16  # +3
	v(1).charisma = 14  # +2
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	v(1).hotbar.assign([s])  # a Sigil's skill: the leftmost it fits
	var r := v(1).rank(s)
	ok(s.span(v(1)) == 1 + 2 + 3 and s.lasts(r, v(1)) == 2 + 2, "unmodified: range 1 + rank + int mod, turns rank + cha mod")
	v(1).trinket = emblem(&"rho_up", &"sigil", 1)  # x1.75
	ok(s.span(v(1)) == 1 + 1 + 3 and s.lasts(r, v(1)) == roundi(2 * 1.75) + 2 and v(1).mods(s).label() == "ρ↑", "Density: rank range as at rank I, rank impact x1.75")
	v(1).trinket = emblem(&"rho_down", &"sigil", 1)
	ok(s.span(v(1)) == 1 + 2 * 1.75 + 3 and s.lasts(r, v(1)) == 1 + 2, "Diluted: rank impact as at rank I, rank range x1.75")
	v(1).trinket = emblem(&"sigma_down", &"sigil", 1)
	ok(s.span(v(1)) == 1 + 2 and s.lasts(r, v(1)) == 2 + roundi(2 * 1.75), "Concentrated: stat range nullified, stat impact x1.75")
	v(1).trinket = emblem(&"sigma_up", &"sigil", 1)
	ok(s.span(v(1)) == 1 + 2 + roundi(3 * 1.75) and s.lasts(r, v(1)) == 2, "Dispersed: stat impact nullified, stat range x1.75")
	v(1).trinket = null
	v(1).learned.append(slot(stoneskin, 1))
	v(1).max_hp = 100
	v(1).hp = 80
	ok(is_zero_approx(v(1).stat(&"mitigate")), "Stoneskin is off at 80% HP (above 85% only)")
	v(1).trinket = emblem(&"lambda_down", &"insignia", 1)  # f 0.5: share 0.15^(1/1.5) = 0.28, so above 72%; 0.4 / 1.5
	ok(is_equal_approx(v(1).stat(&"mitigate"), 0.4 / 1.5), "Unrestrictive: on at 80%% now, at a weaker 0.27 (%s)" % v(1).stat(&"mitigate"))
	v(1).hp = 100
	v(1).trinket = emblem(&"lambda_up", &"insignia", 1)
	ok(is_equal_approx(v(1).stat(&"mitigate"), 0.4 * 1.5), "Restrictive: stronger, 0.6")
	v(1).hp = 93
	ok(is_zero_approx(v(1).stat(&"mitigate")), "...but off at 93%: 0.15^1.5 = 6%, so above 94% only")


func test_requirement() -> void:
	var s := scaler()
	s.requires = Requirement.new()
	s.requires.test = &"energy_above"
	s.requires.share = 0.2  # at least 80% Energy
	s.requires.hit = 2
	v(1).learned.append(slot(s, 1))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	v(1).hotbar.assign([s])
	v(1).max_energy = 100
	v(1).energy = 90
	ok(b.requirement(v(1), s, v(3), 1) == [2, 0, 0], "met at 90% Energy: +2 to hit")
	v(1).trinket = emblem(&"lambda_up", &"sigil", 3)  # f 5/6: share 0.2^1.83 = 5%, so 95% Energy (the user's example)
	ok(b.requirement(v(1), s, v(3), 1) == [0, 0, 0], "Restrictive: 90% is no longer enough")
	v(1).energy = 96
	ok(b.requirement(v(1), s, v(3), 1) == [4, 0, 0], "at 96%% it's met, and the payoff is x1.83: +4 (%s)" % [b.requirement(v(1), s, v(3), 1)])
	v(1).trinket = emblem(&"lambda_down", &"sigil", 3)
	v(1).energy = 60
	ok(b.requirement(v(1), s, v(3), 1) == [1, 0, 0], "Unrestrictive: met at 60%% (0.2^(1/1.83) = 42%%), +2 / 1.83 = +1 (%s)" % [b.requirement(v(1), s, v(3), 1)])


func test_emblem_scopes() -> void:
	var a := scaler()
	var c := scaler()
	v(1).learned.append(slot(a, 1))
	v(1).learned.append(slot(c, 1))
	v(1).learned.append(slot(stoneskin, 1))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	var plain := Skill.new()
	plain.name = "Plain"
	v(1).hotbar.assign([plain, c, a])
	v(1).trinket = emblem(&"rho_up", &"sigil")
	ok(v(1).mods(c).label() == "ρ↑" and v(1).mods(a).empty() and v(1).mods(plain).empty(), "a Sigil: the leftmost eligible skill on the hotbar (Plain scales by nothing): %s / %s / %s" % [v(1).mods(plain).label(), v(1).mods(c).label(), v(1).mods(a).label()])
	v(1).trinket = emblem(&"fire", &"insignia")
	ok(&"fire" in v(1).skill_tags(a) and &"fire" in v(1).skill_tags(c) and &"fire" not in v(1).skill_tags(hide), "an Insignia: every skill it fits")
	v(1).trinket = emblem(&"lambda_up", &"badge")
	ok(not v(1).mods(stoneskin).empty() and v(1).mods(a).empty(), "a Badge: passives")
	v(1).trinket = emblem(&"rho_up", &"crest")
	ok(not v(1).mods(a).empty() and not v(1).mods(c).empty(), "a Crest: actives")
	var made: Item = load("res://Items/fire_insignia.tres")
	ok(made.emblem == &"fire" and made.scope == &"insignia" and made.slot == "trinket" and "Puts fire on every skill it fits" in made.describe(), made.describe())
	ok(made.trim() == Tags.color(&"fire") and made.trim_tag() == &"fire", "its trim is fire's, not its form word's (Tags.PLAIN)")
	for f in ["density_sigil", "diluted_sigil", "concentrated_crest", "dispersed_crest", "restrictive_badge", "unrestrictive_insignia", "execute_sigil"]:
		var it: Item = load("res://Items/%s.tres" % f)
		ok(it.trim_tag() == it.emblem and it.trim() == Tags.color(it.emblem) and it.emblem in Tags.COLOR, "%s: trimmed in its modifier's colour (%s)" % [it.name, it.trim_tag()])
	var loot: Loot = load("res://Loot/alabaster.tres")
	ok(loot.items.any(func(it: Item): return it.name == "Execute Sigil") and loot.items.filter(func(it: Item): return it.emblem in Modifiers.SYMBOLS).size() == 6, "in loot: every symbol, the Fire Insignia, the Execute Sigil")


func test_tags_everywhere() -> void:
	var haluca: Skill = load("res://Skills/haluca.tres")
	v(1).learned.append(slot(strike, 1))
	v(1).learned.append(slot(haluca, 2))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).trinket = load("res://Items/fire_insignia.tres")
	ok(&"fire" in Battle.hit_tags(v(1), strike) and v(1).has_tag(&"fire"), "Fire Insignia: Strike's blows are fire, and its holder carries fire to whatever asks")
	v(1).afflict(effect("damage", 0.5, [&"fire"]), 3)
	ok(is_equal_approx(v(1).skill_stat(&"damage", strike), 0.5), "effects keyed on fire reach its skills")
	v(1).trinket = load("res://Items/execute_sigil.tres")
	v(1).hotbar.assign([haluca, strike])
	v(3).max_hp = 100
	v(3).hp = 10
	ok(&"execute" in v(1).skill_tags(haluca) and is_equal_approx(Battle.executed(v(3), v(1).skill_tags(haluca), 2), 0.05), "Execute Sigil: Haluca's save is an execute (its leftmost eligible: a save)")
	var bless := effect("check", 3, [&"execute"])
	bless.kind = &"defensive"
	v(3).afflict(bless, 3)
	ok(v(3).check_mod(&"wisdom", &"defensive", v(1).skill_tags(haluca)) == v(3).check_mod(&"wisdom", &"defensive") + 3, "and what helps against executes helps against it")


# A tag the Glossary gains later works with no code: a throwaway damage tag.
func test_throwaway_tag() -> void:
	Glossary.added[&"zz_acid"] = ["Acid ??", &"damage", "A test's throwaway."]
	var s := scaler()
	v(1).learned.append(slot(s, 1))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).trinket = emblem(&"zz_acid", &"insignia")
	ok(Modifiers.eligible(&"zz_acid", s) and not Modifiers.eligible(&"zz_acid", hide), "its kind decides: damage")
	ok(&"zz_acid" in Battle.hit_tags(v(1), s) and v(1).has_tag(&"zz_acid") and v(1).mods(s).label() == "zz_acid", "it lands on the skill's hits")
	v(3).afflict(effect("mitigate", 1.0, [&"zz_acid"]), 3)
	var before := v(3).hp
	v(3).hit(5, Battle.hit_tags(v(1), s), v(1))
	ok(v(3).hp == before, "and what resists it resists the skill")
	Glossary.added.erase(&"zz_acid")
