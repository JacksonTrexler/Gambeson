extends Test

# The Bracing passives on the general tree (Unit.check_bonus()): armor ranks added to checks, by the
# armor's weight, the check's stat and whether it's offensive or defensive, up to the passive's rank -
# only while the armor is worn to some effect (Unit.armored()).

var gambeson: Item = load("res://Items/gambeson.tres")
var habergeon: Item = load("res://Items/habergeon.tres")
var brigandine: Item = load("res://Items/brigandine.tres")


func brace(n: String) -> Skill:
	return load("res://Skills/%s_bracing.tres" % n)


# A piece of armor at a rank.
func at(it: Item, r: int) -> Item:
	var x: Item = it.duplicate()
	x.rank = r
	return x


func test_tree() -> void:
	var u := b.starter({faction = lancin, role = load("res://Roles/adventurer.tres"), name = "Shrike"})
	for n in ["agility", "balanced", "vanguard", "combat", "meditative", "invigorating"]:
		ok(brace(n) in u.sources()[&"class"] and u.tier(brace(n)) == 5, "%s: on the general trees an Adventurer gets, tier 5" % n)
	u.free()
	ok(&"martial" in brace("agility").tags and &"specialist" in brace("agility").tags and &"magical" in brace("meditative").tags, "martial, specialist and caster passives")
	ok("Rollers" in brace("agility").describe() and "Doozers" in brace("combat").describe(), "each with its gang's lore")


func test_agility() -> void:
	v(1).learned.append(slot(brace("agility"), 2))
	v(1).armor = at(gambeson, 3)
	ok(v(1).check_bonus(&"dexterity", &"offensive") == 2 and v(1).check_bonus(&"dexterity", &"defensive") == 2, "light rank 3: +3 to dex rolls, up to rank II")
	ok(v(1).check_bonus(&"strength", &"offensive") == 0, "not str")
	v(1).armor = at(habergeon, 3)
	ok(v(1).check_bonus(&"dexterity", &"offensive") == 0, "not in medium armor")


func test_balanced_and_vanguard() -> void:
	v(1).learned.append(slot(brace("balanced"), 5))
	v(1).armor = at(habergeon, 2)
	ok(v(1).check_bonus(&"strength", &"defensive") == 2 and v(1).check_bonus(&"dexterity", &"offensive") == 0, "Balanced: defensive str and dex")
	v(1).learned.append(slot(brace("vanguard"), 5))
	ok(v(1).check_bonus(&"dexterity", &"offensive") == 2, "Vanguard: offensive")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).armor = bulwark()
	var with := Battle.hit_chance(v(1), strike, v(3))
	v(1).armor = null
	ok(with > Battle.hit_chance(v(1), strike, v(3)), "attack rolls take it")


func test_combat() -> void:
	v(1).learned.append(slot(brace("combat"), 5))
	v(1).armor = at(brigandine, 3)
	ok(v(1).check_bonus(&"strength", &"offensive") == 3 and v(1).check_bonus(&"strength", &"defensive") == 3 and v(1).check_bonus(&"dexterity", &"defensive") == 0, "heavy: str rolls")
	var heavy: Item = at(brigandine, 3)
	heavy.requires = &"intelligence"
	v(1).intelligence = 8
	v(1).armor = heavy
	ok(not v(1).armored() and v(1).check_bonus(&"strength", &"offensive") == 0, "armor it can't wear to effect: nothing")


func test_mental() -> void:
	v(1).learned.append(slot(brace("meditative"), 5))
	v(1).learned.append(slot(brace("invigorating"), 2))
	v(1).armor = at(gambeson, 4)
	ok(v(1).check_bonus(&"wisdom", &"defensive") == 4 and v(1).check_bonus(&"charisma", &"defensive") == 4, "Meditative: defensive mental checks, any armor")
	ok(v(1).check_bonus(&"intelligence", &"offensive") == 2, "Invigorating: half the armor's rank to offensive mental checks")
	v(1).refresh()
	var skill_ap := v(1).ap[2].amount
	v(1).armor = null
	v(1).refresh()
	ok(skill_ap == v(1).ap[2].amount + 2, "and rank more skill AP, while armored")


# Bracing and other check effects reach investigations (offensive), hiding (defensive) and last stands
# (the best defensive bonus over its stats).
func test_more_checks() -> void:
	v(1).learned.append(slot(load("res://Skills/turtle_tactics.tres"), 2))
	ok(v(1).best_defensive_bonus() == 4, "Turtle Tactics II: +4 to defensive checks")
	var lowest := 99
	for n in 200:
		lowest = mini(lowest, b.last_stand(v(1)))
	ok(lowest >= 1 + v(1).average_mod() + 4, "a last stand takes it (lowest %d)" % lowest)
	var keen := effect("check", 30.0)
	keen.kind = &"offensive"
	v(3).afflict(keen, 9)
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(6, 3)})
	var looks := []
	b.investigated.connect(func(_by, _of, _s, total, _against, _close): looks.append(total))
	b.investigate(v(1), load("res://Skills/hide.tres"), [v(3)] as Array[Unit], 25)
	ok(looks.size() == 1 and looks[0] >= 31 + v(3).mod(&"wisdom"), "an investigation is offensive: +30 (%s)" % [looks])
	ok(b._hide_roll(v(1)) >= 1 + v(1).mod(&"dexterity") + 4, "hiding is defensive")
