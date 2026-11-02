extends Test

# Allied sides (Faction.allies, Faction.friends()): they don't fight each other, win together, and
# don't take each other's orders; the Astral Envoy's Wayfarers (the other starters, Battle.companions).
# And a Dagger's edge on the initiative roll.

var wayfarers: Faction = load("res://Factions/wayfarers.tres")


func test_friends() -> void:
	var a := Faction.new()
	var c := Faction.new()
	ok(not Faction.friends(a, c), "strangers")
	a.allies = [c]
	ok(Faction.friends(a, c) and Faction.friends(c, a), "allied, either way")
	v(3).faction = a
	v(1).faction = c
	stage(c, {v(1): Vector2i(4, 1), v(3): Vector2i(5, 1)})
	v(1).refresh()
	ok(b.read(v(1), v(3)).attitude(v(1)) == &"ally" and not b.cast(v(1), strike, v(3)), "an ally isn't attacked")


func test_envoy_companions() -> void:
	Game.starter = {faction = lancin, role = load("res://Roles/rogue.tres"), name = "Vex"}
	var scene: Node = load("res://Scenes/astral_envoy.tscn").instantiate()
	tree.root.add_child(scene)
	var e: Battle = scene.get_node("Battle")
	var them := e.members(wayfarers)
	ok(them.size() == 6 and them.all(func(u: Unit): return u.role.name != "Rogue"), "the other six starters: %s" % [them.map(func(u: Unit): return u.role.name)])
	ok(Faction.friends(wayfarers, lancin) and wayfarers in e.order, "their own side, allied with the player's")
	ok(them.all(func(u: Unit): return u.armor != null and u.weapon != null), "in their starting items")
	var cmd := Command.new(e, e.player)
	ok(them.all(func(u: Unit): return not cmd.can_order(u)), "the player's leader can't order them")
	ok(e.sides_left() == 2, "Lancin and the Wayfarers count as one side against the Stellar Order (Starmen are neutral): %d" % e.sides_left())
	scene.free()


func test_dagger_initiative() -> void:
	v(1).equip(load("res://Items/dagger.tres"))
	b.rng.seed = 4
	var rolls := b.roll_initiative()
	ok(b.unit_rolls[v(1)] >= 1, "rolled")
	var dagger_roll: int = b.unit_rolls[v(1)]
	v(1).unequip("weapon")
	b.rng.seed = 4
	b.roll_initiative()
	ok(dagger_roll == roundi(b.unit_rolls[v(1)] * 1.2), "the dagger's 20%% on its d20 (%d vs %d)" % [dagger_roll, b.unit_rolls[v(1)]])
	ok(rolls.size() >= 1, "")
