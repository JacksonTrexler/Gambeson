extends Test

# Striking at tiles (Battle.attempt) and exposure: a hidden unit loses a level of concealment when
# a hostile skill lands on it, and when it lands one, until its side's next turn starts.


func test_strike_at_hidden() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).afflict(effect("concealment", 4), 9)
	ok(Perception.cover(b, v(3)) == 4 and b.read(v(1), v(3)).net == -4, "concealment 4: not even suspected")
	ok(b.attempt(v(1), strike, Vector2i(5, 3)) == &"hit" and v(3).hp == 8, "a strike at its tile finds it (1 + str 1)")
	ok(v(3).exposed == 1 and b.read(v(1), v(3)).net == -3, "hit: a level of concealment lost - now suspected")
	ok(v(1).exposed == 0, "an attacker with nothing to hide has nothing to lose")
	b.attempt(v(1), strike, Vector2i(5, 3))
	ok(v(3).exposed == 2 and b.read(v(1), v(3)).located(), "hit again: located")
	b.end_turn()
	ok(v(3).exposed == 0 and b.read(v(1), v(3)).net == -4, "back in hiding as its side's turn starts")


func test_attacker_exposed() -> void:
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).afflict(effect("concealment", 2), 9)
	ok(b.cast(v(3), strike, v(1)) and v(3).exposed == 1, "attacking from hiding gives it away")
	b.end_turn()
	ok(v(3).exposed == 1 and b.read(v(1), v(3)).net == -1, "through the other side's turn")
	b.end_turn()
	ok(v(3).exposed == 0, "until its own turn comes round")
	ok(b.cast(v(3), hex, v(1)) and v(1).exposed == 0, "the unhidden target loses nothing")


func test_support_doesnt_expose() -> void:
	var al: Unit = b.get_node("Units/Alabaster")
	var stonegift: Skill = load("res://Skills/stonegift.tres")
	stage(lancin, {al: Vector2i(2, 4), v(1): Vector2i(3, 4), v(3): Vector2i(8, 2)})
	v(1).afflict(effect("concealment", 2), 9)
	ok(b.cast(al, stonegift, v(1)) and v(1).exposed == 0, "a gift from an ally isn't an attack")


func test_strike_at_air() -> void:
	var al: Unit = b.get_node("Units/Alabaster")
	stage(lancin, {v(1): Vector2i(4, 3), al: Vector2i(1, 1), v(3): Vector2i(8, 2)})
	ok(b.attempt(v(1), strike, Vector2i(5, 3)) == &"miss" and is_equal_approx(v(1).ap_left(), 9.0), "nobody there: the strike is spent")
	ok(b.attempt(v(1), strike, Vector2i(7, 3)) == &"" and is_equal_approx(v(1).ap_left(), 9.0), "out of reach: not tried, nothing spent")
	var stonegift: Skill = load("res://Skills/stonegift.tres")
	ok(b.attempt(al, stonegift, Vector2i(1, 2)) == &"" and al.energy == 10, "only attacks are aimed at tiles")
	b.end_turn()
	ok(b.attempt(v(1), strike, Vector2i(5, 3)) == &"", "not on the other side's turn")
