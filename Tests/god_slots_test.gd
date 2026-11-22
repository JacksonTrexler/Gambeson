extends Test

# One god system (God, Gods/*.tres): a god or patron offers its own tree and a pool of trees, each of
# a kind; a class's slots (TreeChoice.kinds) pick from its god's pool (Unit.offered()), a slot with no
# real choice opening what's on offer (Unit.picks()), and a Cleric's god chosen on its own tab grants its
# domain trees (TreeChoice.grants).

func titles(ts: Array) -> Array:
	return ts.map(func(t: SkillTab): return t.title())


func make(role: String, god := &"") -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/%s.tres" % role), name = "Pip"})
	b.get_node("Units").add_child(u)
	if god:
		u.god = god
	return u


func test_gods() -> void:
	ok(God.pantheon().size() == 7, "seven gods")
	for g in God.pantheon():
		ok(g.domains != "" and g.tag != &"", "%s has domains and a damage tag" % g.id)
		ok(g.offers(["Prowess"]).size() >= 2, "%s: at least two prowesses (?69)" % g.id)
	ok(God.of(&"elmon").patron and God.of(&"hogel").patron and God.of(&"hogel").own.satisfied_by == &"rest_whole", "patrons are gods too")
	ok(titles(God.of(&"eros").offers(["Prowess"])) == ["Prowess: Protector", "Prowess: Vanguard"] and titles(God.of(&"sol").offers(["School"])) == ["School: Radiance"],
			"Eros's prowesses as before; Sol's domain caster tree, Radiance")


func test_cleric() -> void:
	var u := make("cleric")
	var god: TreeChoice = u.role.choices[0]
	var domain: TreeChoice = u.role.choices[1]
	ok(titles(u.offered(god)) == ["Divinity: Eros", "Divinity: Luun", "Divinity: Sol"] and u.offered(domain).is_empty(), "a god to pick; no domain without one")
	ok(u.pick(god, God.of(&"sol").own) and titles(u.class_trees()) == ["Cleric", "Divinity: Sol", "School: Radiance"], "Sol picked: its Divinity and its domain tree, Radiance, granted")
	ok(u.pick_missing(domain, God.of(&"sol").pool[3]) == "Picked", "granted: nothing to pick")
	var e := make("cleric")
	ok(e.pick(god, God.of(&"eros").own) and titles(e.class_trees()) == ["Cleric", "Divinity: Eros"], "Eros offers no domain caster tree yet")


func test_paladin() -> void:
	var u := make("paladin", &"sol")
	var c := u.role.choices
	ok(titles(u.offered(c[1])) == ["Divinity: Sol"] and titles(u.picks(c[1])) == ["Divinity: Sol"], "a Sol Paladin's Domain: Sol's Divinity, no choice so no pick")
	ok(titles(u.offered(c[2])) == ["Prowess: Protector", "Prowess: Vanguard", "Prowess: Fury", "Divinity: Sol", "School: Radiance"] and u.picks(c[2]).is_empty(),
			"its Flex: whatever Sol offers (%s)" % [titles(u.offered(c[2]))])
	ok(u.pick(c[0], God.of(&"sol").pool[0]) and u.pick_missing(c[2], God.of(&"sol").pool[0]) == "Picked", "Protector as its Prowess: not again as its Flex")
	ok(u.pick_missing(c[2], God.of(&"sol").own) == "Picked" and u.pick(c[2], God.of(&"sol").pool[3]), "Radiance as its Flex")
	ok(titles(u.class_trees()) == ["Paladin", "Prowess: Protector", "Divinity: Sol", "School: Radiance"], "%s" % [titles(u.class_trees())])
	var war := make("paladin", &"ramut")
	ok(war.offered(c[1]).is_empty() and war.pick_missing(c[1], God.of(&"sol").own) == "Not Ramut's way", "Ramut offers no Divinity yet")
