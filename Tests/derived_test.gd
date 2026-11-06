extends Test

# The derived-stat pipeline (Unit.refit(), Unit.level_hp(), Role.vigor_per_level(), Unit.respec_by()):
# a unit's base stats, under its effects, give its max HP - its authored base + what each level brings,
# (con mod x (1 + Hardy) + its class's vigor) - then item and passive bonuses, Asphyxia and Humble.

var hardy: Skill = load("res://Skills/hardy.tres")


func starter(role: String) -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/%s.tres" % role), name = role})
	b.get_node("Units").add_child(u)
	return u


func test_vigor() -> void:
	var by := {}
	for r in ["fighter", "paladin", "adventurer", "rogue", "bard", "wizard", "warlock", "cleric"]:
		by[r] = (load("res://Roles/%s.tres" % r) as Role).vigor_per_level()
	ok(by == {"fighter": 3, "paladin": 3, "adventurer": 2, "rogue": 2, "bard": 2, "wizard": 1, "warlock": 1, "cleric": 1},
			"martialists 3, specialists and generalists 2, casters 1 (%s)" % [by])


func test_level_hp() -> void:
	var f := starter("fighter")  # con 14 (+2), vigor 3, level 1
	ok(f.level_hp() == 5 and f.max_hp == 5 + 5 and f.hp == f.max_hp, "a level 1 Fighter: its base 5 + (con mod 2 + vigor 3)")
	f.level = 3
	f.refit()
	ok(f.max_hp == 5 + 15, "level 3: three levels' worth")
	var down := effect("level", -1)
	f.afflict(down, 2)
	ok(f.lv() == 2 and f.max_hp == 5 + 10, "a level taken (Level Down) takes a level's HP with it")
	var w := starter("wizard")
	var con := w.mod(&"constitution")
	ok(w.level_hp() == con + 1, "a Wizard: its con mod (%d) + its vigor (1)" % con)
	w.afflict(effect("constitution", 4), 2)
	ok(w.level_hp() == con + 2 + 1 and w.max_hp == 5 + con + 3, "con +4 for a while: +2 a level, and its max HP follows at once")


func test_hardy() -> void:
	var f := starter("fighter")
	f.learned.append(slot(hardy, 2))
	f.refit()
	ok(f.level_hp() == 2 * 3 + 3, "Hardy II: con mod counts three times (2 x 3) beside vigor 3")
	ok("con mod counts 3 times over" in hardy.describe(2), hardy.describe(2))
	var al := b.get_node("Units/Alabaster") as Unit
	ok(al.role == null and al.level_hp() == 5 * 1 * 5, "a classless unit (Alabaster) gets only Hardy's extra: con mod 5 x 1 x level 5")


func test_respec() -> void:
	var a := starter("adventurer")  # 16 across
	var top := a.max_hp
	ok(a.respec_by({&"constitution": 2, &"charisma": -2}, 2) and a.constitution == 18 and a.charisma == 14, "Meditate II: each stat shifts up to 2")
	ok(a.max_hp == top + 1, "con 18 (+4): a point more HP from its one level")
	ok(not a.respec_by({&"constitution": 1}, 2) and a.constitution == 18, "past its limit from where it was born: refused, unchanged")
	ok(a.respec_by({&"constitution": -4}, 2) and a.constitution == 14 and a.respec[&"constitution"] == -2, "back down through 16 to 14: -2 from birth")


func test_asphyxia_takes_grown_hp() -> void:
	var f := starter("fighter")  # 10
	f.afflict(effect("asphyxia", 0.2), 3)
	f.refit()
	ok(f.max_hp == 10 - 2, "Asphyxia's share comes off its whole grown max HP (20% of 10)")


func test_learning_hardy_refits() -> void:
	var a := starter("adventurer")
	var adv: Role = a.role
	if hardy not in adv.options:
		adv.options.append(hardy)  # offered for the test; its tree home waits on question 57
	var before := a.max_hp
	a.skill_points = 3
	ok(a.unlock(hardy) and a.max_hp == before + a.mod(&"constitution"), "learning Hardy I adds its con mod a level at once")
	ok(a.raise(hardy) and a.max_hp == before + 2 * a.mod(&"constitution"), "raising it to II, twice")
	adv.options.erase(hardy)
