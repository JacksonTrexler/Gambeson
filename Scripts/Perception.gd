class_name Perception

# Works out what one unit knows about another unit or a tile (see Read for the tiers).
# Concealment comes in kinds, each blocking a sense. Per kind it's the most any source lays on
# (the target itself, or the tile when reading a tile, plus zones like Darkstone), less the
# observer's nullify for that kind (Darkvision); the kinds then add up. Recon minus that is net.

# Concealment kinds: the sense each blocks, and what it hints at [shape at -2, vibe at -3].
# Unknown kinds read as plain.
const KINDS := {
	&"": {sense = &"sight", hints = ["movement?", "a sense of being watched"]},
	&"dark": {sense = &"sight", hints = ["a shape in the dark?", "a chill in the shadows"]},
	&"light": {sense = &"sight", hints = ["optical disturbance?", "a glare that hurts to look at"]},
	&"sound": {sense = &"hearing", hints = ["muffled steps?", "a silence that feels deliberate"]},
}
const BENEVOLENT := "Serene, warm"
const TRAPS_SET := "traps were set here"
const OMINOUS := "Menacing, cold"


# What `o` knows about unit `t`. Persona advertises; with enough trickery it lies to other factions,
# and whatever it doesn't cover gets twisted (more of it, more consistently, the higher the trickery).
static func unit(b: Battle, o: Unit, t: Unit) -> Read:
	var r := Read.new()
	var recon := o.stat(&"recon", t.tags)
	var left := _left(o, _levels(b, t.cell, t))
	_sense(r, left, recon, o.luck - t.luck)
	_place(r, o, t, _main(left))
	var trick := trickery(t, r)
	r.deceived = trick > 0 and trick >= recon and o.faction != t.faction
	if r.deceived:
		r.twist = 1.0 if recon <= 0 else clampf(trick / (2.0 * recon), 0.0, 1.0)
	if r.net <= -4:
		return r
	r.aura = t.aura
	var p := roundi(t.stat(&"persona"))
	var shown := func(tier: int, persona_tier: int) -> bool:
		return r.net >= tier or (p >= persona_tier and r.net >= -1)
	if shown.call(0, 99):
		r.name = t.nick if t.nick else String(t.name)
	if shown.call(0, 2):
		r.faction = t.faction
		r.hp = t.hp
		r.max_hp = t.max_hp
		r.energy = t.energy
		r.stores = t.stores.duplicate()
	if shown.call(0, 1):
		r.healthy = t.hp * 2 > t.max_hp
	if shown.call(1, 1):
		r.vibe = t.vibe
		var vals := {}
		for s in Unit.CORE.slice(0, 6):
			vals[s] = t.stat(s)
		var order: Array = vals.keys()
		order.sort_custom(func(x, y): return vals[x] > vals[y])
		r.strengths = [order[0]]
		r.weaknesses = [order[-1]]
	if shown.call(1, 3):
		r.tags = t.tags.duplicate()
		for x in [t.race, t.role]:
			if x:
				r.tags.append(StringName(x.name))
	if shown.call(1, 99):
		for s in Unit.CORE:
			r.stats[s] = t.stat(s)
		r.affected = not t.timed.is_empty()
	if shown.call(2, 2):
		r.role = t.role
	if shown.call(2, 99):
		r.level = t.level
	if shown.call(3, 2):
		r.skills = t.actives + t.passives
	if shown.call(3, 99):
		r.effects.assign(t.timed.keys())
	if r.deceived:
		_lie(o, t, r, p)
	return r


# What `o` knows about the tile at `c`. A trap looks like what it imitates until recon reaches it -
# or o was told of it (a laid trap's setter, and the allies it told) - unless a zone (darkness) hides
# the ground altogether. Allies of a setter with trap_word who weren't told get a vibe of it.
static func tile(b: Battle, o: Unit, c: Vector2i) -> Read:
	var r := Read.new()
	var ter := b.terrain(c)
	var snare: Battle.Snare = b.snares.get(c)
	var hidden := b.hidden(c) and not (snare and o in snare.known)
	var left := _left(o, _levels(b, c, null, hidden))
	_sense(r, left, o.stat(&"recon", ter.tags), o.luck)
	r.cell = c
	if r.net > -4:
		r.aura = ter.worth()
	if r.net >= 0:
		r.name = ter.name
		r.cost = ter.enter
		r.exit = ter.exit
		r.trap = ter.is_trap()
		r.tags.assign(ter.tags.filter(func(t): return t not in [&"beneficial", &"detrimental"]))  # those: worth, at 1
		r.effects.assign(ter.effects)
		r.afflicts.assign(ter.afflicts)
		r.at_end.assign(ter.at_end)
	if r.net >= 1:
		r.worth = ter.worth()
	var shrouded := b.zones.any(func(z): return c in z.levels)
	if hidden and r.net < 0 and not shrouded:
		r.name = ter.looks_like
		r.hint = {-2: ter.shape, -3: ter.vibe}.get(r.net, "")
		if snare and snare.word and o.faction == snare.faction:
			r.hint = TRAPS_SET
	elif r.net in [-2, -3]:
		r.hint = _kind(_main(left)).hints[-2 - r.net]
	return r


# Trickery, doubled per its kind: sound when heard but not seen, sight when unheard.
static func trickery(t: Unit, r: Read) -> float:
	var plain := t.stat(&"trickery")
	var sound := t.stat(&"trickery", [&"sound"]) - plain
	var sight := t.stat(&"trickery", [&"sight"]) - plain
	return plain + sound * (2.0 if r.heard and not r.seen else 1.0) + sight * (2.0 if not r.heard else 1.0)


# Seen, heard and net from the concealment left.
static func _sense(r: Read, left: Dictionary, recon: float, net_luck: int) -> void:
	r.seen = left.keys().all(func(k): return _kind(k).sense != &"sight" or left[k] == 0)
	r.heard = left.keys().all(func(k): return _kind(k).sense != &"hearing" or left[k] == 0)
	r.net = Luck.settle(recon - left.values().reduce(func(a, x): return a + x, 0), net_luck, true, false)


static func _kind(k: StringName) -> Dictionary:
	return KINDS.get(k, KINDS[&""])


# How much concealment a unit has where it stands, before anyone's nullify (exposure taken off).
static func cover(b: Battle, t: Unit) -> int:
	return _levels(b, t.cell, t).values().reduce(func(sum, x): return sum + x, 0)


# Concealment levels at a cell by kind: zones over it, plus the unit's own (less what it's lost to
# exposure, deepest kinds first) or the tile's hidden trap (unless `trap` is false: the observer knows).
static func _levels(b: Battle, c: Vector2i, t: Unit = null, trap := true) -> Dictionary:
	var lv := {}
	for z in b.zones:
		if c in z.levels:
			lv[z.kind] = maxi(lv.get(z.kind, 0), z.levels[c])
	if t:
		var plain := t.stat(&"concealment")
		for k in KINDS:
			var own := roundi(plain if k == &"" else t.stat(&"concealment", [k]) - plain)
			lv[k] = maxi(lv.get(k, 0), own)
		for i in t.exposed:
			var deepest := _main(lv)
			if lv.get(deepest, 0) <= 0:
				break
			lv[deepest] -= 1
	elif trap and b.hidden(c):
		var ter := b.terrain(c)
		lv[ter.kind] = maxi(lv.get(ter.kind, 0), ter.concealment)
	return lv


static func _left(o: Unit, lv: Dictionary) -> Dictionary:
	var out := {}
	for k in lv:
		out[k] = maxi(lv[k] - roundi(o.stat(&"nullify", [k])), 0)
	return out


static func _main(left: Dictionary) -> StringName:
	var best := &""
	for k in left:
		if left[k] > left.get(best, 0):
			best = k
	return best


# Where it is: exact from -2 up; at -3 a 3x3 area of suspicion that contains it, shifted per
# observer so its middle doesn't give the cell away. Hints by the kind hiding it most.
static func _place(r: Read, o: Unit, t: Unit, kind: StringName) -> void:
	if r.net >= -2:
		r.cell = t.cell
	if r.net == -3:
		var mid := t.cell + Vector2i(int(_chance(o, t, &"x") * 3) - 1, int(_chance(o, t, &"y") * 3) - 1)
		for x in range(mid.x - 1, mid.x + 2):
			for y in range(mid.y - 1, mid.y + 2):
				r.area.append(Vector2i(x, y))
	if r.net in [-2, -3]:
		r.hint = _kind(kind).hints[-2 - r.net]


# Persona's presentation where its rank covers it (and only as far as its honest advertising would
# reach); elsewhere each shown field flips with chance `twist`, fixed per observer, target and field.
static func _lie(o: Unit, t: Unit, r: Read, p: int) -> void:
	var faked := {}
	var reach := r.net >= -1
	if reach and p >= 2 and t.as_ally and r.faction:
		r.faction = o.faction
		faked[&"faction"] = true
	if reach and p >= 1 and not t.shows_vibe.is_empty():
		r.vibe = ", ".join(t.shows_vibe)
		r.aura = 2
		faked[&"vibe"] = true
	if reach and p >= 3 and not t.shows_tags.is_empty():
		r.tags = t.shows_tags.duplicate()
		r.name = t.shows_name  # its real name would give it away
	if reach and p >= 2 and r.net < 3:
		r.skills = []  # so would its real skills
	var flips := func(field: StringName) -> bool:
		return field not in faked and _chance(o, t, field) < r.twist
	if r.faction and flips.call(&"faction"):
		r.faction = o.faction
	if r.hp != null and flips.call(&"hp"):
		r.hp = maxi(r.max_hp - r.hp, 1)
		r.energy = t.max_energy - t.energy
	if r.healthy != null and flips.call(&"healthy"):
		r.healthy = not r.healthy
	if not r.strengths.is_empty() and flips.call(&"strengths"):
		var s := r.strengths
		r.strengths = r.weaknesses
		r.weaknesses = s
	if r.aura != null and r.aura != 0 and flips.call(&"vibe"):
		r.aura = -r.aura
		if r.vibe:
			r.vibe = BENEVOLENT if r.aura > 0 else OMINOUS


static func _chance(o: Unit, t: Unit, field: StringName) -> float:
	return float(absi(hash([String(o.name), String(t.name), field])) % 1000) / 1000.0
