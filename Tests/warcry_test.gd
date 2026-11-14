extends Test

# Warcry (Skills/warcry.tres, Behaviours/warcry.gd): marks on the first rank tiles of the line to each of up
# to rank foes it can see: the nearer half Charge! (allies: dex AP back, +10% x rank damage until their turn
# ends), the farther Routed! (foes pay rank more movement), each used up by the first to enter.

var warcry: Skill = load("res://Skills/warcry.tres")


func start(rank: int) -> void:
	v(1).learned.append(slot(warcry, rank))
	stage(lancin, {v(1): Vector2i(1, 3), v(2): Vector2i(1, 5), v(3): Vector2i(7, 3), v(4): Vector2i(7, 5)})
	b.sight = false
	v(1).refresh()
	v(2).refresh()


func test_warcry_lays_the_line() -> void:
	start(2)
	ok(b.cast(v(1), warcry, v(1)), "cast on itself")
	ok(b.has_mark(Vector2i(2, 3), &"charge") and b.has_mark(Vector2i(3, 3), &"routed"), "rank 2 toward the nearer foe: Charge! then Routed!")
	ok(b.has_mark(Vector2i(2, 4), &"charge") or b.has_mark(Vector2i(2, 5), &"charge") or b.marks.size() >= 3, "and on the way to the other foe (%d tiles)" % b.marks.size())
	ok(not b.has_mark(Vector2i(7, 3), &"routed") and not b.has_mark(Vector2i(4, 3), &"charge"), "only the first rank tiles, short of the foe")
	var m: Battle.Mark = b.marks_at(Vector2i(3, 3))[0]
	ok(m.who == &"foes" and m.cost == 2.0 and m.uses == 1 and m.turns == 4, "Routed!: foes pay 2 more, one use, rank + 2 turns")
	var c: Battle.Mark = b.marks_at(Vector2i(2, 3))[0]
	ok(c.who == &"allies" and c.rank == 2 and c.effects.size() == 2, "Charge!: allies, two effects at rank 2")


func test_rank_one_picks_one_foe() -> void:
	start(1)
	b.cast(v(1), warcry, v(1))
	ok(b.marks.size() == 1 and b.has_mark(Vector2i(2, 3), &"charge"), "rank 1: the nearest foe, one tile, a Charge! (the nearer half rounds up)")
	ok(warcry.describe(3) != "" and warcry.stub == "", "it says what it does")


func test_charge() -> void:
	start(2)
	b.cast(v(1), warcry, v(1))
	v(2).ap[1].amount = 0.0
	b.move(v(2), Vector2i(1, 4))
	var before := v(2).ap[1].amount
	b.travel(v(2), Vector2i(2, 3))
	ok(v(2).stat(&"damage") > 0.19 and v(2).stat(&"damage") < 0.21, "an ally entering: +10 percent x rank damage (%s)" % v(2).stat(&"damage"))
	ok(v(2).ap[1].amount > before - 0.001 and not b.has_mark(Vector2i(2, 3), &"charge"), "its dex AP back (%s), and the mark's used up" % v(2).ap[1].amount)
	b.end_turn()
	ok(v(2).stat(&"damage") == 0.0, "until its turn ends")


func test_charge_gives_back_what_it_spent() -> void:
	start(2)
	b.cast(v(1), warcry, v(1))
	var start_dex: float = v(2)._ap_start[1]
	v(2).ap[1].amount = maxf(start_dex - 1.0, 0.0)
	var low: float = v(2).ap[1].amount
	b.place(v(2), Vector2i(2, 3))
	ok(is_equal_approx(v(2).ap[1].amount, minf(low + 2.0, start_dex)), "regains up to rank dex AP, no more than it started the turn with (%s of %s)" % [v(2).ap[1].amount, start_dex])


func test_routed() -> void:
	start(2)
	b.cast(v(1), warcry, v(1))
	stage(nemes, {v(3): Vector2i(5, 3), v(1): Vector2i(1, 1)})
	v(3).movement = 9
	v(3).refresh()
	var w := b.walk(v(3), Vector2i(3, 3))
	var plain := 1.0
	ok(w.path.size() == 2 and is_equal_approx(w.costs[1], plain + 2.0), "a foe entering the Routed! tile pays 2 more movement (%s)" % [w.costs])
	b.travel(v(3), Vector2i(3, 3))
	ok(not b.has_mark(Vector2i(3, 3), &"routed") and b.has_mark(Vector2i(2, 3), &"charge"), "and it's used up; the Charge! beside it is for allies, still there")
	ok(v(3).timed.is_empty() or v(3).stat(&"damage") == 0.0, "a foe takes no Charge!")


func test_a_foe_it_cannot_see_isnt_picked() -> void:
	start(2)
	b.sight = true
	v(1).wisdom = 4
	b.cast(v(1), warcry, v(1))
	ok(b.marks.is_empty() or not b.has_mark(Vector2i(2, 5), &"charge"), "with no foe in sight: nothing to mark toward (%d)" % b.marks.size())
