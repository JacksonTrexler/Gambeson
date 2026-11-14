extends Test

# The general trees (Unit.general_trees(), Unit._general_need(): which a class gets, their tier gates,
# Generalist / Martialist / Thaumaturgist waivers and what lapses without them, Foundations), and
# Strike's chain and upgrades (Battle._chain()).

var roles := {}


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func unit_of(role: String) -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/%s.tres" % role), name = role})
	b.get_node("Units").add_child(u)
	return u


func names(u: Unit) -> Array:
	return u.general_trees().map(func(t: SkillTab): return t.name)


func test_trees_by_class() -> void:
	ok(names(unit_of("adventurer")) == ["General", "Martial", "Specialist", "Caster"], "an Adventurer: all three, and the base")
	ok(names(unit_of("rogue")) == ["General", "Specialist"], "a Rogue: Specialist")
	ok(names(unit_of("paladin")) == ["General", "Martial", "Caster"], "a Paladin: Martial and Caster")
	ok(unit_of("cleric").tier(sk("strike")) == 0 and sk("strike") in unit_of("wizard").actives, "Strike: tier 0 on the General tree, every class has it")


func test_base_gate() -> void:
	var u := unit_of("adventurer")
	u.skill_points = 30
	ok(u.missing(sk("strike_bang")).begins_with("Needs 3 T7+ skills"), u.missing(sk("strike_bang")))
	ok(u.missing(sk("generalist")) == "Needs 3 T1+ skills (0 so far)", "Generalist: tier 1, needing 3 of that tier or more (%s)" % u.missing(sk("generalist")))
	for s in ["hex", "sola", "snare"]:
		u.unlock(sk(s))
	ok(u.missing(sk("generalist")) == "" and u.unlock(sk("generalist")), "three tier-1 skills: Generalist opens")
	u.skill_points = 500
	for i in 6:
		u.raise(sk("generalist"))
	ok(u.base_rank(sk("generalist")) == 7 and u.missing(sk("strike_bang")) == "", "Generalist VII waives tier 7: Strike! is high tier")
	ok(u.unlock(sk("strike_bang")) and u.waived.get(sk("strike_bang")) == sk("generalist"), "learned through it")
	u.disable(sk("generalist"), 2)
	ok(u.lapsed(sk("strike_bang")) and sk("strike_bang") not in u.passives, "Generalist disabled: Strike! stops working")


func test_category_gate() -> void:
	var u := unit_of("rogue")
	u.skill_points = 30
	ok(u.missing(sk("striking_features")).begins_with("Needs a T4+ specialist class skill"), u.missing(sk("striking_features")))
	ok(u.missing(sk("brutal_strike")) == "" or sk("brutal_strike") not in u.general_skills(), "the Martial tree isn't a Rogue's")
	ok(sk("brutal_strike") not in u.general_skills(), "not shown")
	for s in ["hide", "meander", "snare"]:
		u.unlock(sk(s))
	ok(u.unlock(sk("martialist")) and "Martial" in names(u), "Martialist: the Martial tree shows")
	ok(u.missing(sk("brutal_strike")) == "" and u.missing(sk("strike_out")) != "", "a Rogue, a specialist: rank I - 1 + 2 reaches tier 2 already")
	u.raise(sk("martialist"))
	u.raise(sk("martialist"))
	ok(u.missing(sk("strike_out")) == "", "rank III: tier 4")
	var f := unit_of("fighter")
	f.skill_points = 30
	for s in ["wary"]:
		f.unlock(sk(s))
	f.learned.append_array([slot(sk("snare")), slot(sk("hide")), slot(sk("journeyman"), 3)])
	ok("Specialist" in names(f) and f.missing(sk("synergy")) == "" and f.missing(sk("striking_features")) != "", "a Fighter's Journeyman III: the Specialist tree, up to tier 2")
	var c := unit_of("cleric")
	c.skill_points = 5
	c.pick(c.role.choices[0], God.of(&"luun").own)
	c.unlock(sk("level_down"))
	ok(c.missing(sk("elemental_strike")) == "", "a Cleric's Luun skill (tier 2) opens Caster tier 2")


func test_exclusive() -> void:
	var u := unit_of("adventurer")
	u.learned.append(slot(sk("decisive_strike")))
	ok(u.missing(sk("brutal_strike")) == "Not with Decisive Strike" and u.missing(sk("elemental_strike")) == "Not with Decisive Strike", "one low-tier Strike upgrade")
	ok(u.skill_name(sk("strike")) == "Decisive Strike", "Strike goes by its name")


func test_foundation() -> void:
	v(1).learned.append(slot(sk("generalist"), 4))
	ok(sk("generalist").pillar() and sk("generalist").foundation(), "a Foundation is a Pillar")
	var order := v(1).disable_order()
	ok(order.size() > 2 and order[2] == [sk("generalist")], "rank IV: two slots in from the right (%s)" % [order.map(func(g): return g.map(func(s: Skill): return s.name))])


# A Strike chain from v(1) at v(3), every roll a hit: str 18 (+4) against Defense 2, hits rolled from 11
# up (b.rng seeded for it: the first hits all land).
func strike_at(r: int) -> Array:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).strength = 30  # mod 10: nothing misses Defense 2
	v(1).learned.append(slot(strike, r))
	v(3).max_hp = 500
	v(3).hp = 500
	var dealt := []
	v(3).hp_changed.connect(func(was: int, now: int): dealt.append(was - now))
	v(1).refresh()
	var rolls := []
	b.attacked.connect(func(_c, _t, d20: int, _total, _def): rolls.append(d20))
	b.cast(v(1), strike, v(3))
	return [dealt, rolls]


func test_chain() -> void:
	var got := strike_at(3)
	ok(got[1].size() == 3, "a roll a hit")
	ok(got[0][0] - got[0][1] == 1 or got[1][0] == 20 or got[1][1] == 20, "each hit in a row: 1 less damage (%s)" % [got[0]])
	ok("Attacks cease on a miss" in strike.describe(1), strike.describe(1))


func test_strike_out() -> void:
	v(1).learned.append(slot(sk("strike_out"), 3))
	var got := strike_at(3)
	ok(got[0].size() == 3 and (got[0][0] == got[0][2] or got[1].has(20)), "Strike Out: no penalty (%s)" % [got[0]])


func test_brutal() -> void:
	v(1).learned.append(slot(sk("brutal_strike"), 2))
	v(1).weapon = load("res://Items/broadsword.tres")
	var got := strike_at(3)
	ok(got[1].size() == 1, "Brutal Strike: a single attack")
	ok(got[0][0] == 1 + 10 + 1 + 2 or got[1][0] == 20, "+ the weapon's rank (1) + rank (2): %s" % [got[0]])


func test_features() -> void:
	v(1).learned.append(slot(sk("striking_features"), 1))
	v(1).charisma = 16
	var got := strike_at(2)
	ok(got[0][0] == 11 + 1 or got[1][0] == 20, "Striking Features I: + cha mod, up to 1, on the first hit (%s)" % [got[0]])


func test_record() -> void:
	v(1).learned.append(slot(sk("record_striker"), 1))
	v(1).intelligence = 40
	v(3).wisdom = 1
	var first: Skill = v(3).hotbar[0]
	var before := v(3).rank(first)
	strike_at(1)
	ok(v(3).rank(first) == before - 1, "Record Striker: the leftmost skill a rank down (%s %d -> %d)" % [first.name, before, v(3).rank(first)])


func test_strike_bang() -> void:
	v(1).learned.append(slot(sk("strike_bang"), 2))
	v(1).learned.append(slot(sk("strike_out"), 20))  # nothing stops the chain
	var got := strike_at(12)
	ok(got[1].size() >= 12 + 13, "12 hits landed: it strikes again at once, with 1 more - and that use can too, up to 3 times (%d rolls)" % got[1].size())


func test_perfect() -> void:
	v(1).learned.append(slot(sk("strike_bang"), 1))
	v(1).learned.append(slot(sk("strike_out"), 50))
	var perfect := []
	b.perfect.connect(func(u: Unit): perfect.append(u))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).strength = 10
	v(1).learned.append(slot(strike, 12))
	v(3).max_hp = 5000
	v(3).hp = 5000
	v(1).max_hp = 400
	v(1).hp = 50
	v(1).refresh()
	b.cast(v(1), strike, v(3))
	ok(perfect == [v(1)] and v(1).hp == 350, "36 in a row: a Perfect, 300 healed (%d)" % v(1).hp)


func test_elemental() -> void:
	v(1).learned.append(slot(sk("elemental_strike"), 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(1).element = &"fire"
	ok(b.cast(v(1), sk("elemental_strike"), v(1)) and v(1).imbued == 2 and v(1).skill_name(strike) == "Firestrike", "imbued: Firestrike for 2 uses")
	v(3).max_hp = 500
	v(3).hp = 500
	v(1).strength = 30
	b.cast(v(1), strike, v(3))
	ok(v(1).imbued == 1, "a use spent")
	v(1).imbued = 0
	v(1).learned.append(slot(sk("elemental_mastery")))
	v(1).element = &""
	v(1).god = &"luun"
	ok(sk("elemental_mastery") in v(1).passives and v(1).stat(&"elemental") > 0.0 and v(1).skill_name(strike) == "Strike",
			"Elemental Mastery: Strike always carries an element (its god's, else fire) without being renamed")
