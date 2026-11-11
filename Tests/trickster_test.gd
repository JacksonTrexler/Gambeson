extends Test

# The Rogue's Trickster tab: trickery, persona and deception. Showmanship on the left, Deception in the
# middle up to Illusionist, and Legerdemain ?? on the right, a caster wing dipping into illusion,
# teleportation and utility magic.

var rogue: Role = load("res://Roles/rogue.tres")


func test_tab() -> void:
	var t: SkillTab = rogue.tabs.filter(func(x: SkillTab): return x.name == "Trickster")[0]
	ok(t.roots.map(func(r: SkillRoot): return r.name) == ["Showmanship", "Deception", "Legerdemain ??"], "left to right: %s" % [t.roots.map(func(r: SkillRoot): return r.name)])
	ok(t.roots.map(func(r: SkillRoot): return r.tag) == [&"specialist", &"specialist", &"magical"], "the right wing magical")
	var named := func(r: SkillRoot) -> Array:
		var out: Array = r.skills().map(func(s: Skill): return s.title())
		out.sort()
		return out
	ok(named.call(t.roots[0]) == ["Flourish ??", "Showstopper ??", "Stage Presence ??"], "Showmanship: %s" % [named.call(t.roots[0])])
	ok(named.call(t.roots[1]) == ["Double Bluff ??", "Illusionist", "Vanishing Act ??"], "Deception, up to Illusionist")
	ok(rogue.tier(load("res://Skills/illusionist.tres")) == 3, "Illusionist its capstone, tier 3")
	ok(named.call(t.roots[2]) == ["Phantasm ??", "Prestidigitation ??", "Switcheroo ??"], "Legerdemain: %s" % [named.call(t.roots[2])])
	ok("Trickster" in rogue.trees().map(func(x: SkillTab): return x.title()), "on the Rogue's skills screen, titled Trickster: %s" % [rogue.trees().map(func(x: SkillTab): return x.title())])
