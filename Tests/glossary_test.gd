extends Test

# The Glossary (terms defined once; descriptions in its markup, read plain or rich), skills' specs (the
# same target / range / AP / cost line on every skill), the Guide's pages, and the skills screen's tab
# colours (SkillTab.tone()).

static var dice := RegEx.create_from_string("(?<![0-9])d20|\\broll(s|ed)?\\b")  # damage dice (1d20) are fine


func all_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for f in DirAccess.get_files_at("res://Skills"):
		if f.ends_with(".tres"):
			out.append(load("res://Skills/" + f))
	return out


func test_markup() -> void:
	var text := "%s (%s) vs %s + {r:2} for {t:3 turns}, {x:fire}" % [Glossary.term(&"save"), Glossary.mod(&"wisdom", true), Glossary.mod(&"cha")]
	ok(Glossary.plain(text) == "Save (wis mod) vs cha mod + 2 for 3 turns, fire", Glossary.plain(text))
	var rich := Glossary.rich(text)
	ok("[url=term:save]" in rich and "[color=#%s]wis mod[/color]" % Glossary.DEFENSE.to_html(false) in rich
			and "[color=#%s]cha mod[/color]" % Glossary.OFFENSE.to_html(false) in rich, "rich: the term links to its page, the target's mod blue, the user's orange")
	ok("[color=#%s]2[/color]" % Glossary.RANK.to_html(false) in rich and "[color=#%s]fire[/color]" % Tags.color(&"fire").to_html(false) in rich, "rank gold, fire in its colour")
	ok(Glossary.plain(Glossary.term(&"held", "Holds")) == "Holds" and Glossary.rich("[1] a").begins_with("[lb]1]"), "a term in other words; brackets in text kept as text")
	ok(Glossary.page(&"save") == &"checks" and Glossary.page(&"burning") == &"ground" and Glossary.page(&"held") == &"conditions", "each term has its Guide page")


func test_no_dice_in_skills() -> void:
	var rolling: Array = []
	for s in all_skills():
		for r in [1, 2, 5]:
			var text := s.describe(r).to_lower().replace("sees the rolls of allies", "")  # Self-evaluation's whole point
			if dice.search(text):
				rolling.append("%s %d" % [s.name, r])
	ok(rolling.is_empty(), "no skill says how the dice fall - its checks go by name (%s)" % [rolling])
	var bad: Array = []
	for s in all_skills():
		if "{" in s.describe(3) or "}" in s.describe(3):
			bad.append(s.name)
	ok(bad.is_empty(), "every token reads plain (%s)" % [bad])


func test_spec() -> void:
	var odd: Array = []
	for s in all_skills():
		if s.stub or s.passive:
			continue
		var first := s.describe(1).split("\n")[0]
		var target := Glossary.name_of(s.target())
		if not first.begins_with(target + " · ") or not first.contains(" AP") or (not s.self_only and not first.contains(" · range ")):
			odd.append(first)
	ok(odd.is_empty(), "every active skill leads with its target, then its range, AP and cost (%s)" % [odd])
	var sing: Skill = load("res://Skills/sing.tres")
	ok(sing.reach_markup() == "{r:rank} + {o:cha mod}" and sing.target() == &"nearest", "range: what grows with rank gold, the user's mod orange")
	var hide: Skill = load("res://Skills/hide.tres")
	ok(hide.spec().map(func(p): return p[0]) == ["", "AP", "cost"], "on itself: no range")
	ok(load("res://Skills/strike.tres").markup(1, false).split("\n")[0] != load("res://Skills/strike.tres").spec_line(), "the skills screen takes the spec apart")


func test_guide() -> void:
	for id in Guide.ids():
		ok(Guide.text(id) != "", "the %s page has something on it" % id)
	ok("Save" in Guide.text(&"checks") and "d20" in Guide.text(&"checks") and "Burning" in Guide.text(&"ground"), "the d20s live in the Guide")
	ok(Guide.terms(&"checks").has(&"attack") and not Guide.terms(&"checks").has(&"burning"), "each Glossary page, its kinds' terms")


func test_tab_colours() -> void:
	var t := SkillTab.new()
	t.kind = "General"
	t.category = &"martial"
	ok(t.tone() == Color("#d27a70"), "Martial: a light, slightly muted red")
	t.category = &""
	ok(t.tone().s < 0.1 and t.tone().v < 0.55, "the base General tree: dark gray")
	var seen := {}
	for f in DirAccess.get_files_at("res://Roles"):
		if f.ends_with(".tres"):
			for tab: SkillTab in (load("res://Roles/" + f) as Role).trees():
				seen[tab.title()] = tab.tone()
	ok(seen.values().all(func(c: Color): return c != Color(0.6, 0.63, 0.7)), "every class's tabs have a colour of their own: %s" % [seen.keys()])
	ok(seen["Divinity: Sol"] != seen["Divinity: Luun"] and seen["Patron: Elmon"] != seen["Patron: Hogel"], "gods and patrons apart")
