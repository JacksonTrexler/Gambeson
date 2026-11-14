extends Test

# Tag colours (Tags.COLOR, Tags.color()) and item trim (Tags.mark(), Item.trim()): every tag has a
# colour, a child takes its parent's, an unknown word is neutral; an item is trimmed in its first
# coloured tag that isn't a plain word (material, form, weight, quality); mechanic.py asks a colour of
# every new tag and fails one without.


func test_color_reader() -> void:
	ok(Tags.color(&"fire") == Tags.COLOR[&"fire"], "a tag's own colour")
	ok(Tags.color(&"slash") == Tags.color(&"physical") and &"slash" not in Tags.COLOR, "a child without its own takes its parent's")
	ok(Tags.color(&"no_such_word") == Tags.NEUTRAL and not Tags.coloured(&"no_such_word"), "an unknown word: neutral")
	ok(Glossary.colour(&"burning") == Tags.color(&"burning"), "Glossary links read the same table")
	ok(Glossary.colour(&"attack") == Glossary.KINDS[&"check"], "a generic term keeps its kind's colour")


func test_every_tag_coloured() -> void:
	var missing: Array[StringName] = []
	for t: StringName in Glossary.TERMS:
		if not Tags.coloured(t):
			missing.append(t)
	for c: StringName in Tags.PARENT:
		if not Tags.coloured(c) or not Tags.coloured(Tags.PARENT[c]):
			missing.append(c)
	for f in DirAccess.get_files_at("res://Items"):
		for t in (load("res://Items/" + f) as Item).tags:
			if not Tags.coloured(t):
				missing.append(t)
	ok(missing.is_empty(), "every Glossary term, parent tag and item tag has a colour: %s" % ", ".join(missing))


func test_mark() -> void:
	ok(Tags.mark([&"metal", &"heavy", &"fire"]) == &"fire", "plain words are passed over")
	ok(Tags.mark([&"ring", &"gem"]) == &"", "all plain: no mark")
	ok(Tags.mark([&"martial", &"slash", &"fire"], Tags.BROAD) == &"fire", "skip passes over the broad words and their children")
	ok(Tags.mark([&"slash"]) == &"slash", "a child with its parent's colour marks")


func test_trim() -> void:
	var it := Item.new()
	it.tags = [&"metal", &"heavy", &"fire"]
	ok(it.trim_tag() == &"fire" and it.trim() == Tags.color(&"fire"), "Ignauldron-like: fire trim")
	it.tags = [&"light", &"cloth"]
	ok(it.trim_tag() == &"" and it.trim().a == 0.0, "light on an item is its weight, not the element: no trim")
	it.tags = [&"insignia", &"water"]
	ok(it.trim() == Tags.color(&"water"), "an emblem carrying a tag (a Water Insignia) is trimmed in it, whatever its form word")
	ok((load("res://Items/burning_bag.tres") as Item).trim_tag() == &"fire", "Burning Bag: unique is plain, fire trims")
	ok((load("res://Items/heart_up.tres") as Item).trim_tag() == &"astral", "Heart Up: astral")
	ok((load("res://Items/quartz_ring.tres") as Item).trim_tag() == &"", "Quartz Ring: ring and gem are plain")


func test_tool() -> void:
	var py := ProjectSettings.globalize_path("res://Util/mechanic.py")
	var out := []
	var code := OS.execute("python3", [py, "tag", "zz_probe", "--kind", "damage", "--define", "A probe.", "--dry-run", "--no-test"], out, true)
	if code == -1 or code == 127:
		print("tag_colors_test: no python3, skipped")
		return
	ok(code != 0 and "--color" in "".join(out), "a new tag without a colour or parent is refused")
	out.clear()
	code = OS.execute("python3", [py, "tag", "zz_probe", "--kind", "damage", "--define", "A probe.", "--color", "#7fd04a", "--dry-run", "--no-test"], out, true)
	ok(code == 0 and '&"zz_probe": Color("#7fd04a")' in "".join(out), "with --color it goes into Tags.COLOR")
	out.clear()
	code = OS.execute("python3", [py, "tag", "zz_probe", "--kind", "damage", "--define", "A probe.", "--parent", "physical", "--dry-run", "--no-test"], out, true)
	ok(code == 0, "a child may take its parent's colour")
	out.clear()
	code = OS.execute("python3", [py, "color", "fire", "red", "--dry-run"], out, true)
	ok(code != 0, "a colour is #rrggbb")


func test_trim_shows() -> void:
	var u := v(1)
	ok(u.banner != null and u.banner.get_parent() == u.sprite, "a unit carries its banner on its sprite (a silhouette hides it too)")
	u.trinket = load("res://Items/burning_bag.tres")
	ok(HUD.trims(u).any(func(t: Array) -> bool: return t[0] == Tags.color(&"fire") and t[1] == "Burning Bag"), "the card shows a fire banner for a Burning Bag")
	u.trinket = load("res://Items/quartz_ring.tres")
	ok(not HUD.trims(u).any(func(t: Array) -> bool: return t[1] == "Quartz Ring"), "an untrimmed ring shows nothing")
	u.trinket = null
	var m := UnitCard.trim_mark(Color(0, 0, 0, 0), "")
	ok(m.custom_minimum_size == Vector2(7, 10), "an untrimmed item's mark keeps the space, so sheet rows line up")
	m.free()
