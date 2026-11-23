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


# The AI weighs the reactions it reads on its targets' side (item 3 of docs/plans/gaps-react-marks.md, through
# Behaviour.foils()): of two otherwise alike foes it strikes the one with no Gallantry Paladin beside it; one
# it can't read (no recon of skills) it can't weigh, and a Paladin out of reach is nothing to it.
func test_ai_weighs_it() -> void:
	v(1).learned.append(slot(jam))
	v(4).learned.append(slot(gallantry))
	v(4).afflict(keen(), 9)
	v(2).faction = nemes
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(2): Vector2i(3, 3), v(4): Vector2i(6, 4)})
	for i in [1, 2, 3, 4]:
		v(i).refresh()
		soak(v(i), 300)
	v(1).dexterity = 40
	var reads := AI.reads_from({v(3): b.read(v(1), v(3)), v(2): b.read(v(1), v(2)), v(4): b.read(v(1), v(4))})
	ok(AI._foiled(b, v(1), jam, v(3), reads) == 0.0, "its recon reads no skills: nothing to weigh")
	sharp(v(1))
	reads = {v(3): b.read(v(1), v(3)), v(2): b.read(v(1), v(2)), v(4): b.read(v(1), v(4))}
	var f := AI._foiled(b, v(1), jam, v(3), reads)
	ok(f > 0.5 and f <= AI.FOILED and AI._foiled(b, v(1), jam, v(2), reads) == 0.0, "read, a Paladin beside the target foils the blow (%.2f), and not one elsewhere's" % f)
	var log: Array[String] = []
	ok(AI._strike(b, v(1), reads, log) and "Villager2" in log[0], "it strikes the unguarded foe, not the first alike (%s)" % [log])
	b.move(v(4), Vector2i(9, 9))
	ok(AI._foiled(b, v(1), jam, v(3), reads) == 0.0, "Gallantry out of reach of the target: nothing")
