class_name Role
extends Resource

# A unit's class ("class" is reserved in GDScript).
@export var name := ""
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


func has_tree() -> bool:
	return not roots.is_empty() or center != null or not core.is_empty()


# Every skill it offers: its options, then its tree's centre, core and roots.
func offered() -> Array[Skill]:
	var out: Array[Skill] = []
	for s in options + ([center] if center else []) + core:
		if s and s not in out:
			out.append(s)
	for r in roots:
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


# The root a skill is on, or null (its core, or not in its tree).
func root_of(s: Skill) -> SkillRoot:
	for r in roots:
		if r and r.branch(s):
			return r
	return null
