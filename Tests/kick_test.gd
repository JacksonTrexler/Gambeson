extends Test

# Kick (Behaviours/kick.gd): an attack at rank range whose rider is whatever lies on the tile at the
# kicker's feet, between it and the foe - a trap springs on the foe, water soaks it, loose ground blinds
# it, a hole drives it back rank tiles; bare ground, just the blow; beside it, a 1-tile push. The first
# skill on Skill.behaviours.

var kick: Skill = load("res://Skills/kick.tres")
const KICK := preload("res://Behaviours/kick.gd")
const FROM := Vector2i(2, 3)
const MID := Vector2i(3, 3)  # between them, at rank II's 2 tiles
const AT := Vector2i(4, 3)


# v(1) kicking at rank r, sure to hit (str 40), at v(3) on `at`, sturdy enough to take it.
func kicker(r := 2, at := AT) -> Unit:
	v(1).learned.append(slot(kick, r))
	v(1).strength = 40
	v(1).refresh()
	stage(lancin, {v(1): FROM, v(3): at})
	v(3).max_hp = 300
	v(3).hp = 300
	return v(1)


func test_reach() -> void:
	var u := kicker(1)
	ok(not b.in_reach(u, kick, v(3)) and b.cast(u, kick, v(3)) == false, "rank I: 2 tiles is out of reach")
	stage(lancin, {u: FROM, v(3): MID})
	ok(b.in_reach(u, kick, v(3)), "rank I reaches the tile beside it")
	ok(load("res://Trees/general_martial.tres").offers(kick), "on the General Martial tree")
	var said := kick.describe(2)
	ok(said.split("\n")[0].contains("range rank"), "range: its rank (%s)" % said.split("\n")[0])
	ok("Soaked" in said and "Blinded" in said and "drives it 2 tiles straight back" in said, "what it kicks up, said beside the rest: %s" % said)


func test_bare() -> void:
	var u := kicker()
	ok(KICK.kind(b, MID) == &"", "plain ground between")
	ok(b.cast(u, kick, v(3)) and v(3).hp < 300 and v(3).cell == AT and v(3).timed.is_empty(), "just the blow (took %d)" % (300 - v(3).hp))


func test_beside() -> void:
	var u := kicker(2, MID)
	ok(b.cast(u, kick, v(3)) and v(3).cell == AT, "nothing between: a 1-tile push (%s)" % v(3).cell)


func test_water() -> void:
	var u := kicker()
	b.paint(MID, load("res://Terrain/shallows.tres"))
	var moves := v(3).stat(&"movement")
	ok(b.cast(u, kick, v(3)) and KICK.SOAKED in v(3).timed, "water between: it splashes the foe, Soaked")
	ok(is_equal_approx(v(3).stat(&"movement"), moves - 2.0) and v(3).timed[KICK.SOAKED].total == 2, "rank II: 2 less movement for 2 turns")
	ok(v(3).cell == AT, "and no push")


func test_loose() -> void:
	var u := kicker()
	b.lay_layer(MID, load("res://Terrain/leaves.tres"))
	ok(b.cast(u, kick, v(3)) and KICK.BLINDED in v(3).timed, "leaves between: thrown up, Blinded")
	ok(v(3).check_bonus(&"strength", &"offensive") == -2 and v(3).check_bonus(&"strength", &"defensive") == 0,
			"rank II: -2 to its attacks and offensive checks, its defence untouched")


func test_trap() -> void:
	var u := kicker()
	b.paint(MID, load("res://Terrain/trap.tres"))
	var sprung := []
	b.sprung.connect(func(c: Vector2i, by: Unit): sprung.append([c, by]))
	ok(b.cast(u, kick, v(3)) and sprung == [[MID, v(3)]], "a trap between: kicked into the foe, it springs on it (%s)" % [sprung])
	ok(u.hp == u.max_hp, "not on the kicker")


func test_hole() -> void:
	var u := kicker()
	b.map.erase_cell(MID)
	ok(b.cast(u, kick, v(3)) and v(3).cell == AT + Vector2i(2, 0), "a hole between: no footing, driven back rank (2) tiles (%s)" % v(3).cell)
