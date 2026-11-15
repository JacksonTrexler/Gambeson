extends Test

# Gallantry (Skills/gallantry.tres, Behaviours/gallantry.gd): a Paladin (Chivalry) reaction. When a foe
# attacks an ally beside it, a cha check against the attacker, before the roll; passing, it becomes the
# target, and the attack is locked on it: no later reaction (Interject) turns it aside.

var gallantry: Skill = load("res://Skills/gallantry.tres")
var interject: Skill = load("res://Skills/interject.tres")
var jam: Skill = load("res://Skills/jam.tres")


func scene() -> void:
	v(2).learned.append(slot(gallantry))
	v(2).afflict(keen(), 9)
	v(3).learned.append(slot(jam))
	v(3).dexterity = 40
	stage(nemes, {v(1): Vector2i(4, 3), v(2): Vector2i(4, 4), v(3): Vector2i(5, 3)})
	for i in [1, 2, 3]:
		v(i).refresh()
		soak(v(i), 300)


static func keen() -> Effect:
	return (load("res://Tests/interject_test.gd") as GDScript).keen()


func test_becomes_the_target() -> void:
	scene()
	var rolls := []
	b.attacked.connect(func(_c: Unit, t: Unit, _d: int, _tot: int, _def: int): rolls.append(t))
	ok(b.cast(v(3), jam, v(1)), "Jam lands")
	ok(v(1).hp == 300 and v(2).hp < 300 and rolls == [v(2)], "v(2) became the target, before the roll (%d, %d)" % [v(1).hp, v(2).hp])


func test_locked() -> void:
	scene()
	v(1).learned.append(slot(interject, 4))
	v(1).afflict(keen(), 9)
	b.cast(v(3), jam, v(1))
	ok(v(1).hp == 300 and v(2).hp < 300, "v(1)'s Interject can't take it back")


func test_not_beside() -> void:
	scene()
	stage(nemes, {v(1): Vector2i(4, 3), v(2): Vector2i(4, 6), v(3): Vector2i(5, 3)})
	b.cast(v(3), jam, v(1))
	ok(v(1).hp < 300 and v(2).hp == 300, "an ally not beside it isn't covered")


func test_describe() -> void:
	ok("attacked" in gallantry.describe(1) and "cha" in gallantry.describe(1), gallantry.describe(1))
	ok(load("res://Roles/paladin.tres").roots[0].branch(gallantry) != null, "on the Paladin's Chivalry")
