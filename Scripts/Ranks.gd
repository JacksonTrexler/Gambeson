class_name Ranks
extends RefCounted

# Targeting superlatives kept per side (docs/plans/w16-swarm.md): each side's living units sorted by HP, physical
# Defense and magical Defense, lowest first, so "the weakest foe" is a walk from the front, not a read of everyone.
# HP is kept as it changes (Unit.hp_changed: a binary search out and back in); the Defenses (effects, armor, ground)
# are taken afresh once a side's turn (Battle.turns_begun), with any unit new since. Battle.ranks; read by AI._herd_plan()
# and free for any rule that wants a side's lowest (a skill hitting the frailest, a healer's neediest).

const KEYS: Array[StringName] = [&"hp", &"physical", &"magical"]

var _turn := -1  # Battle.turns_begun the lists were taken at
var _lists := {}  # Faction -> {key -> Array[Unit], ascending by (value, instance id)}
var _vals := {}  # Unit -> {key -> value it is sorted by}


# Side f's living units, lowest `key` first (the shared array: don't change it).
func lowest(b: Battle, f: Faction, key: StringName) -> Array:
	if _turn != b.turns_begun:
		_build(b)
	return _lists.get(f, {}).get(key, [])


static func value(u: Unit, key: StringName) -> int:
	match key:
		&"hp":
			return u.hp
		&"physical":
			return u.defense([&"physical"])
		&"magical":
			return u.defense([&"magical"])
	return 0


func _build(b: Battle) -> void:
	_turn = b.turns_begun
	_lists.clear()
	_vals.clear()
	Unit.begin_read()
	for u: Unit in b.units.values():
		if u.faction == null or not u.is_alive():
			continue
		var v := {}
		for k in KEYS:
			v[k] = value(u, k)
		_vals[u] = v
		if not _lists.has(u.faction):
			var by := {}
			for k in KEYS:
				by[k] = []
			_lists[u.faction] = by
		for k in KEYS:
			_lists[u.faction][k].append(u)
		if not u.hp_changed.is_connected(_on_hp):
			u.hp_changed.connect(_on_hp.bind(u))
	Unit.end_read()
	for f in _lists:
		for k in KEYS:
			_lists[f][k].sort_custom(func(a: Unit, c: Unit): return _before(a, c, k))


func _before(a: Unit, c: Unit, k: StringName) -> bool:
	var va: int = _vals[a][k]
	var vc: int = _vals[c][k]
	return va < vc or (va == vc and a.get_instance_id() < c.get_instance_id())


# HP changed: out of its place by binary search, back in at the new one; at 0 or below it leaves the list.
func _on_hp(_was: int, now: int, u: Unit) -> void:
	if not _vals.has(u) or not _lists.has(u.faction):
		return
	var list: Array = _lists[u.faction][&"hp"]
	var i := list.bsearch_custom(u, func(a: Unit, c: Unit): return _before(a, c, &"hp"))
	if i < list.size() and list[i] == u:
		list.remove_at(i)
	_vals[u][&"hp"] = now
	if now > 0 or u.is_alive():
		list.insert(list.bsearch_custom(u, func(a: Unit, c: Unit): return _before(a, c, &"hp")), u)
