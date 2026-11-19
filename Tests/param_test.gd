extends Test

# Skills parameterized for modifiers (docs/plans/param.md): each declares its terms (a behaviour's
# terms(), or SkillTerms' reading of its reserve, opens, downed rule or per-stat effect) and reads its
# rank and stats through its holder's modifiers, so at least one modifier fits it and acts on it.

# Every skill parameterized here: eligible for at least one modifier.
const PARAMETERIZED := ["acceptance", "bargaining", "quarry", "survivalist", "wildcaller", "bandwagon", "illusionist",
		"molothrus", "telepathy", "word_to_the_wise", "energize", "heal", "megaheal", "move", "resuscitate", "clairvoyance",
		"manifest", "sweet_nothings", "mana", "grudge", "tenacity",
		"favour", "hazard_expert", "move_plus_one", "magic_slot", "martial_slot", "specialist_slot", "final_act", "gallantry", "stonegift"]


func emblem(word: StringName, scope: StringName, rank := 1) -> Item:
	var it := Item.new()
	it.name = "Test %s %s" % [word, scope]
	it.slot = "trinket"
	it.emblem = word
	it.scope = scope
	it.rank = rank
	return it


func test_eligible() -> void:
	for id in PARAMETERIZED:
		var s: Skill = load("res://Skills/%s.tres" % id)
		var fits := Modifiers.words().filter(func(w: StringName): return Modifiers.eligible(w, s))
		ok(not fits.is_empty() and SkillTerms.of(s).scales(), "%s: eligible for %s" % [id, ", ".join(fits.slice(0, 4))])


# An active's behaviour: Move's tiles are rank impact.
func test_move() -> void:
	var move: Skill = load("res://Skills/move.tres")
	duel(move, 2)
	v(1).trinket = emblem(&"rho_up", &"insignia", 1)  # x1.5: rank II reads as 3
	var before := v(1).move_left()
	ok(b.cast(v(1), move, v(1)) and is_equal_approx(v(1).move_left() - before, 3.0), "Density: Move II gains 3 tiles (%s)" % (v(1).move_left() - before))
	ok(Modifiers.eligible(&"rho_down", move) and not Modifiers.eligible(&"rho_down", load("res://Skills/clairvoyance.tres")), "Diluted fits it (rank impact to tamp, a slot to defend); not Clairvoyance, with no rank impact")


# Heal's caster mod is stat impact.
func test_heal() -> void:
	var heal: Skill = load("res://Skills/heal.tres")
	v(1).learned.append(slot(heal, 1))
	v(1).wisdom = 16  # +3
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	var plain: int = heal.behaviours[0].restores(b.cast_of(v(1), heal, v(2), 1, false))[&"hp"]
	v(1).trinket = emblem(&"sigma_down", &"insignia", 1)  # stat impact x1.5
	var more: int = heal.behaviours[0].restores(b.cast_of(v(1), heal, v(2), 1, false))[&"hp"]
	ok(more - plain == 2, "Concentrated: its wis mod 3 x1.5 -> 5 (%d -> %d)" % [plain, more])


# Clairvoyance's reach: wisdom score and channel rank, both range.
func test_clairvoyance() -> void:
	var cv: Skill = load("res://Skills/clairvoyance.tres")
	v(1).learned.append(slot(cv, 1))
	v(1).wisdom = 4
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 6)})
	v(1).trinket = emblem(&"sigma_up", &"insignia", 1)  # stat range x1.5
	ok(b.cast(v(1), cv, v(1)) and cv.behaviours[0].reach(v(1)) == roundi(4 * 1.5 + 1), "Dispersed: wisdom x1.5 + rank (%d)" % cv.behaviours[0].reach(v(1)))
	v(1).trinket = emblem(&"rho_up", &"insignia", 1)
	ok(not Modifiers.eligible(&"rho_up", cv) and cv.behaviours[0].reach(v(1)) == 5, "Density doesn't fit it (no rank impact): wisdom + rank, unmodified")
	v(1).trinket = emblem(&"rho_down", &"insignia", 1)
	ok(not Modifiers.eligible(&"rho_down", cv) and cv.behaviours[0].reach(v(1)) == 5, "Diluted doesn't fit it either (nothing to tamp: docs/plans/w4-density.md): wisdom + rank, unmodified")


# A passive's hook (Word to the Wise: its wis mod is stat impact) and Unit-side reads (a reserve, Mana's tiers).
func test_passives() -> void:
	var wise: Skill = load("res://Skills/word_to_the_wise.tres")
	var sweet: Skill = load("res://Skills/sweet_nothings.tres")
	var mana: Skill = load("res://Skills/mana.tres")
	v(1).learned.append(slot(wise, 1))
	v(1).learned.append(slot(sweet, 1))
	v(1).wisdom = 16  # +3
	v(2).wisdom = 16
	v(1).charisma = 14  # +2
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	var bh: Behaviour = wise.behaviours[0]
	ok(bh.command_mod(null, v(1), 1, v(2)) == 3 and v(1).pools()[sweet.reserve] == 2, "unmodified: commands by wis mod 3; Sweet Nothings cha mod 2 x I")
	v(1).trinket = emblem(&"sigma_down", &"badge", 1)  # stat impact x(1 + 2/3)
	ok(bh.command_mod(null, v(1), 1, v(2)) == 4 and v(1).pools()[sweet.reserve] == 3, "Concentrated Badge: wis 3 -> min(5, 3 + 1) = 4; Sweet Nothings 2 -> 3 (%d, %d)" % [bh.command_mod(null, v(1), 1, v(2)), v(1).pools()[sweet.reserve]])
	v(1).learned.append(slot(mana, 1))
	v(1).refresh()
	v(1).trinket = emblem(&"rho_up", &"badge", 1)
	ok(v(1).opened(mana.opens) == 2, "Density Badge: Mana I opens up to tier 2 (%d)" % v(1).opened(mana.opens))


# The concrete skills made to scale (docs/plans/w2-param.md), one table: each reads its number off its
# holder at rank I as it always did, at rank II more, and a Density insignia (rank impact x1.5: I reads as II)
# moves rank I the same way.
func test_concrete_scaled() -> void:
	var gal: Skill = load("res://Skills/gallantry.tres")
	var stone: Skill = load("res://Skills/stonegift.tres")
	# id -> [what it reads off a holder with the skill in its first slot, what rank I adds to a holder without it]
	var reads := {
		&"favour": [func(u: Unit): return u.stat(&"luck"), 1.0],
		&"hazard_expert": [func(u: Unit): return u.stat(&"trap_word"), 1.0],
		&"move_plus_one": [func(u: Unit): return u.stat(&"movement"), 1.0],
		&"magic_slot": [func(u: Unit): return u.granted_slots().size(), 1],
		&"martial_slot": [func(u: Unit): return u.granted_slots().size(), 1],
		&"specialist_slot": [func(u: Unit): return u.granted_slots().size(), 1],
		&"stonegift": [func(u: Unit): return stone.lasts(u.learned[0].rank, u), 3],  # absolute: 3 turns at I, as before
		&"final_act": [func(u: Unit): return _free_actions(u), 1],
		&"gallantry": [func(u: Unit): return gal.behaviours[0].check_bonus(u, u.learned[0].rank) - u.mods(gal).check, 0],  # its rank's part (the shift: test_density)
		&"cram": [func(u: Unit): return u.granted_slots().size(), 2],  # 1 + rank caster slots; its converted slots and wear: equip_test.test_cram
	}
	for id in reads:
		var s: Skill = load("res://Skills/%s.tres" % id)
		var read: Callable = reads[id][0]
		var absolute: bool = id in [&"stonegift", &"final_act", &"gallantry"]
		v(1).trinket = null
		v(1).learned.clear()
		v(1).refresh()
		var none = 0 if absolute else read.call(v(1))
		var got := []
		for r in [1, 2]:
			v(1).learned.clear()
			v(1).learned.append(slot(s, r))
			v(1).refresh()
			got.append(read.call(v(1)))
		ok(got[0] - none == reads[id][1], "%s at rank I: %s (as it was)" % [id, reads[id][1]])
		ok(got[1] > got[0], "%s: rank II reads more than rank I (%s -> %s)" % [id, got[0], got[1]])
		v(1).learned.clear()
		v(1).learned.append(slot(s, 1))
		v(1).refresh()
		v(1).trinket = emblem(&"rho_up", &"insignia", 1)
		ok(read.call(v(1)) == got[1], "%s: Density makes rank I read as II (%s)" % [id, read.call(v(1))])
		v(1).trinket = null
	# Favour's mitigation grows with its luck: 1% a rank.
	var tags: Array[StringName] = [&"physical"]
	var mit := []
	for r in [1, 3]:
		v(1).learned.clear()
		v(1).learned.append(slot(favour, r))
		mit.append(v(1).mitigation(tags))
	ok(is_equal_approx(mit[1] - mit[0], 0.02), "Favour III: 2%% more mitigation than I (%s)" % (mit[1] - mit[0]))
	var r := Behaviour.Reaction.new()
	r.battle = b
	r.skill = gal
	ok(r.odds(v(1), &"charisma", v(3), 8) > r.odds(v(1), &"charisma", v(3)), "a reaction's check takes a bonus (Reaction.odds)")
	ok(not gal.markup(1).contains("at +") and gal.markup(2).contains("at +"), "Gallantry's text names its bonus from rank II")


# What a Final Act in u's first slot would give u falling to a blow (Behaviour.react() on a made Reaction).
func _free_actions(u: Unit) -> int:
	var fa: Skill = u.learned[0].skill
	var r := Behaviour.Reaction.new()
	r.battle = b
	r.trigger = &"fallen"
	r.subject = u
	r.skill = fa
	b.directed = func(_x: Unit): return true
	b._interrupts.clear()
	b.interrupter = null
	var n := 0
	if fa.behaviours[0].react(r, u, u.learned[0].rank):
		n = b._interrupt_left if b.interrupter == u else b._interrupts.back()[1]
	b.interrupter = null
	b._interrupts.clear()
	return n


# Density's bargain (docs/plans/w4-density.md): the one rule - rank impact and something to trade against it (a range,
# a check, a slot a foe can disable, a cost) - and what each side trades: Density cuts the whole range and makes every
# check the skill makes harder and its slot easier to disable; Diluted the reverse.
func test_density() -> void:
	var missile: Skill = sk("energy_missile")  # range 4, an attack, dice by rank
	var t := duel(missile, 2)
	v(1).set_equipped([missile])
	var weight := func() -> int: return v(1).slot_weight([missile])
	var plain := [missile.span(v(1)), b.requirement(v(1), missile, t, 2)[0], Battle.hit_chance(v(1), missile, t, b), weight.call()]
	v(1).trinket = emblem(&"rho_up", &"sigil", 1)  # f 0.75: range / 1.75, checks - roundi(5 x 0.75) = 4
	var dense := [missile.span(v(1)), b.requirement(v(1), missile, t, 2)[0], Battle.hit_chance(v(1), missile, t, b), weight.call()]
	ok(is_equal_approx(dense[0], 4.0 / 1.75) and dense[1] == plain[1] - 4 and dense[2] < plain[2] and dense[3] == plain[3] - 4,
			"Density: range 4 -> %s, its attack - 4 (%s -> %s), its slot 4 easier to disable" % [dense[0], plain[2], dense[2]])
	v(1).trinket = emblem(&"rho_down", &"sigil", 1)  # checks + roundi(3 x 0.75) = 2; no rank range, so its range stays
	var thin := [missile.span(v(1)), b.requirement(v(1), missile, t, 2)[0], Battle.hit_chance(v(1), missile, t, b), weight.call()]
	ok(thin[0] == plain[0] and thin[1] == plain[1] + 2 and thin[2] > plain[2] and thin[3] == plain[3] + 2, "Diluted: its attack + 2 (%s), its slot 2 harder to disable" % thin[2])
	var stun := sk("stun")  # its save's DC: rank impact, and the shift (easier to overcome dense)
	v(1).learned.append(slot(stun, 2))
	v(1).trinket = emblem(&"rho_up", &"insignia", 1)  # f 0.5: rank 2 -> 3, checks - roundi(2.5) = 3
	var dc: int = stun.behaviours[0].dc(b.cast_of(v(1), stun, t, 2, false))
	ok(dc == Difficulty.dc(&"difficult", 3) - 3, "Density: Stun's DC at rank 3, less 3 (%d)" % dc)
	# The rule: a trait has no slot to disable, so with no range or check it has nothing to trade; slotted, it does.
	var look: Skill = sk("alluring")
	var slotted: Skill = look.duplicate()
	slotted.tags = look.tags.filter(func(x): return x != &"trait")
	ok(not Modifiers.eligible(&"rho_up", look) and not Modifiers.eligible(&"rho_down", look) and Modifiers.eligible(&"rho_up", slotted) and Modifiers.eligible(&"rho_down", slotted),
			"a trait can't trade (%s); the same skill slotted can" % SkillTerms.of(look).density_why())
	ok(not Modifiers.eligible(&"rho_down", sk("clairvoyance")), "no rank impact, nothing for Diluted to tamp: ineligible both ways")


# Balance knobs (docs/plans/w4-knobs.md), one table: a skill's own coefficient on a channel, the β tags (every channel's
# scaling x1.25 or / 1.25) and the d tags (rank impact reads 1.5 / rank more or less than the rank, nudging early ranks
# most) - what each reads rank I to V as. Then the same through a unit on the three skills that carry one, that they leave
# the price alone and stack with a symbol, who is shown β and d (very high int), and what the check calls a knob that does nothing.
func test_knobs() -> void:
	var rows := [  # [skill's scaling, its tags, channel, rank I-V read as (irank)]
		[{}, [], &"rank_impact", [1, 2, 3, 4, 5]],
		[{&"range": 0.5}, [], &"rank_range", [1, 1, 2, 2, 3]],  # 1, 1, 1.5, 2, 2.5: never below rank I
		[{&"range": 0.5}, [], &"rank_impact", [1, 2, 3, 4, 5]],  # a range coefficient leaves impact alone
		[{&"impact": 2.0}, [], &"rank_impact", [2, 4, 6, 8, 10]],
		[{}, [&"beta_up"], &"rank_impact", [1, 3, 4, 5, 6]],
		[{}, [&"beta_down"], &"rank_range", [1, 2, 2, 3, 4]],
		[{&"impact": 2.0}, [&"beta_up"], &"rank_impact", [3, 5, 8, 10, 13]],  # they multiply: x2.5
		[{}, [&"cohen_up"], &"rank_impact", [3, 3, 4, 4, 5]],  # r + 1.5 / r: 2.5, 2.75, 3.5, 4.4, 5.3
		[{}, [&"cohen_down"], &"rank_impact", [1, 1, 3, 4, 5]],  # r - 1.5 / r: not below rank I
		[{}, [&"cohen_up"], &"rank_range", [1, 2, 3, 4, 5]],  # d is impact alone
	]
	for row in rows:
		var s := Skill.new()
		s.scaling.assign(row[0])
		s.tags.assign(row[1])
		var m := Modifiers.tuned_for(s)
		m = m if m else Modifiers.NONE
		var got := []
		for r in range(1, 6):
			got.append(m.irank(r, row[2]))
		ok(got == row[3], "%s %s on %s: rank I-V read %s (%s)" % [row[0], row[1], row[2], row[3], got])
		if row[0].get(&"range") == 0.5 and row[2] == &"rank_range":
			ok(m.rank(1.0, row[2]) == 1.0 and m.rank(2.0, row[2]) == 1.0 and m.rank(3.0, row[2]) == 1.5, "a weaker coefficient never reads below rank I: 1, 1, 1.5")
	var s := Skill.new()
	s.scaling.assign({&"modified": 0.5})
	ok(Modifiers.tuned_for(s).stat(3, &"stat_impact") == 2 and Modifiers.tuned_for(s).stat(3, &"stat_range") == 2 and Modifiers.tuned_for(s).stat(3, &"rank_impact") == 3, "modified: both stat channels, a mod of 3 reads 2")
	# Through a unit, on the three that carry one: Kick's reach (range x0.5), Gank's dice (beta up), Spike's rank (d up).
	var kick := sk("kick")
	var gank := sk("gank")
	var spike := sk("spike")
	duel(kick, 3)
	ok(kick.span(v(1)) == 1.5 and SkillTerms.of(kick).knobs != null, "Kick III reaches 1.5 tiles, not 3 (%s)" % kick.span(v(1)))
	ok(v(1).mods(gank).irank(2, &"rank_impact") == 3 and v(1).mods(spike).irank(1, &"rank_impact") == 3 and v(1).mods(spike).irank(5, &"rank_impact") == 5, "Gank II rolls 3 dice, Spike I reads as III and V as itself")
	ok(v(1).mods(gank).empty() and v(1).mods(gank).label() == "" and v(1).mods(gank).tuned, "a knob is not a modifier: no label, no symbol shown")
	var steep := sk("sutemi").duplicate()  # a priced skill (the cost calculator reads its rank): β makes it no dearer at rank III
	steep.tags = steep.tags.duplicate()
	steep.tags.append(&"beta_up")
	ok(steep.priced() and Pricing.ap_at(v(1), steep, 3) == Pricing.ap_at(v(1), sk("sutemi"), 3) and Pricing.cost_at(v(1), steep, 3) == Pricing.cost_at(v(1), sk("sutemi"), 3), "a knob doesn't change the price (%s AP)" % Pricing.ap_at(v(1), steep, 3))
	ok(v(1).mods(gank).priced().k[&"rank_impact"] == 1.0 and not v(1).mods(gank).priced().tuned, "priced() reads a skill without its knobs")
	v(1).trinket = emblem(&"rho_up", &"insignia", 1)  # f 0.5: x1.5 on top of x1.25
	var dense := v(1).mods(gank)
	ok(is_equal_approx(dense.k[&"rank_impact"], 1.5 * 1.25) and dense.label() == "ρ↑" and dense.tuned, "a symbol stacks with it, and alone is what's shown (%s)" % dense.label())
	v(1).trinket = null
	# Whom they're shown to: very high int only; the others see the numbers, never the tag.
	v(1).intelligence = Modifiers.VERY_HIGH_INT
	v(3).intelligence = Modifiers.VERY_HIGH_INT - 1
	v(1).refresh()
	v(3).refresh()
	ok(Modifiers.sees_knobs(v(1)) and not Modifiers.sees_knobs(v(3)) and not Modifiers.sees_knobs(null), "int 16 sees them, 15 doesn't, nobody doesn't")
	ok("β+" in gank.describe(1, v(1)) and "β+" not in gank.describe(1, v(3)) and "β+" not in gank.describe(1), "Gank's tooltip carries its β tag for very high int alone (%s)" % gank.describe(1, v(1)).right(60))
	ok("d+" in spike.describe(1, v(1)) and "d+" not in spike.describe(1, v(3)), "Spike's carries d+")
	# What the check calls a knob that does nothing (skill.py check).
	var bad := sk("clairvoyance").duplicate()  # no rank impact: nothing for d or an impact coefficient to tune
	bad.scaling = bad.scaling.duplicate()  # a duplicate shares its dictionary and tags
	bad.tags = bad.tags.duplicate()
	bad.scaling.assign({&"impact": 2.0, &"range": 1.0, &"made_up": 2.0})
	bad.tags.append_array([&"cohen_up", &"cohen_down", &"beta_up"])
	SkillTerms.forget(bad)
	var said := " | ".join(SkillTerms.of(bad).knob_problems(bad))
	ok("no impact scaling" in said and "not 1" in said and "no coefficient" in said and "both cohen_up and cohen_down" in said and "no rank impact" in said, "knob_problems(): %s" % said)
	ok(SkillTerms.of(kick).knob_problems(kick).is_empty() and SkillTerms.of(gank).knob_problems(gank).is_empty() and SkillTerms.of(spike).knob_problems(spike).is_empty(), "the three sound")
