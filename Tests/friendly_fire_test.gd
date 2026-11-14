extends Test

# Friendly fire (Battle.cast(), Battle._holds_fire()): an attack on an ally its user can't tell for one
# (hidden from it, or passing for something else) first makes a hidden wis check at the standard
# difficulty. Passing, it holds its fire: the action is spent but cut off as an interrupt cuts it (its
# own hiding ends), the ally takes nothing, and its side reads that ally well enough to see its side.
# Failing, the attack lands on the ally as on a foe. An ally it can tell for one it still can't attack.


# v(1) beside v(2), its ally, hidden from it in deep darkness (a zone: its allies know where it hides by
# its own concealment, not by what's laid over it); v(1) sure to hit.
func hidden_ally() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	v(1).refresh()
	v(1).strength = 40
	var dark: Dictionary[Vector2i, int] = {Vector2i(5, 3): 9}
	b.zones.append(Battle.Zone.new(&"dark", dark, 99, nemes))
	v(2).max_hp = 200
	v(2).hp = 200
	ok(b.read(v(1), v(2)).attitude(v(1)) != &"ally", "v(1) can't tell v(2) for an ally")


func test_holds_fire() -> void:
	hidden_ally()
	v(1).wisdom = 99  # sure to pass
	var told := []
	b.held_fire.connect(func(u: Unit, ally: Unit): told.append([u, ally]))
	var ap := v(1).ap_left()
	ok(b.cast(v(1), strike, v(2)), "the attack is used")
	ok(v(2).hp == 200 and told == [[v(1), v(2)]], "but it holds its fire: nothing lands (%d)" % v(2).hp)
	ok(v(1).ap_left() < ap, "the action is spent")
	ok(b.read(v(1), v(2)).attitude(v(1)) == &"ally", "and now it reads it for an ally")
	ok(not b.cast(v(1), strike, v(2)) and v(2).hp == 200, "which it can't attack")


func test_interrupts() -> void:
	hidden_ally()
	v(1).wisdom = 99
	v(1).afflict(effect("concealment", 1), 9).until_move = true
	var ended := []
	b.interrupted.connect(func(u: Unit, what: Array[StringName]): ended.append([u, what]))
	ok(b.cast(v(1), strike, v(2)) and ended.size() == 1 and ended[0][0] == v(1) and &"hiding" in ended[0][1], "cut off as an interrupt: its own hiding ends (%s)" % [ended])


func test_friendly_fire() -> void:
	hidden_ally()
	v(1).wisdom = 1  # sure to fail (mod -5 against DC 12)
	var told := []
	b.held_fire.connect(func(u: Unit, ally: Unit): told.append(u))
	ok(b.cast(v(1), strike, v(2)) and v(2).hp < 200 and told.is_empty(), "failing, the blow lands on its ally (%d)" % v(2).hp)
