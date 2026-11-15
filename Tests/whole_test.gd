extends Test

# Behaviour.whole(): a behaviour whose apply() is the whole of a cast (Beastshape, Emergency Exit, an
# aura, Igna on an ally...) lands it at once - no roll, no effects or damage of the skill's own - and one
# that isn't, on a foe (Igna's Boost), leaves the skill to land as usual.


class Whole extends Behaviour:
	var ran := 0

	func whole(_c: Cast) -> bool:
		return true

	func apply(_c: Cast) -> void:
		ran += 1


func test_whole_is_all_it_does() -> void:
	var w := Whole.new()
	var s: Skill = hex.duplicate()  # an attack with damage and an effect
	s.behaviours = [w] as Array[Behaviour]
	v(1).learned.append(slot(s, 3))
	v(1).refresh()
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	v(3).max_hp = 300
	v(3).hp = 300
	var rolls := []
	b.attacked.connect(func(_c: Unit, _t: Unit, d: int, _x: int, _df: int): rolls.append(d))
	ok(b.cast(v(1), s, v(3)) and w.ran == 1, "it lands: its behaviour runs")
	ok(rolls.is_empty() and v(3).hp == 300 and v(3).timed.is_empty(), "with no roll, damage or effect of the skill's own (%s, %d HP, %d effects)" % [rolls, v(3).hp, v(3).timed.size()])


func test_boost_whole_only_on_an_ally() -> void:
	var igna: Skill = load("res://Skills/igna.tres")
	var c := b.cast_of(v(1), igna, v(2), 1, false)
	var boost: Behaviour = igna.behaviours[0]
	ok(boost == igna.behaviour(&"boost") and boost.whole(c), "Igna on an ally: the AP is the whole of it")
	c.foe = true
	ok(not boost.whole(c), "on a foe it isn't: the skill lands as usual")
