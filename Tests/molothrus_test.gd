extends Test

# Molothrus (Skills/molothrus.tres, Behaviours/molothrus.gd): those its holder fools within rank tiles
# feed it rank x 10% of each heal they get, and take rank x 20% of each hit it takes, shared. Its persona
# goes by Precious. Blinthe has it at III; his clout with Lancin (3) is trickery enough to fool villagers.

const MOLOTHRUS := preload("res://Behaviours/molothrus.gd")
var molothrus: Skill = load("res://Skills/molothrus.tres")


func blinthe(near: Dictionary) -> Unit:
	var bl: Unit = b.summon(load("res://Scenes/blinthe.tscn"), load("res://Factions/unaligned.tres"), Vector2i(5, 3))
	stage(lancin, near)
	b.move(bl, Vector2i(5, 3))
	bl.max_hp = 200
	bl.hp = 100
	return bl


func test_shield() -> void:
	var bl := blinthe({v(1): Vector2i(4, 3), v(2): Vector2i(9, 7)})
	ok(Perception.fools(b, v(1), bl) and MOLOTHRUS.fooled(b, bl, 3) == ([v(1)] as Array[Unit]), "v(1), beside him, is fooled; v(2) is out of range")
	var was := v(1).hp
	var took := bl.hit(10, [&"physical"] as Array[StringName])
	var passed := was - v(1).hp
	ok(passed == roundi((took + passed) * 0.6), "III: 60%% goes to the one he fools (%d of %d)" % [passed, took + passed])
	b.move(v(2), Vector2i(5, 4))
	v(1).hp = was
	v(2).hp = was
	took = bl.hit(10, [&"physical"] as Array[StringName])
	ok(was - v(1).hp == was - v(2).hp and was - v(1).hp > 0, "two fooled: they share it (%d each)" % (was - v(1).hp))


func test_siphon() -> void:
	var bl := blinthe({v(1): Vector2i(4, 3)})
	v(1).hp = 1
	v(1).heal(10)
	ok(v(1).hp == 8 and bl.hp == 103, "III: 30%% of the heal goes to him (v(1) %d, Blinthe %d)" % [v(1).hp, bl.hp])
	b.move(v(1), Vector2i(1, 1))
	v(1).heal(10)
	ok(bl.hp == 103, "out of range: nothing")


func test_precious() -> void:
	var bl := blinthe({v(1): Vector2i(4, 3)})
	ok(bl.alias == "Precious Friend", "his persona goes by Precious: %s" % bl.alias)
	ok(molothrus.describe(3).contains("30%") and molothrus.describe(3).contains("60%"), molothrus.describe(3))
