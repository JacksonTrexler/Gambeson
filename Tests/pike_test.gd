extends Test

# Pike (Scenes/pike.tscn): a level 2 ambush fish, unaligned, aggressive, Aquatic (water costs it 1 to
# enter and it can't drown: aquatic_test). The shape a Thalassic Druid takes on water (Battle.FORMS:
# nature_test.test_beastshape).

var scene: PackedScene = load("res://Scenes/pike.tscn")
var side: Faction = load("res://Factions/unaligned.tres")


func bring() -> Unit:
	var u: Unit = b.summon(scene, side, Vector2i(5, 3))
	stage(side, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 3)})
	b.move(u, Vector2i(5, 3))
	return u


func test_pike() -> void:
	var u := bring()
	ok(u.bio.behaviour == &"aggressive" and u.bio.appearance == "Fish" and u.level == 2 and u.faction == side, "a level 2 aggressive fish, its own side")
	ok(u.has_tag(&"aquatic") and u.has_tag(&"beast") and u.bio.properties.any(func(p: Property): return p.name == "Aquatic"), "Aquatic, a beast")
	ok(b._cost(u, Battle.PLAIN, load("res://Terrain/water.tres")) == 1.0, "water costs it 1")
	ok(u.learned.any(func(x: Slot): return x.skill == strike), "it bites (Strike)")
	var r := b.read(sharp(v(1)), u)
	ok(r.level == 2, "read with recon: level 2")
