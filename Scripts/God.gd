class_name God
extends Resource

# A god or a patron (Gods/<id>.tres): whom a unit serves (Unit.deity()), and the trees serving it opens
# up. Its own tree (a Cleric's Divinity: Sol, a Warlock's Patron: Hogel) is what picking it takes up, from
# a choice with `gods` (TreeChoice); its pool is every other tree it offers, each tab's kind the kind of
# slot it fills (Prowess, Divinity, School): a class's slots (TreeChoice.kinds) pick from it. One god
# system: patrons are gods too (`patron`).
@export var id := &""  # its key: Unit.god, SkillTab.god
@export var patron := false  # a Warlock's patron rather than a god of the pantheon
@export var domains := ""  # what it holds sway over, shown in its prayers: "war, power" (a god of the pantheon)
@export var tag := &""  # the damage tag of its domain, carried by a skill of its worshippers that takes it (Skill.god_tag; Smite)
@export var own: SkillTab  # its own tree, taken up by choosing it
@export var pool: Array[SkillTab] = []  # the other trees it offers its servants' slots, by kind

const DIR := "res://Gods/"

static var _all: Array[God] = []


# Every god and patron, by file name.
static func all() -> Array[God]:
	if _all.is_empty():
		var names := Array(ResourceLoader.list_directory(DIR)).filter(func(f: String): return f.ends_with(".tres"))
		names.sort()
		for f in names:
			var g := load(DIR + f) as God
			if g:
				_all.append(g)
	return _all


# The god with key id, or null.
static func of(id: StringName) -> God:
	for g in all():
		if g.id == id:
			return g
	return null


# The gods of the pantheon, not the patrons (Pray, a god's domains).
static func pantheon() -> Array[God]:
	return all().filter(func(g: God): return not g.patron)


# The damage tag of god id's domain, or fallback (no such god, or one without).
static func tag_of(id: StringName, fallback := &"") -> StringName:
	var g := of(id)
	return g.tag if g and g.tag else fallback


# Its own tree and its pool, of the kinds listed (none: every kind).
func offers(kinds: Array[String]) -> Array[SkillTab]:
	var out: Array[SkillTab] = []
	for t in ([own] if own else []) + pool:
		if t and (kinds.is_empty() or t.kind in kinds) and t not in out:
			out.append(t)
	return out


# Whether it offers tree t (by name and kind: tabs are copied for a class's shared row).
func has(t: SkillTab, kinds: Array[String] = []) -> bool:
	return t != null and offers(kinds).any(func(x: SkillTab): return x == t or (x.name == t.name and x.kind == t.kind))
