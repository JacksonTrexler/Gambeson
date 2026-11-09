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
@export var invest := 0  # magical skills learned past which its affinity penalty lifts: major investment in magic (a Ranger's Nature: 4)
@export var talent := &""  # a stat raising its trees' skills' Affinity by 1, up to the tier the stat reads (a Ranger's Nature: Natural Talent)
@export var spares_kin := false  # its affinity penalty spares elemental skills (ELEMENTS) and trees kin to a tree its picker has picked (SkillTab.kin: a Druid's guest trees)
@export var borrows: Array[String] = []  # kinds of caster tree it also offers from every class, found when first asked (all()): a Wizard's Domain takes every Divinity

const CLASSES := "res://Roles/"
const ELEMENTS: Array[StringName] = [&"fire", &"water", &"earth", &"light", &"dark", &"energy", &"ice", &"air", &"wind", &"nature"]  # tags a guest skill spares_kin spares

var _all: Array[SkillTab] = []
var _found := false


# Every tree it offers: its own tabs, then every caster tree (its roots all magical) of a kind it
# borrows, whichever class it's on - each a copy with its class's shared row first on the core ring,
# as that class shows it (a Cleric's Pray and Renew on Luun). Class features on them stay that class's
# (Skill.classes: the Paladin's Smite on Eros).
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
				if t.kind in borrows and caster(t) and not _all.any(func(x: SkillTab): return x.name == t.name and x.kind == t.kind):
					var copy: SkillTab = t.duplicate()
					var row: Array[Skill] = []
					row.assign(r.shared.filter(func(x: Skill): return x != null and not t.offers(x)) + t.core)
					copy.core = row
					_all.append(copy)
	return _all


# A caster tree: roots, every one of them magical (not a Paladin's Prowess).
static func caster(t: SkillTab) -> bool:
	return not t.roots.is_empty() and t.roots.all(func(r: SkillRoot): return r and r.tag == &"magical")


# The tab of it that's t, or the same tree under another copy (Role.trees() copies tabs for the shared row).
func has(t: SkillTab) -> bool:
	return t != null and all().any(func(x: SkillTab): return x and (x == t or (x.name == t.name and x.kind == t.kind)))


# How a pick of t is remembered (Unit.picked).
func key(t: SkillTab) -> String:
	return "%s/%s" % [name, t.name]
