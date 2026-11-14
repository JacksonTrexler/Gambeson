extends Test

# Actualization (the Adventurer's Path tab): Self-reflection (T1: self-knowledge), Hardy (T2) and
# Meditate (T3: paid with movement and AP; self-knowledge; then up to rank points moved between core
# stats, one down for each up, as far as the unit already knew itself - Battle.respec()).

var selfref: Skill = load("res://Skills/self_reflection.tres")
var meditate: Skill = load("res://Skills/meditate.tres")
var hardy: Skill = load("res://Skills/hardy.tres")


func shrike() -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/adventurer.tres"), name = "Shrike"})
	b.get_node("Units").add_child(u)
	return u


func test_path() -> void:
	var u := shrike()
	var tab: SkillTab = u.role.trees().filter(func(t: SkillTab): return t.name == "Actualization")[0]
	ok(tab.title() == "Path: Actualization" and tab.roots[0].skills() == [selfref, hardy, meditate], "the Adventurer's Path: Self-reflection, Hardy, Meditate")
	ok(u.tier(selfref) == 1 and u.tier(hardy) == 2 and u.tier(meditate) == 3, "tiers I, II, III")


func test_meditate() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(3, 3)})
	u.learned.append(slot(meditate, 2))
	u.refresh()
	var move := func() -> float: return u.ap.filter(func(p: AP): return p.only == &"move").reduce(func(t, p): return t + p.amount, 0.0)
	var before: float = move.call()
	ok(b.cast(u, meditate, u) and move.call() < before, "Meditate draws on movement first")
	ok(u.respec_room == 0 and roundi(u.stat(&"self_known")) == 2, "the first time, it knew nothing of itself: no shift - but it knows itself 2 levels now")
	u.refresh()
	ok(b.cast(u, meditate, u) and u.respec_room == 2, "meditating again: room to move 2 points")
	ok(b.respec(u, {&"strength": 2, &"charisma": -2}) and u.strength == 18 and u.charisma == 14 and u.respec_room == 0, "str 16 -> 18, cha 16 -> 14; the room is spent")
	ok(not b.respec(u, {&"strength": 1, &"wisdom": -1}), "no room left until it meditates again")
	u.refresh()
	b.cast(u, meditate, u)
	ok(not b.respec(u, {&"strength": 1}) and u.strength == 18, "only a trade: a point up needs a point down (refused, the room spent)")
	u.refresh()
	b.cast(u, meditate, u)
	ok(b.respec(u, {&"strength": 2, &"dexterity": -1, &"wisdom": -1}) and u.strength == 20 and u.dexterity == 15 and u.wisdom == 15, "each use moves rank points again, from any stats: str 20")


func test_self_reflection_first() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(3, 3)})
	u.learned.append(slot(selfref, 1))
	u.learned.append(slot(meditate, 3))
	u.refresh()
	b.cast(u, selfref, u)
	ok(b.cast(u, meditate, u) and u.respec_room == 1, "Self-reflection I first: Meditate III shifts no further than the 1 level it knew itself")
	ok(not b.respec(u, {&"wisdom": 2, &"strength": -2}) and u.wisdom == 16, "2 is past that: refused (and the room is spent)")
