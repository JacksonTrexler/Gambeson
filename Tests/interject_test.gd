extends Test

# Interject (Skills/interject.tres, Behaviours/interject.gd): a Protector reaction. When an ally beside it
# is hit, a dex check against the attacker; passing, it takes the hit instead. It takes 25% less a rank of
# a hit not aimed at it (no cap but the whole hit); from rank V its Defense counts 25% more a rank against
# the roll, taking one for an ally. Who it covers and how often (?13): allies beside it, every hit.

var interject: Skill = load("res://Skills/interject.tres")
var jam: Skill = load("res://Skills/jam.tres")


# v(3) (Nemes) hits v(1), sure to (str and dex 40); v(2), beside v(1), interjects at rank r, sure to pass
# its check (+60 on reaction checks alone: an effect tagged reaction).
func scene(r := 1, at := Vector2i(4, 4)) -> void:
	v(2).learned.append(slot(interject, r))
	v(2).afflict(keen(), 9)
	v(3).learned.append(slot(jam))
	v(3).dexterity = 40
	v(3).strength = 40
	stage(nemes, {v(1): Vector2i(4, 3), v(2): at, v(3): Vector2i(5, 3)})
	for i in [1, 2, 3]:
		v(i).refresh()
		soak(v(i), 300)


static func keen() -> Effect:
	var e := Effect.new()
	e.stat = "check"
	e.amount = 60.0
	e.kind = &"defensive"
	e.tags = [&"reaction"] as Array[StringName]
	return e


func test_takes_the_hit() -> void:
	scene()
	ok(b.cast(v(3), jam, v(1)), "Jam lands")
	ok(v(1).hp == 300 and v(2).hp < 300, "v(2) took it in v(1)'s place (%d, %d)" % [v(1).hp, v(2).hp])
	ok(v(2).stat(&"jammed") > 0.0 and v(1).stat(&"jammed") <= 0.0, "all of it: Jam's interrupt too")


func test_strike() -> void:
	scene()
	ok(b.cast(v(3), strike, v(1)), "a Strike (a chain of hits)")
	ok(v(1).hp == 300 and v(2).hp < 300, "taken for it too (%d, %d)" % [v(1).hp, v(2).hp])


func test_cut() -> void:
	scene(4)
	b.cast(v(3), strike, v(1))
	ok(v(1).hp == 300 and v(2).hp == 300, "rank IV: 100%% off a hit not aimed at it (%d)" % v(2).hp)
	stage(nemes, {v(2): Vector2i(4, 4), v(3): Vector2i(5, 4)})
	b.cast(v(3), strike, v(2))
	ok(v(2).hp < 300, "a hit aimed at it lands in full")


func test_beside_only() -> void:
	scene(1, Vector2i(4, 6))
	b.cast(v(3), jam, v(1))
	ok(v(1).hp < 300 and v(2).hp == 300, "an ally out of reach of it isn't covered")


func test_jammed() -> void:
	scene()
	v(2).afflict(load("res://Effects/jammed.tres"), 2)
	b.cast(v(3), jam, v(1))
	ok(v(1).hp < 300 and v(2).hp == 300, "Jammed, it can't interject")


func test_guard() -> void:
	scene(5)
	var c := b.cast_of(v(3), jam, v(1), 1, true)
	var r := b.react(&"hit", v(1), v(3), c)
	ok(c.target == v(2) and r.guard == roundi(v(2).defense(c.tags) * 0.25 * 5), "rank V: +125%% of its Defense against the roll (%d)" % r.guard)
	v(2).learned.back().rank = 4
	c = b.cast_of(v(3), jam, v(1), 1, true)
	ok(b.react(&"hit", v(1), v(3), c).guard == 0, "not below it")


func test_describe() -> void:
	ok("ally beside it is hit" in interject.describe(1) and "25%" in interject.describe(1), interject.describe(1))
	ok("Defense" in interject.describe(5) and "Defense" not in interject.describe(4), interject.describe(5))
