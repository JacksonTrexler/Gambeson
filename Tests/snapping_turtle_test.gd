extends Test

# Snapping Turtle (Skills/snapping_turtle.tres, Behaviours/snapping_turtle.gd): using an offensive skill on
# a foe, its holder sets off up to rank of its other defensive reactions, top to bottom of its hotbar (the
# trigger &"snap"). Interject snapped: its dex check against the target; passing, the attack is locked -
# the target's side can't turn it aside (Gallantry).

var snapping: Skill = load("res://Skills/snapping_turtle.tres")
var interject: Skill = load("res://Skills/interject.tres")
var gallantry: Skill = load("res://Skills/gallantry.tres")
var jam: Skill = load("res://Skills/jam.tres")


# v(1) (Lancin, its turn) Jams v(3), sure to hit; v(4), beside v(3), has Gallantry, sure to pass.
func scene(turtle := 1) -> void:
	if turtle > 0:
		v(1).learned.append(slot(snapping, turtle))
	v(1).learned.append(slot(interject))
	v(1).learned.append(slot(jam))
	v(1).dexterity = 40
	v(1).afflict(keen(), 9)
	v(4).learned.append(slot(gallantry))
	v(4).afflict(keen(), 9)
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	for i in [1, 3, 4]:
		v(i).refresh()
		v(i).max_hp = 300
		v(i).hp = 300


static func keen() -> Effect:
	return (load("res://Tests/interject_test.gd") as GDScript).keen()


func test_without() -> void:
	scene(0)
	b.cast(v(1), jam, v(3))
	ok(v(3).hp == 300 and v(4).hp < 300, "without it, Gallantry turns the attack aside")


func test_snaps() -> void:
	scene()
	var got := []
	b.reacted.connect(func(u: Unit, s: Skill, r: Behaviour.Reaction): got.append([u, s, r.trigger]))
	b.cast(v(1), jam, v(3))
	ok(v(3).hp < 300 and v(4).hp == 300, "Interject snapped: the attack is locked on its target")
	ok(got.size() == 2 and got[0] == [v(1), interject, &"snap"] and got[1] == [v(1), snapping, &"attacked"], "told: %s" % [got])


func test_offensive_only() -> void:
	scene()
	var c := b.cast_of(v(1), strike, v(3), 1, true)
	b.react(&"attacked", v(3), v(1), c)
	ok(c.target == v(4), "Strike isn't tagged offensive: nothing snaps, Gallantry swaps")


func test_rank() -> void:
	scene()
	var c := b.cast_of(v(1), jam, v(3), 1, true)
	var r := Behaviour.Reaction.new()
	r.battle = b
	r.trigger = &"attacked"
	r.subject = v(3)
	r.by = v(1)
	r.cast = c
	r.skill = snapping
	v(1).timed.clear()
	var e := effect("check", 60.0)
	e.kind = &"offensive"
	v(3).afflict(e, 9)  # the target's +60 against it: Interject's check fails, nothing snapped
	ok(not snapping.behaviours[0].react(r, v(1), 1) and not r.locked and r.trigger == &"attacked" and r.subject == v(3), "nothing that reacts: it didn't, and the moment is as it was")


func test_describe() -> void:
	ok("offensive" in snapping.describe(2) and "2" in snapping.describe(2), snapping.describe(2))
