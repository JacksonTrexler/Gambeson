extends Test

# Turn order: a side that falls while its own turn is ending doesn't make the turn pass twice.

var demons: Faction = load("res://Factions/demons.tres")


# Three sides: Lancin (v1), Nemes (v3), Demons (v4); v2 sits out, Lancin's v1 bleeds out as its turn ends.
func three_sides() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2), v(4): Vector2i(8, 5)})
	v(4).faction = demons
	b.order.assign([lancin, nemes, demons])
	b.turn = null
	b.turn = lancin


func test_last_unit_bleeds_out() -> void:
	three_sides()
	var bleed: Effect = (load("res://Skills/snare.tres") as Skill).lays.wounds[0]
	v(1).hp = 1
	v(1).afflict(bleed, 5, 1)
	var turns: Array = []
	b.turn_changed.connect(func(_was: Faction, now: Faction): turns.append(now))
	b.end_turn()
	ok(not v(1).is_alive() and lancin not in b.order, "its last unit bled out as its turn ended (alive %s)" % v(1).is_alive())
	ok(b.phase == Battle.Phase.TURNS and b.turn == nemes, "the turn passed once, to Nemes, not on to Demons (%s)" % [b.turn.name])
	ok(turns == [nemes], "and the turn only changed once (%s)" % [turns.map(func(f: Faction): return f.name)])


func test_dying_off_turn_still_passes() -> void:
	three_sides()
	v(1).damage(999)  # a side's last unit dying in its own turn, outside end_turn(): the turn passes at once
	ok(b.turn == nemes, "the turn passes on to the next side (%s)" % [b.turn.name])
	b.end_turn()
	ok(b.turn == demons, "and ends as usual")


func test_two_sides_unchanged() -> void:
	villagers_only()
	b.end_turn()
	ok(b.turn == nemes, "Lancin's turn ends")
	b.end_turn()
	ok(b.turn == lancin, "and Nemes'")
