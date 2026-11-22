extends Test

# Item rarity and the two quality tags. Rarity: one table (Item.RANK_COST) sets what a rank costs, in
# ranks of a common item. enchanted and honed: each is rank +1 to the item or skill carrying it
# (Item.ranked(), Unit.rank()), never both; only enchanted is what Pray (Unit.enchant()) acts on.


func test_rank_cost_table() -> void:
	var want := {"common": 1.0, "uncommon": 1.5, "rare": 2.0, "epic": 3.0, "legendary": 4.0, "mythic": 5.0}
	ok(Item.RANK_COST == want, "the table: %s" % [Item.RANK_COST])
	for r in want:
		var it := Item.new()
		it.rarity = r
		it.rank = 2
		ok(it.rank_cost() == want[r] and it.worth() == 2.0 * want[r], "%s: a rank costs %s, rank 2 is worth %s" % [r, want[r], it.worth()])
	var w: Dictionary = Item.RARITY_WEIGHT
	ok(w["common"] > w["uncommon"] and w["uncommon"] > w["rare"] and w["rare"] > w["epic"] and w["epic"] > w["legendary"] and w["legendary"] > w["mythic"] and w["mythic"] > 0.0,
			"each rarity turns up less often than the last")


func test_item_tags() -> void:
	var plain := Item.new()
	plain.rank = 2
	var ench := Item.new()
	ench.rank = 2
	ench.tags.assign([&"enchanted"])
	var hone := Item.new()
	hone.rank = 2
	hone.tags.assign([&"honed"])
	ok(plain.ranked() == 2 and ench.ranked() == 3 and hone.ranked() == 3, "enchanted and honed: rank +1 each")
	ok(plain.worth() == 2.0 and ench.worth() == 2.0 and hone.worth() == 2.0, "worth counts the rank bought, not the quality")
	var epic := Item.new()
	epic.rank = 2
	epic.tags.assign([&"honed"])
	epic.rarity = "epic"
	ok(epic.ranked() == 3 and epic.worth() == 6.0, "a higher rarity: the same +1, its rank costing more")
	ok(ench.enchanted() and not hone.enchanted() and hone.honed() and not ench.honed(), "honed never reads as enchanted")


func test_pray_skips_honed() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var blade := Item.new()
	blade.slot = "weapon"
	blade.tags = [&"honed"]
	v(1).weapon = blade
	v(1).armor = null
	ok(v(1).enchant(1) == 0 and v(1).weapon == blade and blade.enchant == 0, "Pray leaves a honed item alone")


func test_skill_tags() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var s := Skill.new()
	s.name = "Capstone"
	v(1).learned.append(slot(s, 2))
	v(1).refresh()
	ok(v(1).rank(s) == 2, "plain: its learned rank")
	s.tags.assign([&"enchanted"])
	ok(v(1).rank(s) == 3, "enchanted: +1")
	s.tags.assign([&"honed"])
	ok(v(1).rank(s) == 3, "honed: +1")
	var other := Skill.new()
	other.tags.assign([&"honed"])
	ok(v(1).rank(other) == 0, "a skill it doesn't have stays 0")


func test_exclusive() -> void:
	ok(Tags.exclusive([&"enchanted"]) and Tags.exclusive([&"honed", &"fire"]) and not Tags.exclusive([&"enchanted", &"honed"]), "never both")
	var bad: Array[String] = []
	for dir in ["res://Items", "res://Skills"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".tres"):
				var r = load(dir + "/" + f)
				if r and "tags" in r and not Tags.exclusive(r.tags):
					bad.append(f)
	ok(bad.is_empty(), "no item or skill is both enchanted and honed: %s" % [bad])
