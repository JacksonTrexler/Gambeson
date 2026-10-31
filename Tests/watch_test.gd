extends Test

# Looking around (Battle._watch()): as its side's turn ends, each unit inspects the nearest suspicious
# things within its wis mod in tiles - with wis mod 0 or less, only beside it, every (1 - wis mod) turns.
# Each turn in a row it has rested widens its look, takes in one more thing and adds +1, up to its
# wis (Battle.survey()). Checks on things not beside it lose a point a tile from where it looks
# (Battle.distance_penalty()), less with Special Eyes. Observe searches every tile around a tile as if
# it had rested rank turns (Battle.observe()); Eyes Forward, every tile ahead the way it last moved
# (Battle._look_ahead()). Where nothing hides, there's nothing to find. AI searches by the clues. Pray, by god.

const TRAP := Vector2i(5, 4)  # the museum's spike trap

var observe: Skill = load("res://Skills/observe.tres")
var pray: Skill = load("res://Skills/pray.tres")


func looks_of(u: Unit) -> Array:
	var out := []
	b.inspected.connect(func(by: Unit, at: Vector2i, total: int, against: int):
		if by == u:
			out.append([at, total, against]))
	return out


func test_watch() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	var looks := looks_of(v(1))
	v(1).wisdom = 16  # mod 3
	ok(TRAP in b.suspicious(v(1)), "the trap is suspicious, 4 tiles off")
	b._watch(v(1))
	ok(looks.is_empty(), "beyond its wis mod (3) in tiles: no look")
	v(1).rested_turns = 1
	b._watch(v(1))
	ok(looks.size() == 1 and looks[0][0] == TRAP and looks[0][1] >= 1 + 3 + 1 - 4 and looks[0][1] <= 20 + 3 + 1 - 4,
			"a turn rested: a tile further, +1, less 4 for the tiles (%d)" % looks[0][1])
	ok(b.survey(v(1), v(1).cell, 50) == 1 and looks[-1][1] >= 1 + 3 + 16 - 4, "the rested bonus tops out at its wis (16): %d" % looks[-1][1])
	v(3).afflict(effect("concealment", 2), 9)
	b.move(v(3), Vector2i(2, 5))
	ok(b.read(v(1), v(3)).hint != "", "a vague shape beside it")
	ok(b.survey(v(1), v(1).cell, 0) == 1 and looks[-1][0] == Vector2i(2, 5), "not rested: one thing, the nearest")
	ok(b.survey(v(1), v(1).cell, 1) == 2, "a turn rested: one more")
	v(1).wisdom = 10  # mod 0
	v(1).rested_turns = 0
	v(1).suspicion.clear()  # what it saw through, it would look at no more
	var n := looks.size()
	for i in 2:
		v(1).suspicion.clear()
		b._watch(v(1))
	ok(looks.size() == n + 2 and looks[-1][0] == Vector2i(2, 5), "wis mod 0: what's beside it, every turn")
	v(1).wisdom = 8  # mod -1
	v(1).rested_turns = 0
	n = looks.size()
	v(1).suspicion.clear()
	b._watch(v(1))
	ok(looks.size() == n, "wis mod -1: not this turn...")
	b._watch(v(1))
	ok(looks.size() == n + 1, "...but every other")


func test_turn_end() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(8, 1)})
	var looks := looks_of(v(1))
	v(1).wisdom = 12
	b.end_turn()
	ok(v(1).rested_turns == 1 and looks.size() == 1 and looks[0][0] == TRAP, "its side's turn ends: it looks at the trap beside it, a turn rested")
	b.end_turn()
	v(1).refresh()
	b.travel(v(1), Vector2i(4, 5))
	b.end_turn()
	ok(v(1).rested_turns == 0 and looks.size() == 2, "it moved: the streak is over, but it still looks")


func test_distance_penalty() -> void:
	stage(lancin, {v(1): Vector2i(1, 4)})
	ok(b.distance_penalty(v(1), v(1).cell, Vector2i(2, 5)) == 0, "beside it: none")
	ok(b.distance_penalty(v(1), v(1).cell, TRAP) == 4, "4 tiles off: -4")
	ok(b.distance_penalty(v(1), Vector2i(6, 4), TRAP) == 1, "looking around a tile (Observe): a point a tile from there")
	v(1).afflict(effect("keen_eyes", 1), 9)
	ok(b.distance_penalty(v(1), v(1).cell, TRAP) == 2, "Special Eyes I: 4 / 2")
	var special: Skill = load("res://Skills/special_eyes.tres")
	ok(special.passive and "lose only tiles away / 3" in special.describe(2), special.describe(2))


func test_observe() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	var looks := looks_of(v(1))
	v(1).wisdom = 16
	v(1).learned.append(slot(observe, 2))
	v(1).refresh()
	ok(b.area_reach(v(1), observe) == 5.0 and not b.cast_at(v(1), observe, Vector2i(7, 4)), "reach: wis mod + rank (5); 6 tiles off is too far")
	ok(b.cast_at(v(1), observe, Vector2i(6, 4)) and looks.size() == 1 and looks[0][0] == TRAP
			and looks[0][1] >= 1 + 3 + 2 - 1 and looks[0][1] <= 20 + 3 + 2 - 1, "around the tile, as if it had rested 2 turns: +2, -1 a tile from it (%d)" % looks[0][1])
	ok("Inspects around a tile as if it had rested 2 turns: every tile" in observe.describe(2), observe.describe(2))
	v(3).afflict(effect("concealment", 4), 9)
	b.move(v(3), Vector2i(7, 5))
	ok(Vector2i(7, 5) not in b.suspicious(v(1)), "v(3) hides too well to leave a hint")
	var n := looks.size()
	ok(not b.inspect(v(1), Vector2i(3, 3)) and looks.size() == n, "nothing hidden there: nothing to find, no roll")
	v(1).refresh()
	ok(b.cast_at(v(1), observe, Vector2i(6, 4)) and looks.size() == n + 2 and looks.any(func(l: Array): return l[0] == Vector2i(7, 5)),
			"every tile around: it rolls for v(3) all the same (and the trap)")
	for path in ["res://Roles/adventurer.tres", "res://Roles/rogue.tres"]:
		var role: Role = load(path)
		ok(observe in role.offered() and load("res://Skills/eyes_forward.tres") in role.offered(), "%s: Observe and Eyes Forward on its tree" % role.name)


func test_eyes_forward() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	var looks := looks_of(v(1))
	v(1).wisdom = 12  # mod 1
	v(1).afflict(effect("eyes_forward", 2), 9)
	v(3).afflict(effect("concealment", 4), 9)
	b.move(v(3), Vector2i(4, 5))
	b.travel(v(1), Vector2i(2, 4))
	ok(v(1).heading == Vector2i(1, 0) and looks.is_empty(), "moving east")
	b._look_ahead(v(1))
	ok(looks.size() == 2 and looks.any(func(l: Array): return l[0] == TRAP) and looks.any(func(l: Array): return l[0] == Vector2i(4, 5))
			and v(1).heading == Vector2i.ZERO, "it looks ahead at every tile: the trap 3 on (rank 2 + wis mod 1), and v(3), hintless, a tile aside")
	v(1).heading = Vector2i(-1, 0)
	b._look_ahead(v(1))
	ok(looks.size() == 2, "moving the other way: not behind it")
	ok("2 + wis mod tiles ahead and 2 to either side" in load("res://Skills/eyes_forward.tres").describe(2), "described")



func test_eyes_forward_replaces() -> void:
	stage(lancin, {v(1): Vector2i(6, 4), v(3): Vector2i(8, 1)})
	var looks := looks_of(v(1))
	v(1).wisdom = 12
	v(1).afflict(effect("eyes_forward", 1), 9)
	v(1).heading = Vector2i(1, 0)
	b._watch(v(1))
	ok(looks.is_empty(), "moved east last: it looks ahead instead of around - not at the trap behind it")
	b._watch(v(1))
	ok(looks.size() == 1 and looks[0][0] == TRAP, "standing still, it looks around: the trap beside it")

func test_pray() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(2): Vector2i(2, 4), v(3): Vector2i(8, 1)})
	ok((load("res://Roles/paladin.tres") as Role).god == &"eros" and pray in (load("res://Roles/paladin.tres") as Role).offered(), "Paladins pray to Eros")
	v(1).learned.append(slot(pray, 2))
	v(1).god = &"ramut"
	v(1).refresh()
	var grace := b.grace(lancin)
	ok(b.cast(v(1), pray, v(1)) and b.hastened[lancin] == 2 and b.grace(lancin) == maxf(grace - 2.0, 0.0), "to Ramut: Lancin waits 2 turns less for the Ire")
	v(1).god = &"eros"
	b.suspect(v(2), v(1), 2)
	b.suspect(v(3), v(1))
	v(1).refresh()
	ok(b.cast(v(1), pray, v(1)) and v(2).suspects(v(1)) == 1 and v(3).suspects(v(1)) == 1, "to Eros: a stack off the suspicion of those near that see it; v(3), 7 tiles off, keeps its")
	v(1).god = &"sol"
	v(1).refresh()
	ok(b.cast(v(1), pray, v(1)) and b.hastened[lancin] == 2 and v(2).suspects(v(1)) == 1, "to Sol: no answer yet")
	ok(Unit.GODS.has_all([&"ramut", &"eros", &"sol", &"urlo", &"luun", &"drael", &"vetruvis"]), "the seven gods")


func test_ai_search() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	v(3).afflict(effect("concealment", 4), 9)
	v(1).wisdom = 16
	v(1).learned.append(slot(observe, 2))
	v(1).refresh()
	var log := AI.act(b, v(1))
	ok(log.any(func(l: String): return "uses Observe" in l), "no foe in sight: it searches where the trap's hint is %s" % [log])
