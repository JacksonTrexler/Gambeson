class_name Role
extends Resource

# A unit's class ("class" is reserved in GDScript).
@export var name := ""
@export var tends := &""
@export var god := &""  # whom its units pray to, by default (Unit.god; Paladin: eros, its Divinity root)  # how its units heal, by default (Unit.tends; Adventurer: loyal)
@export var noun := ""  # what its units look like to an ally that can barely read them ("Caster"; empty: its name)
@export var look: Texture2D
@export var race: Race  # default race for units created from this role (Paladin: Halfling)
@export var innate: Array[Slot] = []  # skills its units start with (Adventurer: Strike and its three starting passives)
@export var options: Array[Skill] = []  # the class's skills a unit can unlock with skill points, as a plain list
@export var stats: Dictionary[StringName, int] = {}  # starting stats for new units
@export var reserves: Dictionary[Reserve, int] = {}  # reserves new units start with, by max (Wizard: mana 10)

@export_group("Tree")  # a class with a skill tree (the Adventurer's, drawn as a wheel on the skills screen)
@export var center: Skill  # the one skill at the very centre (Adventurer: Skill Slot +1)
@export var core: Array[Skill] = []  # around it, with its innate skills: a first choice at any time (Hex)
@export var roots: Array[SkillRoot] = []  # reaching out from there (Magic, Martial, Specialist)
@export var tabs: Array[SkillTab] = []  # more of its tree, beside its own, each a wheel of its own (Rogue: Calling: Freedom)


func has_tree() -> bool:
	return not roots.is_empty() or center != null or not core.is_empty() or not tabs.is_empty()


# Its tree, a tab at a time: its own (named after it, with its innate skills on the core ring
# where no other tab has them), then its tabs.
func trees() -> Array[SkillTab]:
	var own := SkillTab.new()
	own.name = name
	own.center = center
	for x in innate:
		if x and x.skill and x.skill not in own.core and not tabs.any(func(t: SkillTab): return t and t.offers(x.skill)):
			own.core.append(x.skill)
	for s in core:
		if s and s not in own.core:
			own.core.append(s)
	own.roots = roots
	var out: Array[SkillTab] = [own]
	out.append_array(tabs.filter(func(t: SkillTab): return t != null))
	return out


# Every skill it offers: its options, then its tree's centres, cores and roots, tab by tab.
func offered() -> Array[Skill]:
	var out: Array[Skill] = []
	var firsts: Array = options + ([center] if center else []) + core
	for t in tabs:
		if t:
			firsts.append_array(([t.center] if t.center else []) + t.core)
	for s in firsts:
		if s and s not in out:
			out.append(s)
	for r in all_roots():
		for s in r.skills():
			if s not in out:
				out.append(s)
	return out


# A skill's tier: 1, plus how many skills must be learned before it's reached - those its branch
# comes after, and theirs in turn, or the count of its root's skills a capstone needs (the starter
# spells 1, Hazard Expert 2, the capstones 4). Its centre, core, innate skills and listed options are
# tier 1; 0 for a skill it doesn't offer.
func tier(s: Skill) -> int:
	var root := root_of(s)
	if root:
		var seen: Array[Skill] = []
		return 1 + maxi(_before(s, seen).size(), root.branch(s).needs)
	if s in offered() or innate.any(func(x: Slot): return x and x.skill == s):
		return 1
	return 0


# Every skill that must be learned before s on its tree, added to out.
func _before(s: Skill, out: Array[Skill]) -> Array[Skill]:
	var root := root_of(s)
	if root:
		for x in root.branch(s).after:
			if x not in out:
				out.append(x)
				_before(x, out)
	return out


# The root a skill is on, in any of its tabs, or null (a centre or core, or not in its tree).
func root_of(s: Skill) -> SkillRoot:
	for r in all_roots():
		if r.branch(s):
			return r
	return null


# Its roots, then its tabs'.
func all_roots() -> Array[SkillRoot]:
	var out: Array[SkillRoot] = []
	for r in roots:
		if r:
			out.append(r)
	for t in tabs:
		if t:
			for r in t.roots:
				if r:
					out.append(r)
	return out
