extends Test

# The Sorcerer (Roles/sorcerer.tres): a caster of the Astral - its tree Stellar Soul ("Beings with a heart
# that originated from and yearns for the Astral."), rooted in Powerful (its Energy is Power: grants arrive
# as Power, it never regenerates), borrowing the astral creatures' spells as they are - the Starmote's
# Energy Missile, the Starman's Starsap - and, as a caster, Energy Transfer on the general Caster tree.

func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func sorcerer() -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/sorcerer.tres"), name = "Astrid"})
	b.get_node("Units").add_child(u)
	return u


func test_sorcerer() -> void:
	var u := sorcerer()
	ok(u.role.name == "Sorcerer" and u.role.noun == "Caster" and u.role.god == &"urlo", "a Sorcerer, a Caster to the eye, of Urlo (magic, energy)")
	ok(u.charisma == 15 and u.intelligence == 10 and u.wisdom == 12 and u.strength == 8, "caster stats, cha over int (Energy Missile is a cha spell)")
	ok(u.pools().is_empty(), "no Mana: it runs on Energy, and Power once Powerful")
	ok(&"magical" in u.role.general, "the general Caster tree")
	var items: Array = u.role.items.map(func(it: Item): return it.name)
	ok(items == ["Robe", "Staff", "Energy Potion"], "a robe and a staff like the Mage and Wizard, an Energy Potion for their Mana Potion (%s)" % [items])


func test_tree() -> void:
	var u := sorcerer()
	var tree: SkillRoot = load("res://Trees/stellar_soul.tres")
	ok(tree.name == "Stellar Soul" and tree in u.role.roots, "its own tree: Stellar Soul")
	ok(tree.branches[0].skill == sk("powerful") and tree.branches[0].after.is_empty(), "its root: Powerful")
	ok(tree.branch(sk("energy_missile")).after == [sk("powerful")] and tree.branch(sk("starsap")).after == [sk("energy_missile")], "then Energy Missile, then Starsap")
	ok(tree.branches.all(func(x: Branch): return x.skill.resource_path.get_file() in ["powerful.tres", "energy_missile.tres", "starsap.tres"]), "the astral creatures' own skill resources, not copies")
	var star: Unit = load("res://Scenes/starman.tscn").instantiate()
	var mote: Unit = load("res://Scenes/starmote.tscn").instantiate()
	ok(star.innate.any(func(x: Slot): return x.skill == sk("starsap")) and mote.innate.any(func(x: Slot): return x.skill == sk("energy_missile")), "borrowed from the Starman and the Starmote")
	star.free()
	mote.free()
	var tiers: Array = ["powerful", "energy_missile", "starsap"].map(func(n): return u.role.tier(sk(n)))
	ok(tiers.all(func(t): return t >= 0), "its class offers all three, by tier %s" % [tiers])
	ok(u.missing(sk("powerful")) == "", "Powerful, its root, open from the start")


func test_powerful() -> void:
	var u := sorcerer()
	ok(not u.powered(), "a starter isn't powered yet")
	u.learned.append(slot(sk("powerful")))
	ok(u.powered(), "learning its root: its Energy is Power")
	u.energy = 2
	ok(u.grant_energy(3) == 3 and u.energy == 5, "what grants Energy grants it Power")
