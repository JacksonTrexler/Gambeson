extends Test

# Survivalist: the Ranger's midpoint capstone on its Scout root - it opens its guest choice (Survival ??, TreeChoice.by),
# and its rank is an efficiency stack on that guest tree's skills up to its tier (Behaviours/efficiency.gd).

var cap: Skill = load("res://Skills/survivalist.tres")


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func test_survivalist() -> void:
	var u := b.starter({faction = lancin, role = load("res://Roles/ranger.tres"), name = "Wren"})
	b.get_node("Units").add_child(u)
	u.skill_points = 20
	var c: TreeChoice = u.role.choices.filter(func(x: TreeChoice): return x.by == cap)[0]
	ok(c.name == "Survival ??", "it opens Survival ??")
	ok(u.missing(cap).begins_with("Needs"), "a capstone: it waits on its root (%s)" % u.missing(cap))
	for n in "hide,stamina".split(","):
		u.learned.append(slot(sk(n)))
	ok(u.missing(cap) == "" and u.unlock(cap), "midway up Scout: learned")
	var t: SkillTab = u.offered(c).filter(func(x: SkillTab): return x.roots.any(func(r: SkillRoot): return r.branch(sk("forage"))))[0]
	ok(u.pick(c, t), "its guest tree picked: %s" % t.title())
	var probe := sk("forage")
	ok(u.tier(probe) == 1 and u.affinity(probe) == c.affinity + 1, "rank I: a stack on its tier 1 skills, the guest penalty eased (%d)" % u.affinity(probe))
	ok(cap.describe(2).contains("tier"), "it says what it does: %s" % cap.describe(2))
