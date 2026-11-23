extends Test

# Ambush (Behaviours/ambush.gd): hidden marks on up to rank tiles its weapon reaches; a foe walking onto
# one stops there and is struck out of turn (Mark.halts, Behaviour.tripped()), unless the caster reads it
# as no one to hit; each fires once; gone as its side's next turn ends. Walkers can't foresee one they
# haven't seen through, and seeing through it is an inspect() like a trap's.

var ambush: Skill = load("res://Skills/ambush.tres")


func test_ambush() -> void:
	v(3).learned.append(slot(ambush, 2))
	stage(nemes, {v(3): Vector2i(4, 2), v(1): Vector2i(1, 3)})  # beside the path, not on it
	v(3).strength = 60
	v(3).dexterity = 60
	soak(v(1))
	ok(Behaviours_ambush().weapon(v(3)) == strike, "its weapon: its first attack")
	ok(b.cast_at(v(3), ambush, Vector2i(4, 3)), "lies in wait")
	var laid := b.marks.keys().filter(func(c: Vector2i): return b.has_mark(c, &"ambush"))
	ok(laid.size() == 2 and Vector2i(4, 3) in laid, "rank 2: two tiles, nearest the one aimed at (%s)" % [laid])
	b.end_turn()
	var seen: Array = b.walk(v(1), Vector2i(7, 3), true).path
	ok(Vector2i(4, 3) in seen and seen.back() != Vector2i(4, 3),
			"hidden: the walker doesn't see it coming")
	var p := b.travel(v(1), Vector2i(7, 3))
	ok(p.back() == Vector2i(4, 3) and v(1).hp < 999, "walks in: stopped there, and struck")
	ok(not b.has_mark(Vector2i(4, 3), &"ambush") and laid.any(func(c: Vector2i): return b.has_mark(c, &"ambush")), "that tile's used up, the other waits")
	b.end_turn()
	b.end_turn()
	ok(laid.all(func(c: Vector2i): return not b.has_mark(c, &"ambush")), "gone once its side's next turn ends")


func test_ambush_spares_friends() -> void:
	v(3).learned.append(slot(ambush, 1))
	stage(nemes, {v(3): Vector2i(4, 2), v(1): Vector2i(1, 3)})
	ok(b.cast_at(v(3), ambush, Vector2i(4, 3)), "lies in wait")
	b.end_turn()
	v(1).wisdom = 60
	ok(b.inspect(v(1), Vector2i(4, 3)) and b.walk(v(1), Vector2i(7, 3), true).path.back() == Vector2i(4, 3), "seen through, as a trap is: it knows it'd stop there")
	v(1).afflict(effect("trickery", 9), 9)  # passes itself off as a friend
	v(3).wisdom = 1
	var hp := v(1).hp
	ok(b.read(v(3), v(1)).attitude(v(3)) == &"ally", "the ambusher takes it for a friend")
	ok(b.travel(v(1), Vector2i(7, 3)).back() == Vector2i(4, 3) and v(1).hp == hp, "stopped, but the caster holds its blow")


# The AI lies in wait where the foes will walk (AI._waylay(), Behaviour.waylays()): marks on tiles a foe's walk
# toward it crosses, and waits there; a foe that wouldn't come within reach gets none.
func test_ai_waylays() -> void:
	v(3).learned.append(slot(ambush, 2))
	stage(nemes, {v(3): Vector2i(4, 2), v(1): Vector2i(9, 4)})
	v(3).dexterity = 60
	v(3).strength = 60  # a blow worth the AP
	var far := v(1).stat(&"movement")
	print("DBG ", Behaviours_ambush().weapon(v(3)).name, " ", b.skill_range(v(3), Behaviours_ambush().weapon(v(3))), " ", v(3).actives.map(func(x): return x.name), v(3).move_left(), " ", v(1).faction.name, v(3).faction.name)
	var log := AI.act(b, v(3))
	var laid := b.marks.keys().filter(func(c: Vector2i): return b.has_mark(c, &"ambush"))
	ok(Vector2i(5, 2) in laid and v(3).cell == Vector2i(4, 2),
			"a foe coming: it lays marks on the tile it walks to and waits (%s) %s" % [laid, log])
	for c in laid:
		b.marks.erase(c)
	stage(nemes, {v(3): Vector2i(0, 0), v(1): Vector2i(9, 7)})
	AI.act(b, v(3))
	ok(not b.marks.keys().any(func(c: Vector2i): return b.has_mark(c, &"ambush")), "a foe out of its walk's reach of it: none (%s)" % far)


func Behaviours_ambush() -> GDScript:
	return load("res://Behaviours/ambush.gd")
