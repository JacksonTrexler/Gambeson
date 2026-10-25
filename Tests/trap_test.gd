extends Test

# Traps units lay (Snare; Battle.lay()): what they look like, who's told of them (allies within the
# setter's charisma mod in tiles, twice that with Hazard Expert, a vibe for the rest), what they do
# when sprung, and traps that keep their concealment after springing.

var snare: Skill = load("res://Skills/snare.tres")
var hazard: Skill = load("res://Skills/hazard_expert.tres")
var trap: Terrain = load("res://Terrain/trap.tres")
const AT := Vector2i(3, 3)


func al() -> Unit:
	return b.get_node("Units/Alabaster")


func test_lay() -> void:
	v(1).learned.append(slot(snare, 2))
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(1, 3), al(): Vector2i(6, 6), v(3): Vector2i(8, 6)})
	ok(b.cast_at(v(1), snare, AT), "a snare set within reach")
	var t := b.terrain(AT)
	ok(t.name == "Snare" and t.is_trap() and t.concealment == 2 and t.times == 2 and t.bonus == 1 and t.looks_like == &"Grass",
			"rank II: concealment 2, 1d4 x2 + dex 1, looking like the grass it's in")
	ok(b.read(v(1), AT).trap == true and b.read(v(2), AT).trap == true, "the setter knows it, and so does the ally beside it (cha -1: 1 tile)")
	ok(b.read(al(), AT).trap == null and b.read(al(), AT).hint == "a glint of wire?", "an ally further off sees only a shape")
	ok(b.read(v(3), AT).trap == null and b.read(v(3), AT).name == "Grass", "the enemy sees grass")
	ok(not b.cast_at(v(1), snare, AT) and not b.cast_at(v(1), snare, Vector2i(1, 3)), "not on a trap, not under a unit")
	ok(not b.cast_at(v(1), snare, Vector2i(5, 3)), "not out of reach")


func test_spring() -> void:
	v(1).learned.append(slot(snare, 2))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6)})
	b.cast_at(v(1), snare, AT)
	b.end_turn()
	b.travel(v(3), Vector2i(2, 3))
	ok(v(3).cell == AT and v(3).hp >= 1 and v(3).hp <= 7, "the enemy walks into it: 1d4 x2 + 1, piercing (took %d)" % (10 - v(3).hp))
	ok(b.read(v(4), AT).trap == true, "sprung, it's lost all its concealment")


func test_stays_hidden() -> void:
	trap.reveals = false
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(8, 2)})
	b.travel(v(1), Vector2i(5, 4))
	ok(v(1).hp < 10 and b.hidden(Vector2i(5, 4)) and b.read(v(3), Vector2i(5, 4)).trap == null, "a trap made to stay hidden does")
	trap.reveals = true


func test_hazard_expert() -> void:
	v(1).learned.append(slot(snare, 1))
	v(1).learned.append(slot(hazard))
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(0, 3), al(): Vector2i(6, 6), v(3): Vector2i(8, 0)})
	b.cast_at(v(1), snare, AT)
	ok(b.read(v(2), AT).trap == true, "word carries twice as far: 2 tiles")
	ok(b.read(al(), AT).hint == "traps were set here", "allies out of earshot get a vibe of it")
	ok(b.read(v(3), AT).hint == "" and b.read(v(3), AT).trap == null, "the enemy gets nothing")


func test_initiative_record() -> void:
	for f in b.rolls:
		var mine: Array = b.unit_rolls.keys().filter(func(u): return u.faction == f).map(func(u): return b.unit_rolls[u])
		ok(mine == b.rolls[f], "each unit's d20 is recorded (%s)" % f.name)
