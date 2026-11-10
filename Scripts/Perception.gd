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
	&"fog": {sense = &"sight", hints = ["a shape in the mist?", "damp, cloying air"]},
}
const BENEVOLENT := "Serene, warm"
const TRAPS_SET := "traps were set here"
const OMINOUS := "Menacing, cold"
const TRAITS := {&"strength": "Strong", &"dexterity": "Nimble", &"constitution": "Tough",
		&"intelligence": "Smart", &"wisdom": "Wise", &"charisma": "Charming"}  # what a low-wisdom ally calls one by a stat that stands out
const IMPOSING := 14.0  # its six core stats seem to average this or more: "Imposing"
const INSIGNIFICANT := 8.0  # ...this or less: "Insignificant"
const EVEN := 4.0  # the gap from its best stat to its worst, at most: "Average"
const CHARMING := 16.0  # charisma that seems this high or more stands out: "Charming"
const NERVOUS := 7.0  # ...or this low or less: "Nervous"
const STAT_WORDS := {&"strength": "strong", &"dexterity": "nimble", &"constitution": "hardy",
		&"intelligence": "clever", &"wisdom": "wise", &"charisma": "charming"}  # what an embellished stat claims


# What `o` knows about unit `t`. Persona advertises; with enough trickery it lies, and to other
# factions whatever it doesn't cover gets twisted (more of it, more consistently, the higher the
# trickery). Without trickery it still fools allies that aren't insightful (fronts_to()), and allies
# near its Conspire let it fool them; with Conspire switched off, none of its allies are fooled.
# Allies of low wisdom make out less of each other than recon would show (_dim()). extra: recon
# others share with it (Coordinate: Battle.read()).
static func unit(b: Battle, o: Unit, t: Unit, extra := 0.0) -> Read:
	var r := Read.new()
	var recon := o.stat(&"recon", t.tags) + extra
	var left := _left(o, _levels(b, t.cell, t, true, o))
	_sense(r, left, recon, o.luck - t.luck)
	r.concealed = o != t and left.values().any(func(x): return x > 0)
	r.doubted = o != t and o.suspects(t) + o.suspects(t.cell) > 0
	_range(b, o, t, r)
	_place(r, o, t, _main(left))
	if r.cell == null and o != t and b.pinged(o.faction).has(t) and b.pinged(o.faction)[t] == t.cell:
		r.cell = t.cell  # pinged where it still stands (Clairvoyance): where it is, and nothing more
		r.concealed = true
	var trick := trickery(t, r, o, b)
	var tricked := trick > 0 and trick >= recon
	var candid := o.faction == t.faction and t.candid()
	r.deceived = o != t and not candid and (tricked or fronts_to(o, t) or conspires_with(o, t))
	if r.doubted and not candid:  # would it fool o but for o's suspicion?
		var bare := trickery(t, r, o, b, false)
		r.trick = (bare > 0 and bare >= recon) or fronts_to(o, t, false) or conspires_with(o, t)
	if r.deceived and tricked and o.faction != t.faction:
		r.twist = 1.0 if recon <= 0 else clampf(trick / (2.0 * recon), 0.0, 1.0)
	if r.net <= -4:
		return r
	r.aura = t.aura
	var p := roundi(t.stat(&"persona"))
	if p > 0 and o != t and Faction.friends(o.faction, t.faction):
		p += t.clout(o.faction)  # standing with the side: its persona goes further with them
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
		if t.bio:
			r.properties = t.bio.properties.duplicate()
	if shown.call(1, 99):
		for s in Unit.CORE:
			r.stats[s] = t.stat(s)
		r.affected = not t.timed.is_empty()
	if shown.call(2, 2):
		r.role = t.role
	if shown.call(2, 2):
		r.level = t.lv()
	if shown.call(3, 2):
		r.skills = t.kit
	if o != t and o.faction == t.faction and r.net >= 0:
		r.kit = t.kit
	if shown.call(3, 99):
		r.effects.assign(t.timed.keys())
		r.suspects = t.suspicion.duplicate()
	if r.deceived:
		_lie(b, o, t, r, p)
	var f := _seem(b, o, t, r)
	if o != t and o.faction == t.faction:
		_dim(o, t, r, p, f)
	if r.net >= 0 and o != t and o.insightful():
		r.insight = insight(t, r)
	if r.net >= 2 and o != t and o.insightful():
		r.intention = t.intention
		r.strategy = t.strategy.duplicate()
	if r.looks == "" and r.role == null and r.net >= -1 and r.seen and o != t:
		r.looks = looks(t, r.deceived)  # its class lost on it, it goes by how it looks
	if r.net >= 2 and o != t and o.insightful():
		r.temper = t.temper()
	if o.scrambles(t) and not r.tags.is_empty():
		r.tags = scramble(o, t, r.tags.size())
	return r


# Tags o sees on t under Haluca: n of them, drawn from what units can be, the same each time it looks.
static func scramble(o: Unit, t: Unit, n: int) -> Array[StringName]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([o.get_instance_id(), t.get_instance_id(), o.scrambled().since])
	var pool: Array = PersonaPanel.TAGS.duplicate()
	var out: Array[StringName] = []
	for i in mini(n, pool.size()):
		out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return out


# Puts on a front: advertises with persona, or makes its stats seem other than they are.
static func fronts(t: Unit) -> bool:
	return t.stat(&"persona") > 0 or t.stat(&"embellish") > 0 or t.stat(&"brood") > 0


# Fronting fools an ally that isn't insightful, trickery or not - and anyone of wis mod -3 or less -
# unless it's grown suspicious of t (`doubt` false: as if it hadn't).
static func fronts_to(o: Unit, t: Unit, doubt := true) -> bool:
	return fronts(t) and not o.insightful() and (o.faction == t.faction or o.mod(&"wisdom") <= -3) and (not doubt or o.suspects(t) == 0)


# t's Conspire is on and o is an ally within its rank + cha mod tiles: o lets t's persona fool it.
static func conspires_with(o: Unit, t: Unit) -> bool:
	var k := t.conspiring()
	return k > 0 and o != t and o.faction == t.faction and o.is_alive() and Command.tiles(o.cell, t.cell) <= k + t.mod(&"charisma")


# Whether a's presentation fools o, at a glance (no sense doubling its trickery): Brood's reach.
static func fools(b: Battle, o: Unit, a: Unit) -> bool:
	if o == a or (o.faction == a.faction and a.candid()):
		return false
	var trick := trickery(a, Read.new(), o, b)
	return (trick > 0 and trick >= o.stat(&"recon", a.tags)) or fronts_to(o, a) or conspires_with(o, a)


# How t's stats seem to o (Read.stats): its own fronts if it fools o (Embellish up, Brood 25% down a
# rank), less the Brood of allies around it that fool o (rank 5+: 10% x (rank - 4), within rank - 4
# tiles; the strongest counts). Brood can't take a stat below 1. Returns each core stat's factor.
static func _seem(b: Battle, o: Unit, t: Unit, r: Read) -> Dictionary:
	var up := embellish(t) if r.deceived else {}
	var down := 0.25 * t.stat(&"brood") if r.deceived else 0.0
	var aura := 0.0
	for a: Unit in b.units.values():
		var k := a.stat(&"brood") - 4
		if a != t and a.faction == t.faction and k > 0 and Command.tiles(a.cell, t.cell) <= k and fools(b, o, a):
			aura = maxf(aura, 0.1 * k)
	var out := {}
	for s in Unit.CORE.slice(0, 6):
		out[s] = up.get(s, 1.0) * maxf(1.0 - down - aura, 0.0)
		if s in r.stats and out[s] != 1.0:
			r.stats[s] = maxf(roundf(r.stats[s] * out[s]), 1.0)
	return out


# Allies read each other as well as their wisdom lets them, less a negative cha mod of t's (it's hard to
# read: it communicates poorly); at 0 or more, as recon shows.
# -1 to -3: no details beyond what t's persona advertises (Persona II: HP and level; I: vibe; III:
# identity), only healthy or bloodied, and a word or two for it as it seems (traits()). -4 or
# less: only its side, and what it looks like (its persona's noun from rank 3, else its kind's).
static func _dim(o: Unit, t: Unit, r: Read, p: int, f: Dictionary) -> void:
	var w := o.mod(&"wisdom") + mini(t.mod(&"charisma"), 0)
	if w >= 0:
		return
	if p < 2:
		r.hp = null
		r.max_hp = null
		r.energy = null
		r.stores = {}
		r.role = null
		r.skills = []
		r.kit = []  # an unperceptive ally misses what it can do altogether
	if p < 1:
		r.vibe = ""
		r.strengths = []
		r.weaknesses = []
	if p < 3:
		r.tags = []
	r.stats = {}
	if p < 2:
		r.level = null
	r.effects = []
	r.suspects = {}
	r.affected = null
	if r.net >= 0:
		r.traits.assign(traits(t, f))
	if w <= -4:
		r.name = ""
		r.face = ""
		r.traits.clear()
		if p < 1:
			r.healthy = null
		r.looks = t.alias_noun if p >= 3 and t.alias_noun else looks(t)


# The limited judgment a low-wisdom ally makes of t, from its stats as they seem (factors f):
# "Imposing" (strong all round), "Insignificant" (weak all round), "Average" (even, unremarkable),
# or a word for its best stat ("Strong"); then "Charming" or "Nervous" if its charisma stands out.
static func traits(t: Unit, f: Dictionary) -> Array[String]:
	var seems := {}
	for s in Unit.CORE.slice(0, 6):
		seems[s] = t.stat(s) * f.get(s, 1.0)
	var vals: Array = seems.values()
	var mean: float = vals.reduce(func(a, x): return a + x, 0.0) / vals.size()
	var best: StringName = Unit.CORE[0]
	for s in seems:
		if s != &"charisma" and seems[s] > seems[best]:
			best = s
	var out: Array[String] = []
	if mean >= IMPOSING:
		out.append("Imposing")
	elif mean <= INSIGNIFICANT:
		out.append("Insignificant")
	elif vals.max() - vals.min() <= EVEN:
		out.append("Average")
	else:
		out.append(TRAITS[best])
	if seems[&"charisma"] >= CHARMING:
		out.append("Charming")
	elif seems[&"charisma"] <= NERVOUS:
		out.append("Nervous")
	return out


# What t looks like, to one that can't make out its class: its bio's adjectives before its kind's noun
# ("Injured Soldier"). Fooled by a persona with a name (rank 3), the name it goes by ("Precious Lady").
static func looks(t: Unit, deceived := false) -> String:
	if deceived and t.alias:
		return t.alias
	var words: PackedStringArray = t.bio.adjectives if t.bio else PackedStringArray()
	return " ".join(words + PackedStringArray([kind_noun(t)]))


# What a unit of t's kind looks like, at a glance: its bio's appearance (a Knight), else its class's
# noun (casters "Caster", martial classes "Soldier", specialists "Tradefolk", Adventurers "Everyman"),
# "Beast" for monsters, else "Everyman".
static func kind_noun(t: Unit) -> String:
	if t.bio and t.bio.appearance:
		return t.bio.appearance  # its bio says how it looks: a Knight
	if t.role:
		return t.role.noun if t.role.noun else t.role.name
	return "Beast" if &"monster" in t.tags else "Everyman"


# How true t's presentation is, as an insightful observer reads it (Read.insight). Fooled, it seems
# to make no attempt; otherwise its dissonance says how much shows. 1: that it's pretending. 2+:
# what it pretends to be: its persona's adjectives, the stats it inflates (Embellish) or "weak"
# (Brood), and the noun of the name it goes by.
static func insight(t: Unit, r: Read) -> String:
	var who := r.name if r.name else "It"
	var d := 0 if r.deceived else t.dissonance()
	var puffed := embellish(t)
	var brooding := t.stat(&"brood") > 0
	var words: PackedStringArray = []
	for w in t.shows_adjectives:
		words.append(w.to_lower())
	for s in puffed:
		words.append(STAT_WORDS[s])
	if brooding:
		words.append("weak")
	var noun: String = t.alias_noun if t.alias_noun else (t.shows_nouns.keys()[0] if not t.shows_nouns.is_empty() else "")
	if d <= 0:
		return "%s is as they appear; they make no attempt to appear otherwise." % who
	if d == 1 or (words.is_empty() and not noun):
		if not puffed.is_empty():
			return "%s is trying to look strong." % who
		if brooding:
			return "%s is trying to look weak." % who
		if t.stance or t.alias:
			return "%s is pretending to be something they aren't." % who
		return "%s is pretending to have something they lack." % who
	var parts: PackedStringArray = []
	if words:
		parts.append(", ".join(words.slice(0, -1)) + " or " + words[-1] if words.size() > 1 else words[0])
	if noun:
		parts.append(noun.to_lower() + "-like")
	return "%s isn't as %s as they would have others believe." % [who, ", or ".join(parts)]


# How much Embellish makes each stat seem (x1.2, x1.4...), to those t fools: its rank of
# stats, highest first, +20% each; past the sixth it loops back to the highest.
static func embellish(t: Unit) -> Dictionary:
	var order := Unit.CORE.slice(0, 6)
	order.sort_custom(func(x, y): return t.stat(x) > t.stat(y) or (t.stat(x) == t.stat(y) and Unit.CORE.find(x) < Unit.CORE.find(y)))
	var out := {}
	for i in roundi(t.stat(&"embellish")):
		var s: StringName = order[i % order.size()]
		out[s] = out.get(s, 1.0) + 0.2
	return out


# What `o` knows about the tile at `c`. A trap looks like what it imitates until recon reaches it -
# or o was told of it (a laid trap's setter, and the allies it told) - unless a zone (darkness) hides
# the ground altogether. Allies of a setter with trap_word who weren't told get a vibe of it.
static func tile(b: Battle, o: Unit, c: Vector2i, extra := 0.0) -> Read:
	var r := Read.new()
	if b.obscured(c):  # under leaves: only the leaves can be made out, till someone stands there
		var top: Terrain = b.top_layer(c).terrain
		r.cell = c
		r.net = -1
		r.obscured = true
		r.name = top.name
		r.tags.assign(top.tags)
		return r
	var ter := b.terrain(c)
	var snare: Battle.Snare = b.snares.get(c)
	var hidden := b.hidden(c) and not (snare and o in snare.known)
	var left := _left(o, _levels(b, c, null, hidden, o))
	_sense(r, left, o.stat(&"recon", ter.tags) + extra, o.luck)
	r.cell = c
	if r.net > -4:
		r.aura = ter.worth()
	if r.net >= 0:
		r.name = ter.name
		r.cost = ter.enter + ter.drag if ter.drag > 0.0 else ter.enter
		r.exit = ter.exit
		r.trap = ter.is_trap()
		r.tags.assign(ter.tags.filter(func(t): return t not in [&"beneficial", &"detrimental"]))  # those: worth, at 1
		r.effects.assign(ter.effects)
		r.afflicts.assign(ter.afflicts)
		r.at_end.assign(ter.at_end)
	if r.net >= 1:
		r.worth = ter.worth()
	var shrouded := b.zones.any(func(z): return c in z.levels and not z.allied)
	if hidden and r.net < 0 and not shrouded:
		r.name = ter.looks_like
		r.hint = {-2: ter.shape, -3: ter.vibe}.get(r.net, "")
		if snare and snare.word and o.faction == snare.faction:
			r.hint = TRAPS_SET
	elif r.net in [-2, -3]:
		r.hint = _kind(_main(left)).hints[-2 - r.net]
	return r


# Trickery, doubled per its kind: sound when heard but not seen, sight when unheard. Against
# `viewer`, without what it saw through (Clever Disguise, investigated), less a rank for each stack of
# suspicion it has of t (`doubt` false: as if it had none). With a battle, Conspire adds (rank - 1) for each ally it fools. Ramut's Ire
# takes off its ranks, against everyone.
static func trickery(t: Unit, r: Read, viewer: Unit = null, b: Battle = null, doubt := true) -> float:
	var plain := t.stat(&"trickery", [], viewer)
	var sound := t.stat(&"trickery", [&"sound"], viewer) - plain
	var sight := t.stat(&"trickery", [&"sight"], viewer) - plain
	if b and t.conspiring() > 1:
		plain += (t.conspiring() - 1) * b.units.values().filter(func(a: Unit): return conspires_with(a, t)).size()
	if viewer and not Faction.friends(viewer.faction, t.faction):
		plain += t.clout(viewer.faction)  # standing with the viewer's side lends its lies weight
	var defeated := t.stat(&"ire") + (viewer.suspects(t) if viewer and doubt else 0)
	return maxf(plain + sound * (2.0 if r.heard and not r.seen else 1.0) + sight * (2.0 if not r.heard else 1.0) - defeated, 0.0)


# Seen, heard and net from the concealment left.
static func _sense(r: Read, left: Dictionary, recon: float, net_luck: int) -> void:
	r.seen = left.keys().all(func(k): return _kind(k).sense != &"sight" or left[k] == 0)
	r.heard = left.keys().all(func(k): return _kind(k).sense != &"hearing" or left[k] == 0)
	r.net = Luck.settle(recon - left.values().reduce(func(a, x): return a + x, 0), net_luck, true, false)


# Where sight is limited (Battle.sight): beyond every perception range on o's side it doesn't perceive t
# at all; beyond half of them all, it makes out where t is but not how it looks (Battle.in_range()).
# Its own side it always knows.
static func _range(b: Battle, o: Unit, t: Unit, r: Read) -> void:
	if not b.sight or o == t or Faction.friends(o.faction, t.faction):
		return
	match b.in_range(o, t):
		0:
			r.net = mini(r.net, -4)
			r.seen = false
		1:
			r.net = mini(r.net, -2)
			r.concealed = true  # too far to tell how it looks


static func _kind(k: StringName) -> Dictionary:
	return KINDS.get(k, KINDS[&""])


# How much concealment a unit has where it stands, before anyone's nullify (exposure taken off).
static func cover(b: Battle, t: Unit) -> int:
	return _levels(b, t.cell, t).values().reduce(func(sum, x): return sum + x, 0)


# Concealment levels at a cell by kind: zones over it, plus the unit's own (less what `viewer` saw
# through: Hide; none against its allies) or the tile's hidden trap (unless `trap` is false: the
# observer knows). A unit loses levels, deepest kinds first, to exposure, Ramut's Ire, and each stack
# of suspicion `viewer` has of it or its tile; a trap, to each `viewer` has of its tile.
static func _levels(b: Battle, c: Vector2i, t: Unit = null, trap := true, viewer: Unit = null) -> Dictionary:
	var lv := {}
	for z in b.zones:
		if c in z.levels and (not z.allied or (t and t.faction == z.faction and not (viewer and viewer.faction == t.faction))):  # allied darkness (Luun) hides only its side, from the rest
			lv[z.kind] = maxi(lv.get(z.kind, 0), z.levels[c])
	if t and not (viewer and viewer.faction == t.faction):  # its allies know where it hides
		var plain := t.stat(&"concealment", [], viewer)
		for k in KINDS:
			var own := roundi(plain if k == &"" else t.stat(&"concealment", [k], viewer) - plain)
			lv[k] = maxi(lv.get(k, 0), own)
		for i in t.exposed + roundi(t.stat(&"ire")) + (viewer.suspects(t) + viewer.suspects(c) if viewer else 0):
			var deepest := _main(lv)
			if lv.get(deepest, 0) <= 0:
				break
			lv[deepest] -= 1
	elif trap and b.hidden(c):
		var ter := b.terrain(c)
		lv[ter.kind] = maxi(lv.get(ter.kind, 0), ter.concealment - (viewer.suspects(c) if viewer else 0))
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
# Its stance (Friendly from rank 2, the rest from 3) sets the side it seems to be on: an enemy's for
# Enemy and Aggressive, or a Traitor to its own; o's for Friendly, or a Traitor to o's side. Allies
# in on it through Conspire don't turn on it: they defect together.
static func _lie(b: Battle, o: Unit, t: Unit, r: Read, p: int) -> void:
	var faked := {}
	var reach := r.net >= -1
	if reach and r.faction and t.stance and p >= (2 if t.stance == "Friendly" else 3):
		r.stance = StringName(t.stance.to_lower())
		var hostile := r.stance in [&"enemy", &"aggressive"] or (r.stance == &"traitor" and o.faction == t.faction)
		if hostile and conspires_with(o, t):
			r.stance = &"friendly"
			hostile = false
		if hostile:
			r.faction = _other(b, o.faction)
		elif r.stance != &"passive":
			r.faction = o.faction
		faked[&"faction"] = true
	if reach and p >= 1 and not t.shows_vibe.is_empty():
		r.vibe = ", ".join(t.shows_vibe)
		r.aura = 2
		faked[&"vibe"] = true
	if reach and p >= 3 and not (t.shows_tags.is_empty() and t.alias.is_empty()):
		r.tags = t.shows_tags.duplicate()
		r.name = t.alias  # its real name would give it away ("Radiant Lady"; none: "Something")
		r.face = t.alias_face
	if reach and p >= 2 and r.net < 3:
		r.skills = []  # so would its real skills
		r.kit = []
	if reach and p >= 2 and t.shows_level > 0:
		r.level = t.shows_level
		faked[&"level"] = true
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


# A side other than f in the battle (to pin a stance's enemy on); null if there's none.
static func _other(b: Battle, f: Faction) -> Faction:
	for x in b.order:
		if x != f:
			return x
	return null


static func _chance(o: Unit, t: Unit, field: StringName) -> float:
	return float(absi(hash([String(o.name), String(t.name), field])) % 1000) / 1000.0
