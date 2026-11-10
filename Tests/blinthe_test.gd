extends Test

# Blinthe (Scenes/blinthe.tscn): a level 16 bard, unaligned - his own side - with clout among Lancin and
# Nemes, Bandwagon III and Molothrus III. Made with Util/unit.py, the example of a unit with a bio.

func test_blinthe() -> void:
	var bl: Unit = load("res://Scenes/blinthe.tscn").instantiate()
	ok(bl.level == 16 and bl.role == load("res://Roles/bard.tres") and bl.faction == load("res://Factions/unaligned.tres"), "a level 16 bard, his own side")
	ok(bl.bio.behaviour == &"timid" and bl.bio.appearance == "Minstrel" and bl.bio.text.begins_with("While he seemed"), "his bio")
	ok(bl.bio.clout[lancin] == 3 and bl.bio.clout[nemes] == 2, "clout with both sides")
	var ranks := {}
	for x in bl.learned:
		ranks[x.skill.resource_path.get_file().get_basename()] = x.rank
	ok(ranks.get("bandwagon") == 3 and ranks.get("molothrus") == 3 and ranks.get("persona") == 3, "Bandwagon III, Molothrus III, Personify III")
	ok(bl.look != null, "a sprite (a placeholder until art replaces Units/Blinthe.png)")
	bl.free()
