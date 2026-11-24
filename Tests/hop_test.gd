extends Test

# Void, Jump and Floaty: astral void is a wall to walkers (enter 99) and firm ground to the floating (Battle._cost());
# a Jump (Hop: Behaviours/jump.gd) leaps over it but never lands on it (Battle.footing(), Behaviour.fits_at());
# Floaty (Effect ops scale and divide) stretches jumps x(rank + 1) and cuts movement /(rank + 1).

var hop: Skill = load("res://Skills/hop.tres")
var floaty: Skill = load("res://Skills/floaty.tres")
var void_t: Terrain = load("res://Terrain/astral_void.tres")


func test_void_and_jump() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 8)})
	var u := v(1)
	var was := {}
	for c in [Vector2i(3, 3), Vector2i(4, 3)]:
		was[c] = b.terrain(c)
		b.paint(c, void_t)
	var ground := b.terrain(Vector2i(2, 3))
	ok(b._cost(u, ground, void_t) >= 99.0 and not b.footing(u, Vector2i(3, 3)), "a walker can't step onto void, nor land on it")
	u.learned.append(slot(hop)); u.sync_bar(); u.refresh()
	ok(not b.cast_at(u, hop, Vector2i(4, 3)) and u.cell == Vector2i(2, 3), "a jump onto void isn't made (nothing paid)")
	var left := u.move_left()
	ok(b.cast_at(u, hop, Vector2i(5, 3)) == false, "out of range: Hop reaches 2 tiles")
	b.paint(Vector2i(4, 3), was[Vector2i(4, 3)])
	ok(b.cast_at(u, hop, Vector2i(4, 3)) and u.cell == Vector2i(4, 3) and is_equal_approx(u.move_left(), left), "over the void it jumps, spending no movement")
	u.learned.append(slot(floaty)); u.sync_bar(); u.refresh()
	ok(u.has_tag(&"floating") and b._cost(u, ground, void_t) == 1.0 + ground.exit and b.footing(u, Vector2i(3, 3)), "Floaty: void is firm ground to it")
	for c in was:
		b.paint(c, was[c])
	u.learned.pop_back(); u.learned.pop_back(); u.sync_bar(); u.refresh()


func test_ctrl_lands_on_void() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 8)})
	var u := v(1)
	var was := b.terrain(Vector2i(4, 3))
	b.paint(Vector2i(4, 3), void_t)
	u.learned.append(slot(hop)); u.sync_bar(); u.refresh()
	ok(not b.footing(u, Vector2i(4, 3)) and b.footing(u, Vector2i(4, 3), true), "footing(): void only on purpose (fall)")
	ok(not b.cast_at(u, hop, Vector2i(4, 3)) and u.is_alive(), "no fall flag: the jump is refused")
	ok(b.cast_at(u, hop, Vector2i(4, 3), true, "", true) and not u.is_alive(), "Ctrl-landing on void: it jumps and falls")
	b.paint(Vector2i(4, 3), was)


func test_floaty_scales() -> void:
	stage(lancin, {v(1): Vector2i(2, 3)})
	var u := v(1)
	u.learned.append(slot(hop)); u.sync_bar()
	var reach := b.area_reach(u, hop)
	var moves := u.stat(&"movement")
	var strike := sk("strike").span(u)
	for r in [1, 2]:
		u.learned.append(slot(floaty, r)); u.sync_bar(); u.refresh()
		ok(is_equal_approx(b.area_reach(u, hop), reach * (r + 1)) and is_equal_approx(u.stat(&"movement"), moves / (r + 1)),
				"Floaty %d: Hop %.1f -> %.1f tiles, movement %.1f -> %.1f" % [r, reach, b.area_reach(u, hop), moves, u.stat(&"movement")])
		ok(is_equal_approx(sk("strike").span(u), strike), "a skill that isn't a jump is untouched")
		u.learned.pop_back(); u.sync_bar()
	u.learned.pop_back(); u.sync_bar(); u.refresh()
