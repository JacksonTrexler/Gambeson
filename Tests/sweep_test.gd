extends Test

# Sweeps over every skill in Skills/*.tres, so a new skill is covered with no file of its own:
#   test_passives    each passive learned at rank 2: every stat its effects name moved by amount x rank
#   test_actives     each built active cast once at rank 2 on a staged target (or tile) it can be used
#                    on, its checks and attack roll rigged to land: the cast returns true, every effect
#                    is on the target for skill.lasts(2) turns at the right rank and strength, and the
#                    stat moved by amount x rank
#   test_item_skills each skill an item lends, cast through the worn item
#   test_describes   every Behaviour's describe() says something, at ranks 1-3
# One staged battle serves the whole sweep: each skill poses the same few units afresh (stage(), timed
# effects cleared, HP, AP and Energy topped up). What a skill does beyond its effects is tested where
# the rule lives (route_test, the per-skill files); here it only has to land.

# Built skills the sweep doesn't cast, and why. Shrink-only: a skill leaves this list when the sweep can
# stage it, and nothing joins it without a reason beside it.
const NOT_CAST := {
	"beastshape": "turns into a beast its tile suits: a biome has to be staged (route_test, nature_test)",
	"resuscitate": "only a Downed ally takes it (downed_test)",
	"ramuts_ire": "never cast: Battle applies it as a stalled turn goes by (lure_test); applied below instead",
}

# Skills with effects whose effects the sweep casts but doesn't weigh, and why. Shrink-only.
const EFFECTS_UNWEIGHED := {
	"level_down": "its effects land through rank rolls of their own (Battle._level_down), for the turns they say (level_down_test)",
	"sing": "automatic: its effects land on the nearest units in range, not on its user (lure_test)",
}

var _built: Array[Skill] = []


func _init() -> void:
	for f in DirAccess.get_files_at("res://Skills"):
		if f.ends_with(".tres"):
			var s: Skill = load("res://Skills/" + f)
			if not s.stub:
				_built.append(s)


func _id(s: Skill) -> String:
	return s.resource_path.get_file().get_basename()


# What e should move u's stat() by at rank r and strength k: its amount scaled the way Unit.stat() scales
# it (per stat, per mod, per rank), or NAN where this sweep doesn't weigh it (a multiplier, one that needs
# armor or names the skills it applies to, one that isn't a stat). 0 where its condition isn't met.
func _gain(u: Unit, e: Effect, r: int, k := 1.0) -> float:
	if e.op != "add" or e.armored or not e.skills.is_empty() or e.stat == "regain":
		return NAN
	if r < e.min_rank or e.unless_on.any(func(x: StringName): return x in u.ground) or (e.above_hp > 0.0 and u.hp <= e.above_hp * u.max_hp):
		return 0.0
	var amount := e.amount * (floori(u.stat(e.per_stat) / e.per) if e.per_stat else 1) * (r if e.per_rank else 1) * k
	return amount * u.mod(e.per_mod) if e.per_mod else amount


# The stats effects es are on u for (a key is [stat, tags]) and what each should have moved by since
# `before`, read from the same keys. `rank_of` and `strength_of` give an effect's rank and strength.
func _readings(u: Unit, es: Array) -> Dictionary:
	var out := {}
	for e: Effect in es:
		out[[e.stat, e.tags]] = u.stat(e.stat, e.tags)
	return out


func _weigh(u: Unit, es: Array, before: Dictionary, rank_of: Callable, strength_of: Callable, what: String) -> int:
	var want := {}
	for e: Effect in es:
		var key := [e.stat, e.tags]
		var g := _gain(u, e, rank_of.call(e), strength_of.call(e))
		want[key] = want.get(key, 0.0) + g  # (NAN stays NAN: that stat isn't weighed)
	var weighed := 0
	for key in want:
		if is_nan(want[key]):
			continue
		var moved: float = u.stat(key[0], key[1]) - before[key]
		ok(is_equal_approx(moved, want[key]), "%s: %s %s moved %s, not %s" % [what, key[0], key[1], moved, want[key]])
		weighed += 1
	return weighed


func test_passives() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(7, 3), v(4): Vector2i(8, 3)})
	var weighed := 0
	var swept := 0
	for s in _built:
		if not s.passive:
			continue
		var u := v(1)
		for x: Unit in [v(1), v(2), v(3), v(4)]:  # (one that doesn't already have it)
			if x.slots.all(func(h: Slot): return h.skill != s):
				u = x
				break
		var before := _readings(u, s.effects)
		u.learned.append(slot(s, 2))
		var r := u.rank(s)
		ok(r > 0, "%s: learned at rank 2" % s.name)
		weighed += _weigh(u, s.effects, before, func(_e): return r, func(_e): return 1.0, s.name)
		u.learned.pop_back()
		swept += 1
	ok(weighed >= 60, "the passive sweep weighed %d stats" % weighed)
	print("sweep: %d passives learned at rank 2, %d stats weighed" % [swept, weighed])


# Stands v(1) with s learned at rank 2 and returns what it's used on: itself (a skill on its user, or an
# automatic one), a tile (5, 3), a foe (v(3), beside an ally to back it: Gank) or an ally (v(2)). The other
# side's spare unit is out of the way so a kill can't end the battle; everyone starts whole.
func _pose(s: Skill, learn := true) -> Variant:
	var u := v(1)
	if learn:
		u.learned.clear()
		u.learned.append(slot(s, 2))
	var foe := (s.hostile or s.either) and not s.dual
	var on: Variant = u if (s.auto or s.on_self(u)) else (Vector2i(5, 3) if s.on_tile() else (v(3) if foe else v(2)))
	var placed := {u: Vector2i(4, 3), v(4): Vector2i(8, 5)}
	if on is Unit and on != u:
		placed[on] = Vector2i(5, 3)
	if foe:
		placed[v(2)] = Vector2i(5, 4)
	if not placed.has(v(3)):
		placed[v(3)] = Vector2i(8, 2) if on is Vector2i else Vector2i(5, 3)
	stage(lancin, placed)
	for x: Unit in b.get_node("Units").get_children():
		x.timed.clear()
		soak(x)
	u.refresh()
	u.energy = u.max_energy
	if s.mist_only:
		u.afflict(effect("mist", 1.0), 9)  # (Coalescing: only a mist)
	if on is Unit and on != u:
		sure_save_fail(u, s, on)
		u.set(s.stat(), 60)  # ...and its attack roll
	return on


func _use(s: Skill, on: Variant) -> bool:
	return b.cast_at(v(1), s, on) if on is Vector2i else b.cast(v(1), s, on)


func test_actives() -> void:
	var weighed := 0
	var cast := 0
	for s in _built:
		if s.passive or _id(s) in NOT_CAST:
			continue
		var u := v(1)
		var on: Variant = _pose(s)
		var es: Array = s.effects + (s.grants.effects if s.grants else ([] as Array[Effect]))
		var base := _readings(on, es) if on is Unit else {}
		var landed := _use(s, on)
		cast += 1
		ok(landed, "%s: cast at rank 2 and it landed" % s.name)
		if not landed or not on is Unit or es.is_empty() or _id(s) in EFFECTS_UNWEIGHED:
			continue
		var t: Unit = on
		var r := u.rank(s)
		var held := es.filter(func(e: Effect): return e in t.timed)
		ok(held.size() == es.filter(func(e: Effect): return e.stat != "regain").size(), "%s: its effects are on %s (%d of %d)" % [s.name, t.name, held.size(), es.size()])
		for e: Effect in held:
			var a: Unit.Applied = t.timed[e]
			ok(a.total == (e.turns if e.turns else s.lasts(r, u)), "%s: %s lasts %d turns, not %d" % [s.name, e.stat, a.total, s.lasts(r, u)])
			ok(a.rank == r or not e.per_rank, "%s: %s at rank %d, not %d" % [s.name, e.stat, a.rank, r])
		weighed += _weigh(t, held, base, func(e): return t.timed[e].rank, func(e): return t.timed[e].strength(e), s.name)
	# Ramut's Ire: no hotbar skill, Battle puts it on a unit a turn it stalls (Battle.IRE): applied here.
	var ire: Skill = Battle.IRE
	var base := _readings(v(1), ire.effects)
	for e in ire.effects:
		v(1).afflict(e, 3, 2)
	weighed += _weigh(v(1), ire.effects, base, func(_e): return 2, func(_e): return 1.0, ire.name)
	print("sweep: %d actives cast at rank 2 (%d not: %s), %d stats weighed" % [cast, NOT_CAST.size(), NOT_CAST.keys(), weighed])
	ok(weighed >= 40, "the active sweep weighed %d stats" % weighed)
	ok(cast + NOT_CAST.size() == _built.filter(func(s: Skill): return not s.passive).size(), "every built active is cast or named in NOT_CAST")


func test_item_skills() -> void:
	var n := 0
	for f in DirAccess.get_files_at("res://Items"):
		var it: Item = load("res://Items/" + f) if f.ends_with(".tres") else null
		if not it or it.skills.is_empty():
			continue
		for s in it.skills:
			var on: Variant = _pose(s, false)
			v(1).learned.clear()
			ok(v(1).equip(it) == null and s in v(1).actives, "wearing %s lends %s" % [it.name, s.name])
			ok(_use(s, on), "%s: cast through %s" % [s.name, it.name])
			n += 1
	ok(n > 0, "some item lends a skill")


func test_describes() -> void:
	var regex := RegEx.create_from_string("%[sdf]")  # (a format left unfilled)
	var n := 0
	for f in DirAccess.get_files_at("res://Behaviours"):
		if not f.ends_with(".gd"):
			continue
		var bh: Behaviour = load("res://Behaviours/" + f).new()
		for r in [1, 2, 3]:
			var d := bh.describe(r)
			ok(d != "" and not regex.search(d) and "STUB" not in d, "%s describes itself at rank %d: %s" % [f, r, d])
		n += 1
	ok(n > 0, "behaviours found")
