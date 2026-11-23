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
	return roomy(u, 8)


func names(u: Unit) -> Array:
	return u.general_trees().map(func(t: SkillTab): return t.name)


func test_trees_by_class() -> void:
	for f in DirAccess.get_files_at("res://Roles"):
		if f.ends_with(".tres") and (load("res://Roles/" + f) as Role).has_tree():
			var u := unit_of(f.get_basename())
			var got := u.general_trees()
			ok(got[0].key() == &"" and got.size() == 1 + u.role.general.size() and got.slice(1).all(func(g: SkillTab): return g.key() in u.role.general),
					"%s: the base tree and one for each general tree it declares, a category or a grant key (%s)" % [f.get_basename(), names(u)])
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
	f.learned.append_array([slot(sk("snare")), slot(sk("hide")), slot(sk("journeyman"), 3)]); f.sync_bar()
	ok("Specialist" in names(f) and f.missing(sk("synergy")) == "" and f.missing(sk("striking_features")) != "", "a Fighter's Journeyman III: the Specialist tree, up to tier 2")
	var c := unit_of("cleric")
	c.skill_points = 5
	c.pick(c.role.choices[0], God.of(&"luun").own)
	c.unlock(sk("level_down"))
	ok(c.missing(sk("elemental_strike")) == "", "a Cleric's Luun skill (tier 2) opens Caster tier 2")


# Tree composition (SkillRoot.includes): a root's included trees show as its own, with their tiers and prerequisites,
# nothing copied; a loop ends rather than hangs. No general tree includes one now (the Mage's Student is a tab of its
# own, below), so it is tried on roots in memory. The tools' checks police the data (role.py, skill.py check).
func test_included_trees() -> void:
	var student: SkillRoot = load("res://Trees/student.tres")
	var discipline := sk("discipline")
	var kick := sk("kick")
	var put := Branch.new()
	put.skill = kick
	put.tier = 7
	var into := SkillRoot.new()
	into.includes = [student]
	ok(into.branch(discipline) == student.branch(discipline) and into.source(discipline) == student and discipline.kinds() == [&"specialist"], "an included tree's skill shows as its own, from its branch, and keeps its own tree's kind (specialist)")
	student.branches.append(put)
	ok(into.branch(kick) == put and into.skills().has(kick), "a skill put on the included tree is there")
	student.branches.erase(put)
	ok(not into.skills().has(kick), "taken off, gone")
	var a := SkillRoot.new()
	var c := SkillRoot.new()
	a.includes = [c]
	c.includes = [a]
	c.branches.append(put)
	ok(a.skills() == [kick] and c.skills() == [kick] and a.source(kick) == c and a.source(discipline) == null, "a loop of included trees ends (and the tools refuse one)")


# Student is the Mage's (a tab of its own, Role.general key student), no other caster's; Journeyman is the martial and
# specialist classes'. Any other class gets one granted (Unit.grant_tree(): an adventure's reward, or a flex choice's pick).
func test_granted_trees() -> void:
	var discipline := sk("discipline")
	var cram := sk("cram")
	var mage := unit_of("mage")
	ok(names(mage) == ["General", "Caster", "Student"] and cram in mage.general_skills() and discipline in mage.general_skills(), "a Mage: the Caster tree and Student's (%s)" % [names(mage)])
	ok(not sk("cram") in load("res://Trees/general_caster.tres").roots[0].skills() and not "Student" in names(unit_of("wizard")) and not cram in unit_of("wizard").general_skills(), "the Caster tree has no Student: a Wizard hasn't it")
	ok("Journeyman" in names(unit_of("fighter")) and "Journeyman" in names(unit_of("rogue")) and not "Journeyman" in names(unit_of("wizard")), "Journeyman: martial and specialist classes, not casters")
	var f := unit_of("fighter")
	ok(not cram in f.general_skills() and f.grant_tree(&"student") and not f.grant_tree(&"student") and not f.grant_tree(&"nonsense") and cram in f.general_skills() and f.tier(cram) == 7, "a Fighter granted Student has it at its tiers, once; an unknown key grants nothing")
	ok(f.missing(cram).begins_with("Needs a T7+ caster class skill") and f.role.vigor_per_level() == 3 and unit_of("adventurer").role.vigor_per_level() == 2, "its caster gate stays; a grant key isn't a category for vigor")
	ok(discipline.kinds() == [&"specialist"] and cram.kinds() == [&"specialist"], "Student's skills keep its root's kind on its tab")


# Flex trees (Unit.flex_choice()): one per Role.flex_every levels, its class's Role.flex (every one for a jack,
# none it has natively), picked through Unit.pick() into its general trees. A row: class, level, slots, offered.
func test_flex_cadence() -> void:
	for row in [["fighter", 10, 1, []], ["paladin", 9, 0, ["Scout"]], ["paladin", 20, 2, ["Scout"]], ["rogue", 5, 1, ["Scout"]],
			["rogue", 20, 4, ["Scout"]], ["bard", 4, 0, ["Student"]], ["bard", 15, 3, ["Student"]], ["adventurer", 3, 1, ["Student", "Scout"]],
			["adventurer", 18, 6, ["Student", "Scout"]], ["ranger", 20, 2, []], ["mage", 10, 1, []]]:
		var u := unit_of(row[0])
		u.level = row[1]
		ok(u.flex_slots() == row[2] and u.flex_options().map(func(t: SkillTab): return t.name) == row[3],
				"%s at level %d: %d flex trees of %s (%d of %s)" % [row[0], row[1], row[2], row[3], u.flex_slots(), u.flex_options().map(func(t: SkillTab): return t.name)])
	var p := unit_of("paladin")
	var scout: SkillTab = p.flex_options()[0]
	p.level = 9
	var c := p.flex_choice()
	ok(not p.pick(c, scout) and p.pick_missing(c, scout) == "Next at level 10" and not "Scout" in names(p), "a level 9 Paladin can't take up Scout yet")
	p.level_up()
	ok(p.flex_due() == 1, "one to take up")
	ok(p.pick(p.flex_choice(), scout) and p.flex_due() == 0 and "Scout" in names(p) and sk("hide") in p.general_skills() and p.pick_missing(p.flex_choice(), scout) == "Picked", "levelling to 10 offers it: picked, Scout is one of its general trees")
	var back := unit_of("paladin")
	back.from_dict(p.to_dict())
	ok("Scout" in names(back), "a flex tree taken up is saved")


# A flex tree's prereqs (SkillTab.needs, base-stat floors; Unit.flex_needs()): FLEX_SLACK lower for a generalist,
# none for a jack, the tag from its class or anything it carries. A row: class, dex, wis, extra tags, what's missing.
func test_flex_prereqs() -> void:
	var scout: SkillTab = load("res://Trees/general_scout.tres")
	ok(scout.needs == {&"dexterity": 10, &"wisdom": 11}, "Scout asks dexterity 10, wisdom 11")
	for row in [["paladin", 10, 11, [], ""], ["paladin", 9, 11, [], "Needs Dexterity 10"], ["paladin", 10, 10, [], "Needs Wisdom 11"],
			["rogue", 8, 9, [], ""], ["rogue", 7, 9, [], "Needs Dexterity 8"], ["bard", 8, 8, [], "Needs Wisdom 9"],
			["adventurer", 1, 1, [], ""], ["paladin", 8, 9, [&"generalist"], ""], ["paladin", 1, 1, [&"jack"], ""]]:
		var u := unit_of(row[0])
		u.dexterity = row[1]
		u.wisdom = row[2]
		u.tags.append_array(row[3])
		ok(u.flex_missing(scout) == row[4], "%s dex %d wis %d %s: \"%s\" (got \"%s\")" % [row[0], row[1], row[2], row[3], row[4], u.flex_missing(scout)])
	var p := unit_of("paladin")
	p.level = 10
	p.dexterity = 9
	ok(not p.pick(p.flex_choice(), scout) and p.pick_missing(p.flex_choice(), scout) == "Needs Dexterity 10", "short of a floor, it can't take it up")


# One hook, two skills: a check effect with per_mod adds that stat's mod to the checks it names, from 0 up to the rank
# (Unit.check_bonus(): Journeyman's Physical Intelligence, int to str, and Muscle Memory, wis to str).
func test_stat_adds_to_checks() -> void:
	var u := v(1)
	u.intelligence = 18  # +4
	u.wisdom = 14  # +2
	u.dexterity = 10
	var pi := sk("physical_intelligence_check")
	var mm := sk("muscle_memory")
	var row := func(rank_pi: int, rank_mm: int) -> int:
		u.learned.clear(); u.sync_bar()
		if rank_pi:
			u.learned.append(slot(pi, rank_pi)); u.sync_bar()
		if rank_mm:
			u.learned.append(slot(mm, rank_mm)); u.sync_bar()
		return u.check_bonus(&"strength", &"offensive")
	ok(row.call(1, 0) == 1 and row.call(2, 0) == 2 and row.call(4, 0) == 4 and row.call(5, 0) == 4, "int +4 to str checks, up to rank: I +1, II +2, IV and V +4 (the mod)")
	ok(row.call(0, 1) == 1 and row.call(0, 3) == 2, "wis +2: Muscle Memory I +1, III +2 (the mod)")
	ok(row.call(2, 2) == 4 and u.check_bonus(&"strength", &"defensive") == 4 and u.check_bonus(&"dexterity", &"offensive") == 0, "both add, to defensive checks too, and only to str")
	u.intelligence = 6  # -2
	ok(row.call(3, 0) == 0, "a negative mod adds nothing, never a penalty")
	ok(pi.name == "Physical Intelligence" and sk("physical_intelligence").title() != pi.title(), "the Journeyman's skill has the user's name; the old stand-in is renamed")


func test_exclusive() -> void:
	var u := unit_of("adventurer")
	u.learned.append(slot(sk("decisive_strike"))); u.sync_bar()
	ok(u.missing(sk("brutal_strike")) == "Not with Decisive Strike" and u.missing(sk("elemental_strike")) == "Not with Decisive Strike", "one low-tier Strike upgrade")
	ok(u.skill_name(sk("strike")) == "Decisive Strike", "Strike goes by its name")


func test_foundation() -> void:
	v(1).learned.append(slot(sk("generalist"), 4)); v(1).sync_bar()
	ok(sk("generalist").pillar() and sk("generalist").foundation(), "a Foundation is a Pillar")
	var order := v(1).disable_order()
	ok(order.size() > 2 and order[2] == [sk("generalist")], "rank IV: two slots in from the right (%s)" % [order.map(func(g): return g.map(func(s: Skill): return s.name))])


# A Strike chain from v(1) at v(3), every roll a hit: str 18 (+4) against Defense 2, hits rolled from 11
# up (b.rng seeded for it: the first hits all land).
func strike_at(r: int) -> Array:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).strength = 30  # mod 10: nothing misses Defense 2
	v(1).learned.append(slot(strike, r)); v(1).sync_bar()
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
	v(1).learned.append(slot(sk("strike_out"), 3)); v(1).sync_bar()
	var got := strike_at(3)
	ok(got[0].size() == 3 and (got[0][0] == got[0][2] or got[1].has(20)), "Strike Out: no penalty (%s)" % [got[0]])


func test_brutal() -> void:
	v(1).learned.append(slot(sk("brutal_strike"), 2)); v(1).sync_bar()
	v(1).weapon = load("res://Items/broadsword.tres")
	var got := strike_at(3)
	ok(got[1].size() == 1, "Brutal Strike: a single attack")
	ok(got[0][0] == 1 + 10 + 1 + 2 or got[1][0] == 20, "+ the weapon's rank (1) + rank (2): %s" % [got[0]])


func test_features() -> void:
	v(1).learned.append(slot(sk("striking_features"), 1)); v(1).sync_bar()
	v(1).charisma = 16
	var got := strike_at(2)
	ok(got[0][0] == 11 + 1 or got[1][0] == 20, "Striking Features I: + cha mod, up to 1, on the first hit (%s)" % [got[0]])


# The attack_stat effect (Unit.attack_stat()): a table row per stat and passive. Strikes read the higher of
# str and the stat; lower or unequipped changes nothing; a skill the effect doesn't name is untouched; the
# forecast (Battle.attack_odds(), shared by the hit chance and the AI) sees it.
func test_attack_stat() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var kick := sk("kick")
	v(3).constitution = 30  # Defense 12: a bigger bonus shows in the odds
	v(1).learned.append(slot(strike, 1)); v(1).sync_bar()
	for row in [["striking_features", &"charisma"], ["striking_intellect", &"intelligence"]]:
		var u := v(1)
		u.strength = 12
		u.set(row[1], 18)
		var odds0 := Battle.attack_odds(u, strike, v(3), b)[0]
		var kick0 := u.attack_mod(kick)
		ok(u.attack_mod(strike) == 1 and u.attack_stat(strike) == &"strength", "%s unequipped: str (+1)" % row[0])
		var slot_ := slot(sk(row[0]), 1)
		u.learned.append(slot_); u.sync_bar()
		u.refresh()
		ok(u.attack_mod(strike) == 4 and u.attack_stat(strike) == row[1], "%s: %s mod (+4) beats str" % [row[0], row[1]])
		ok(Battle.attack_odds(u, strike, v(3), b)[0] > odds0, "...and the forecast sees it")
		ok(u.attack_mod(kick) == kick0, "...only for Strikes")
		u.set(row[1], 8)
		ok(u.attack_mod(strike) == 1, "%s lower than str: unchanged" % row[1])
		u.learned.erase(slot_); u.sync_bar()
		u.refresh()
		u.set(row[1], 10)


func test_record() -> void:
	v(1).learned.append(slot(sk("record_striker"), 1)); v(1).sync_bar()
	v(1).intelligence = 40
	v(3).wisdom = 1
	var first: Skill = v(3).hotbar[0]
	var before := v(3).rank(first)
	strike_at(1)
	ok(v(3).rank(first) == before - 1, "Record Striker: the leftmost skill a rank down (%s %d -> %d)" % [first.name, before, v(3).rank(first)])


func test_strike_bang() -> void:
	v(1).learned.append(slot(sk("strike_bang"), 2)); v(1).sync_bar()
	v(1).learned.append(slot(sk("strike_out"), 20)); v(1).sync_bar()  # nothing stops the chain
	var got := strike_at(12)
	ok(got[1].size() >= 12 + 13, "12 hits landed: it strikes again at once, with 1 more - and that use can too, up to 3 times (%d rolls)" % got[1].size())


func test_perfect() -> void:
	v(1).learned.append(slot(sk("strike_bang"), 1)); v(1).sync_bar()
	v(1).learned.append(slot(sk("strike_out"), 50)); v(1).sync_bar()
	var perfect := []
	b.perfect.connect(func(u: Unit): perfect.append(u))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).strength = 10
	v(1).learned.append(slot(strike, 12)); v(1).sync_bar()
	v(3).max_hp = 5000
	v(3).hp = 5000
	v(1).max_hp = 400
	v(1).hp = 50
	v(1).refresh()
	b.cast(v(1), strike, v(3))
	ok(perfect == [v(1)] and v(1).hp == 350, "36 in a row: a Perfect, 300 healed (%d)" % v(1).hp)


func test_elemental() -> void:
	v(1).learned.append(slot(sk("elemental_strike"), 2)); v(1).sync_bar()
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
	v(1).learned.append(slot(sk("elemental_mastery"))); v(1).sync_bar()
	v(1).element = &""
	v(1).god = &"luun"
	ok(sk("elemental_mastery") in v(1).passives and v(1).stat(&"elemental") > 0.0 and v(1).skill_name(strike) == "Strike",
			"Elemental Mastery: Strike always carries an element (its god's, else fire) without being renamed")
