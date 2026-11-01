extends Test

# Items: effects on their wearer (Burning Blade: str mod to max HP), a trinket slot, hearts (Heart Up,
# Heart Up-Link), Starblade's Power back on a melee hit, loot tables (Loot), what a battle's victor
# takes home (Battle.winnings(), Game.stash), and the character sheet that puts them on.

var blade: Item = load("res://Items/burning_blade.tres")
var starblade: Item = load("res://Items/starblade.tres")
var link: Item = load("res://Items/heart_up_link.tres")
var heart_up: Item = load("res://Items/heart_up.tres")
var heart: Item = load("res://Items/heart.tres")


func test_burning_blade() -> void:
	var hp := v(1).max_hp
	ok(v(1).equip(blade) == null and v(1).weapon == blade and v(1).max_hp == hp + 1, "str 12 (+1): max HP +1")
	v(1).strength = 6
	v(1).refit()
	ok(v(1).max_hp == hp - 2, "str 6 (-2): even negative")
	v(1).charisma = 16
	ok(v(1).wielded(&"strength") == &"charisma", "strength attacks use the best of cha, wis and int")
	ok(v(1).unequip("weapon") == blade and v(1).max_hp == hp, "taken off: as it was")
	ok("Max HP: +1 per str mod" in blade.describe(), blade.describe())


func test_hearts_from_items() -> void:
	v(1).constitution = 9  # mod -1
	ok(not v(1).can_wear(link) and v(1).equip(link) == null and v(1).armor == null, "Heart Up-Link needs a positive con mod")
	v(1).constitution = 14  # mod 2
	v(1).equip(link)
	v(1).equip(heart_up)
	ok(v(1).trinket == heart_up and v(1).lives() == 3 and v(1).lives_left() == 3, "con mod (2) lives, and Heart Up's one")
	ok(v(1).armor_defense() == v(1).level + 2, "Defense: level + the higher of con mod and hearts spent")
	v(1).hearts_used = 3
	ok(v(1).armor_defense() == v(1).level + 3 and v(1).defense() == v(1).level + 3 + 3, "3 spent: +3, and Heart Up's +3 on top")
	ok("con mod extra lives while worn" in link.describe() and "Gives 1 extra life for good" in heart.describe(), link.describe() + " / " + heart.describe())


func test_starblade() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).weapon = starblade
	v(1).max_energy = 20
	v(1).energy = 0
	var at := 0
	for i in 30:
		v(1).refresh()
		var was := v(3).hp
		b.cast(v(1), strike, v(3))
		if v(3).hp < was:
			at = v(1).energy
			break
	ok(at > 0, "a melee hit: Power back (%d)" % at)
	v(1).energy = 0
	v(1).weapon = null
	b.cast(v(1), strike, v(3))
	ok(v(1).energy == 0, "without it, nothing")


func test_loot() -> void:
	var loot: Loot = load("res://Loot/astral_princess.tres")
	var got := {}
	for i in 400:
		var it := loot.roll(b.rng)
		got[it.name] = got.get(it.name, 0) + 1
	ok(got.get("Heart Up", 0) > 60 and got.get("Heart Up", 0) < 140 and got.get("Heart", 0) > 260, "one of them, 25%% / 75%%: %s" % [got])
	ok(loot.describe() == "Heart Up (25%) or Heart (75%)", loot.describe())
	stage(lancin, {v(1): Vector2i(1, 1), b.get_node("Units/Icor"): Vector2i(5, 5)})
	var icor: Unit = b.get_node("Units/Icor")
	var dropped := []
	b.dropped.connect(func(u: Unit, it: Item): dropped.append([u, it]))
	icor.hp = 0
	ok(dropped == [[icor, blade]] and b.spoils == [[blade, nemes]], "a commander drops its loot as it falls")
	ok(b.phase == Battle.Phase.OVER and b.winnings(lancin) == [blade] and b.winnings(nemes).is_empty(), "the victor takes it home")
	b.rewards = [heart]
	ok(b.winnings(lancin) == [blade, heart], "with the scenario's rewards")


func test_sheet() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	Game.stash.assign([blade, heart, link])
	h.select(v(1))
	h.toggle_sheet()
	ok(h.sheet.visible and h.sheet.unit == v(1), "the character icon opens the selected unit's sheet")
	var buttons := h.sheet.find_children("*", "Button", true, false).map(func(x: Button): return x.text)
	ok(buttons.count("Equip") == 2 and buttons.count("Use") == 1, "Burning Blade and Heart Up-Link (con +1) to equip, a Heart to use: %s" % [buttons])
	h._on_equipped(v(1), blade)
	ok(v(1).weapon == blade and blade not in Game.stash and Game.outfit == {"weapon": blade}, "equipped from the stash, and kept for next battle")
	Game.stash.append(starblade)
	h._on_equipped(v(1), starblade)
	ok(v(1).weapon == starblade and blade in Game.stash, "what it replaces goes back")
	h._on_used_up(v(1), heart)
	ok(v(1).hearts == 1 and v(1).lives_left() == 1 and Game.hearts == 1 and heart not in Game.stash, "a Heart: an extra life, for good")
	b.end_turn()
	h._on_unequipped(v(1), "weapon")
	ok(v(1).weapon == starblade, "not on another side's turn")
	h.free()
	Game.stash.clear()
	Game.outfit = {}
	Game.hearts = 0
