extends Test

# Sweeps over every skill in Skills/*.tres, so a new skill is covered with no file of its own:
#   test_passives    each passive learned at rank 2: every stat its effects name moved by amount x rank; unequipped, back
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
	if r < e.min_rank or (e.rested and u.rested_turns <= 0) or e.unless_on.any(func(x: StringName): return x in u.ground) or (e.above_hp > 0.0 and u.hp <= e.above_hp * u.max_hp):
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
	var inert := 0
	var switched := 0
	for s in _built:
		if not s.passive:
			continue
		var u := v(1)
		for x: Unit in [v(1), v(2), v(3), v(4)]:  # (one that doesn't already have it)
			if x.slots.all(func(h: Slot): return h.skill != s):
				u = x
				break
		var before := _readings(u, s.effects)
		var had := s.tags.filter(func(t: StringName): return u.has_tag(t))
		u.learned.append(slot(s, 2))
		var r := u.rank(s)
		ok(r > 0, "%s: learned at rank 2" % s.name)
		weighed += _weigh(u, s.effects, before, func(_e): return r, func(_e): return 1.0, s.name)
		if s.toggle and Unit.replacer(s) == null:  # a switch off does nothing: its stats and its tags (Hollow Bones' flight) go with it
			u.toggle(s)
			ok(not u.is_on(s) and _readings(u, s.effects) == before and s.tags.filter(func(t: StringName): return u.has_tag(t)) == had, "%s: switched off, inert, its tags gone" % s.name)
			u.toggle(s)
			switched += 1
		if not s.is_trait() and not s.pillar():  # off the bar it does nothing: every stat back where it was (Unit.equipped()); pillars can't come off
			ok(u.equipped(s), "%s: auto-equipped" % s.name)
			u.bar_clear(u.hotbar.find(s))
			ok(not u.equipped(s) and _readings(u, s.effects) == before, "%s: unequipped, inert" % s.name)
			inert += 1
		u.learned.pop_back()
		swept += 1
	ok(weighed >= 60, "the passive sweep weighed %d stats" % weighed)
	ok(inert >= 60, "the passive sweep unequipped %d" % inert)
	ok(switched >= 5, "the passive sweep switched %d toggles off" % switched)
	print("sweep: %d passives learned at rank 2, %d stats weighed, %d unequipped" % [swept, weighed, inert])


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
	u.endurance = 9  # a skill that gives Energy back mustn't burn the next one's pool away on a failed con check (RecoveryEndurance: a roll, so a skill added before it shifts who burns)
	if s.mist_only:
		u.afflict(effect("mist", 1.0), 9)  # (Coalescing: only a mist)
	if on is Unit and on != u:
		sure_save_fail(u, s, on)
		u.set(s.stat(), 60)  # ...and its attack roll
	return on


func _use(s: Skill, on: Variant) -> bool:
	return b.cast_at(v(1), s, on) if on is Vector2i else b.cast(v(1), s, on)


# What damage takes from u: HP, Energy and every reserve together (an energy skill drains Energy first).
func _pool(u: Unit) -> int:
	var n := u.hp + u.energy
	for r in u.stores:
		n += u.store(r)
	return n


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
		var pool := _pool(on) if on is Unit else 0
		var landed := _use(s, on)
		cast += 1
		ok(landed, "%s: cast at rank 2 and it landed" % s.name)
		if landed and on is Unit and on != u and not s.tiers.is_empty() and not s.dual and (s.hostile or s.either):
			ok(_pool(on) < pool, "%s: it costs the foe something (HP, Energy or a reserve: %d -> %d)" % [s.name, pool, _pool(on)])
		if not landed or not on is Unit or es.is_empty() or _id(s) in EFFECTS_UNWEIGHED:
			continue
		var t: Unit = on
		var r := u.rank(s)
		var held := es.filter(func(e: Effect): return e in t.timed)
		ok(held.size() == es.filter(func(e: Effect): return e.stat != "regain").size(), "%s: its effects are on %s (%d of %d)" % [s.name, t.name, held.size(), es.size()])
		for e: Effect in held:
			var a: Unit.Applied = t.timed[e]
			var turns := e.turns if e.turns else s.turns + s.turns_per_rank * r + (maxi(u.mod(s.turns_mod), 0) if s.turns_mod else 0)  # (Skill.lasts(), spelled out)
			ok(a.total == turns, "%s: %s lasts %d turns, not %d" % [s.name, e.stat, a.total, turns])
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


# Skills whose behaviour reads state that may be missing (Retrieve: where the item is; Emergency Exit: a
# forming portal) are cast here with each state absent and present, so a crash on a missing precondition
# fails the run (the runner counts script errors) and a no-op shows.
func test_missing_preconditions() -> void:
	var bag: Skill = load("res://Skills/burning_bag.tres")
	var item: Item = bag.behaviours[0].item
	for where in ["nowhere", "stash", "ally"]:
		var on: Variant = _pose(bag)
		Game.stash.clear()
		v(1).unequip(item.slot)
		v(2).unequip(item.slot)
		if where == "stash":
			Game.stash.append(item.duplicate())
		elif where == "ally":
			v(2).equip(item.duplicate())
		ok(_use(bag, on), "Burning Bag cast with the bag %s" % where)
		var worn: Item = v(1).get(item.slot)
		ok(worn != null and worn.name == item.name, "...it ends up on its caster (%s)" % where)
		ok(v(2).get(item.slot) == null and Game.stash.all(func(x: Item): return x.name != item.name), "...and nowhere else (%s)" % where)
	Game.stash.clear()
	var exit: Skill = load("res://Skills/emergency_exit.tres")
	var on: Variant = _pose(exit)
	ok(b.get_node_or_null("Meadows") == null and _use(exit, on) and b.pockets.size() == 1, "Emergency Exit with no portal forming makes its pocket")


func test_item_skills() -> void:
	var n := 0
	for f in DirAccess.get_files_at("res://Items"):
		var it: Item = load("res://Items/" + f) if f.ends_with(".tres") else null
		if not it or it.skills.is_empty():
			continue
		for s in it.skills:
			var on: Variant = _pose(s, false)
			v(1).learned.clear()
			v(1).unequip(it.slot)
			ok(v(1).equip(it) == null and (s in v(1).passives if s.passive else s in v(1).actives), "wearing %s lends %s" % [it.name, s.name])
			ok((v(1).slot_cost(s) == 0 and s not in v(1).hotbar) if it.link(s) == &"free" else v(1).slot_cost(s) > 0, "%s: lent %s, %s" % [s.name, it.link(s), "no slot, off the bar (?214)" if it.link(s) == &"free" else "for a slot"])
			ok(s.passive or _use(s, on), "%s: cast through %s" % [s.name, it.name])
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


# One lead-in, one line (Skill.merge_leads()): no skill's description, at any rank, says "On a foe: " (or "On an ally: ",
# "On itself: "...) twice; what a dual skill does to a foe reads as one line, its ally side as another.
func test_description_leads() -> void:
	var n := 0
	for s in _built:
		for r in [1, 2, 3]:
			var seen := {}
			for line in s.describe(r).split("\n"):
				var lead := Skill.lead_of(line)
				if lead != "":
					ok(not seen.has(lead), "%s at rank %d: \"%s\" leads one line only (%s)" % [_id(s), r, lead, line])
					seen[lead] = true
					n += 1
	ok(n > 40, "lead-ins swept (%d)" % n)
	var aetha: String = (load("res://Skills/aetha.tres") as Skill).describe(1)
	ok("On a foe: Attack (int mod); deals 1d4 + int mod\n" in aetha and aetha.count("On a foe") == 1 and aetha.count("On an ally") == 1, "a dual spell: foe line, then ally line (%s)" % aetha)
	var sing: String = (load("res://Skills/sing.tres") as Skill).describe(1)
	ok(sing.count("On a foe") == 1 and "; draws it up to 1 tile toward the caster" in sing, "Sing's foe lines are one (%s)" % sing)
	ok(Skill.merge_leads(PackedStringArray(["a", "On a foe: x", "b", "On an ally: y", "On a foe: z"])) == PackedStringArray(["a", "On a foe: x; z", "b", "On an ally: y"]), "merge_leads keeps order and the other lines")


# Every behaviour that declares a scaling term (terms(): rank or stat, impact or range) says its numbers as
# its holder has them: with a modifier on that channel, describe_as() changes (Behaviour.describe_as()).
# Each is read on a built skill that carries it (some read the skill's own fields).
func test_describes_as() -> void:
	var on := {&"rank_impact": &"rho_up", &"rank_range": &"rho_down", &"stat_impact": &"sigma_down", &"stat_range": &"sigma_up"}
	var n := 0
	for s in _built:
		for bh in s.behaviours:
			var t := SkillTerms.new(Skill.new())
			t.skill = s  # (some terms() read it)
			bh.terms(t)
			for ch: StringName in on:
				if not t.has(ch):
					continue
				var base := Behaviour.Cast.at(3)
				base.skill = s
				var held := Behaviour.Cast.at(3)
				held.skill = s
				held.mods = Modifiers.new()
				held.mods.add(on[ch], 2, &"all")
				ok(bh.describe_as(held) != bh.describe_as(base), "%s / %s: a %s modifier changes what it says of %s" % [_id(s), bh.get_script().resource_path.get_file(), on[ch], ch])
				n += 1
	ok(n > 25, "scaling terms swept (%d)" % n)
