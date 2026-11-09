class_name TreeChoice
extends Resource

# A choice of trees on a class's own tab (Role.choices): each tree's tier 0 root in a box headed "Pick
# up to x" (SkillGrid). Picking one (Unit.pick(), free) opens its tab beside the class's own; a tree
# not picked stays shut. A Paladin's Prowess, a Warlock's patron, a Mage's school; a Wizard's Dabblings,
# opened by its expanded studies (Divinity, Symphony, Witchery, Mastery), borrowing the other casters'
# own trees of each kind.
@export var name := ""  # what's picked, the box's heading: Prowess, Patron, School
@export var tabs: Array[SkillTab] = []
@export var picks := 1  # how many may be picked: "Pick up to 1"
@export var by: Skill  # a skill that opens the choice: up to its rank may be picked instead (a Wizard's Divinity)
@export var affinity := 0  # the picked trees' skills' Affinity for their picker (Unit.affinity(): a Wizard's guest trees -1)
@export var borrows: Array[String] = []  # kinds of tree it also offers from every other class, found when first asked (all()): a Wizard's Domain takes every Divinity

const CLASSES := "res://Roles/"

var _all: Array[SkillTab] = []
var _found := false


# Every tree it offers: its own tabs, then every other class's tab of a kind it borrows (their own
# trees, each a copy with its class's shared row first on the core ring, as that class shows it: a
# Cleric's Pray and Renew on Luun).
func all() -> Array[SkillTab]:
	if borrows.is_empty():
		return tabs
	if not _found:
		_found = true
		_all.assign(tabs.filter(func(t: SkillTab): return t != null))
		for f in ResourceLoader.list_directory(CLASSES):
			var r := load(CLASSES + f) as Role if f.ends_with(".tres") else null
			if r == null:
				continue
			for t in r.own_tabs():
				if t.kind in borrows and not _all.any(func(x: SkillTab): return x.name == t.name and x.kind == t.kind):
					var copy: SkillTab = t.duplicate()
					var row: Array[Skill] = []
					row.assign(r.shared.filter(func(x: Skill): return x != null and x not in t.core) + t.core)
					copy.core = row
					_all.append(copy)
	return _all


# The tab of it that's t, or the same tree under another copy (Role.trees() copies tabs for the shared row).
func has(t: SkillTab) -> bool:
	return t != null and all().any(func(x: SkillTab): return x and (x == t or (x.name == t.name and x.kind == t.kind)))


# How a pick of t is remembered (Unit.picked).
func key(t: SkillTab) -> String:
	return "%s/%s" % [name, t.name]
