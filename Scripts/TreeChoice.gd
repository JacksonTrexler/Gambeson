class_name TreeChoice
extends Resource

# A choice of trees on a class's own tab (Role.choices): each tree's tier 0 root in a box headed "Pick
# up to x" (SkillGrid). Picking one (Unit.pick(), free) opens its tab beside the class's own; a tree
# not picked stays shut. A Paladin's Prowess, a Warlock's patron, a Mage's school; a Wizard's Dabblings,
# opened by its expanded studies (Divinity, Symphony, Witchery, Mastery).
@export var name := ""  # what's picked, the box's heading: Prowess, Patron, School
@export var tabs: Array[SkillTab] = []
@export var picks := 1  # how many may be picked: "Pick up to 1"
@export var by: Skill  # a skill that opens the choice: up to its rank may be picked instead (a Wizard's Divinity)
@export var affinity := 0  # the picked trees' skills' Affinity for their picker (Unit.affinity(): a Wizard's guest trees -1)


# The tab of it that's t, or the same tree under another copy (Role.trees() copies tabs for the shared row).
func has(t: SkillTab) -> bool:
	return t != null and tabs.any(func(x: SkillTab): return x and (x == t or (x.name == t.name and x.kind == t.kind)))


# How a pick of t is remembered (Unit.picked).
func key(t: SkillTab) -> String:
	return "%s/%s" % [name, t.name]
