extends Test

# Pray, by god (Battle.pray()): Sol burns darkness away, Urlo enchants allies' items, Luun lays
# darkness that hides only its side, Drael takes debuff ranks off an ally (Battle.cleanse()), and
# Vetruvis turns the ground to disturbed earth its enemies wade through (Battle.wading()).

var pray: Skill = load("res://Skills/pray.tres")


func prayer(u: Unit, god: StringName, r: int) -> void:
	u.god = god
	if not u.learned.any(func(x: Slot): return x.skill == pray):
		u.learned.append(slot(pray, r))
	u.learned.filter(func(x: Slot): return x.skill == pray)[0].rank = r
	u.refresh()


func test_domains() -> void:
	ok(God.of(&"ramut").domains == "war, power" and God.of(&"eros").domains == "love, healing" and God.of(&"vetruvis").domains == "earth, music", "domains")
	ok(God.tag_of(&"ramut") == &"physical" and God.tag_of(&"drael") == &"water" and God.tag_of(&"hogel", &"fire") == &"fire", "damage tags, by god (a patron has none: the fallback)")
	var text := pray.describe(2)
	for g in ["Ramut", "Eros", "Sol", "Urlo", "Luun", "Drael", "Vetruvis"]:
		ok(g + ":" in text, "described: %s" % g)


func test_sol() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	var levels: Dictionary[Vector2i, int] = {Vector2i(2, 4): 2, Vector2i(6, 4): 1}
	b.zones.append(Battle.Zone.new(&"dark", levels, 3, nemes))
	prayer(v(1), &"sol", 2)
	ok(b.cast(v(1), pray, v(1)) and b.zones.size() == 1 and b.zones[0].levels.keys() == [Vector2i(6, 4)], "darkness within 2 tiles is gone; 5 off, it stays")
	prayer(v(1), &"sol", 5)
	ok(b.cast(v(1), pray, v(1)) and b.zones.is_empty(), "rank 5: all of it, and the empty zone with it")


func test_urlo() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(2): Vector2i(2, 4), v(3): Vector2i(3, 4)})
	var rapier: Item = load("res://Items/rapier.tres")
	var gambeson: Item = load("res://Items/gambeson.tres")
	for u in [v(1), v(2), v(3)]:
		u.weapon = rapier
		u.armor = gambeson
	var before := v(1).defense()
	prayer(v(1), &"urlo", 1)
	ok(b.cast(v(1), pray, v(1)) and v(1).weapon.enchant == 1 and v(1).armor.enchant == 0 and rapier.enchant == 0, "rank 1: its own weapon first, a copy of its own")
	ok(v(1).weapon_bonus(&"strength") == 1 and v(1).weapon_bonus(&"intelligence") == 0, "+1 damage on strength attacks")
	prayer(v(1), &"urlo", 2)
	ok(b.cast(v(1), pray, v(1)) and v(1).armor.enchant == 1 and v(1).defense() == before + 1 and v(2).weapon.enchant == 1 and v(2).armor.enchant == 0,
			"rank 2: its armor (+1 Defense), then the nearest ally's weapon; the enchanted aren't done again")
	ok(v(3).weapon.enchant == 0, "enemies' gear: never")
	ok("enchanted +1" in v(1).armor.describe(), v(1).armor.describe())
	var blade := Item.new()
	blade.slot = "weapon"
	blade.tags = [&"enchanted"]
	var plain := Item.new()
	plain.slot = "weapon"
	plain.enchanted_as = blade
	v(2).weapon = plain
	v(2).armor = null
	prayer(v(1), &"urlo", 3)
	ok(b.cast(v(1), pray, v(1)) and v(2).weapon == blade and v(2).weapon.enchant == 0, "an item with its own enchantment becomes that instead")


func test_luun() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(2): Vector2i(1, 5), v(3): Vector2i(3, 4)})
	prayer(v(1), &"luun", 2)
	var seen := b.read(v(3), v(1)).net
	ok(b.cast(v(1), pray, v(1)) and b.zones.size() == 1 and b.zones[0].allied and b.zones[0].turns == 2
			and Vector2i(3, 4) in b.zones[0].levels and b.zones[0].levels.keys().all(func(c: Vector2i): return Command.tiles(c, v(1).cell) <= 2),
			"darkness on the ground within 2 tiles, for 2 turns")
	var dark: Dictionary = b.zones[0].levels
	ok(v(1).cell in dark and Perception.cover(b, v(1)) == 1, "its own tile among them: concealment 1")
	ok(b.read(v(3), v(1)).net == seen - 1 and b.read(v(2), v(1)).net >= 0, "its enemies make it out a level less; its allies see it plainly")
	b.move(v(3), dark.keys().filter(func(c: Vector2i): return c != v(1).cell)[0])
	ok(Perception.cover(b, v(3)) == 0, "an enemy standing in it isn't hidden by it")
	ok(b.read(v(3), Vector2i(1, 4)).hint == "", "and the ground isn't shrouded")


func test_drael() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(2): Vector2i(2, 4), v(3): Vector2i(8, 1)})
	var bleed: Effect = (load("res://Skills/snare.tres") as Skill).lays.wounds[0]
	var hex: Skill = load("res://Skills/hex.tres")
	v(2).afflict(bleed, 5, 3)
	v(2).afflict(hex.effects[0], 5, 1)
	v(2).afflict(effect("luck", 2), 5, 4)  # a buff: not Drael's to lift
	prayer(v(1), &"eros", 2)
	ok(not b.cast(v(1), pray, v(2)), "to Eros: only on itself")
	prayer(v(1), &"drael", 2)
	ok(b.cast(v(1), pray, v(2)) and v(2).timed[bleed].rank == 1 and v(2).timed[hex.effects[0]].rank == 1, "2 ranks off the highest-ranked debuff first: Bleeding 3 -> 1")
	prayer(v(1), &"drael", 3)
	ok(b.cast(v(1), pray, v(2)) and bleed not in v(2).timed and hex.effects[0] not in v(2).timed, "then the rest of it, and the Hex")
	ok(v(2).timed.size() == 1, "the buff stays")
	b.move(v(2), Vector2i(5, 4))
	v(1).refresh()
	ok(not b.cast(v(1), pray, v(2)), "range: rank (3) tiles; 4 off is too far")
	ok(b.cast(v(1), pray, v(1)), "on itself, too")


func test_vetruvis() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	prayer(v(1), &"vetruvis", 1)
	ok(b.cast(v(1), pray, v(1)) and Vector2i(2, 4) in b.earthworks and Vector2i(3, 4) not in b.earthworks and b.earthworks[Vector2i(2, 4)].turns == 1,
			"the ground within 1 tile, for 1 turn")
	ok(is_equal_approx(b.step(v(3), Vector2i(3, 4), Vector2i(2, 4)), 1.5) and is_equal_approx(b.step(v(1), Vector2i(1, 4), Vector2i(2, 4)), 1.0),
			"its enemies pay 50% more to enter; its side, nothing")
	ok(is_equal_approx(b.step(v(3), Vector2i(3, 4), Vector2i(4, 4)), 1.0), "outside it: as before")
	b.end_turn()
	ok(b.earthworks.is_empty(), "gone as its side's turn ends")
