class_name Skill
extends Resource

@export var name := ""
@export var passive := false  # works while its slot is on; costs nothing, can't be cast
@export var toggle := false  # passive: its holder switches it on and off (from the hotbar)
@export var tags: Array[StringName] = []  # e.g. physical, dark, magical, str, wis; martial, magical, specialist: its category
@export var effects: Array[Effect] = []  # passives: on the holder; actives: put on the target
@export var max_rank := 0  # the highest rank it can be raised to; 0: no cap
@export var glyph := ""  # up to 2 characters standing for it on skill trees; empty: its initials

@export_group("Active")
@export var ap := 0.0
@export var cost := 0  # paid in Energy, or a reserve that can pay for this skill's tags
@export var cost_per_rank := false  # cost x rank (starter spells)
@export var ap_with: Dictionary[Reserve, float] = {}  # AP factor when fully paid with a reserve (Hex: mana 0.5)
@export var cost_with: Dictionary[Reserve, float] = {}  # cost factor paid with a reserve, once the caster has opened it up to this skill's tier (starter spells: mana 0.5, opened by Mana)
@export var radius := 0.0  # range before reach and size
@export var radius_mod := &""  # plus the caster's mod in this stat, reaching an adjacent unit at least (starter spells: intelligence)
@export var hostile := true  # targets enemies (false: allies)
@export var dual := false  # usable on allies and foes alike: allies get its effects, foes its damage (starter spells)
@export var rolls := true  # used on a foe: rolls d20 + attack mod against its Defense first (Battle.cast())
@export var tiers: Array[Tier] = []  # damage by rank; none: no damage
@export var hits_per_rank := false  # Strike III hits three times
@export var grants: Skill  # also puts this skill's effects on the target (Stonegift: Stoneskin)
@export var turns := 0  # how many of the target's turns put-on effects last (zones: the caster's)
@export var turns_per_rank := 0  # ...plus this many per rank (Sola: rank turns)

@export_group("Area")  # cast on a cell rather than a unit (Darkstone)
@export var zone := &""  # concealment kind laid on tiles: rank - distance from the centre levels
@export var radius_per_rank := 0.0  # range grows with rank (Darkstone: 1 + rank)

@export_group("Trap")  # cast on a cell, lays a trap there (Snare; Battle.lay())
@export var lays: Terrain  # the trap: its concealment and dice multiplier are per rank

@export_group("Stand-in")  # passive: one stat stands in for others on skills sharing a tag with it
@export var stand_in := &""  # Arcanist Perspective: intelligence
@export var replaces: Array[StringName] = []  # wisdom, charisma

@export_group("Energy")  # passive: what its holder's Energy counts as
@export var energy_as: Array[StringName] = []  # Energy paid for skills with these tags gets the bonuses their own resources give (Working Knowledge: magical - Hex at half AP, as with Mana)
@export var opens: Reserve  # skills up to its rank in tier get their cost_with savings for this reserve (Mana: mana)

@export_group("Stub")  # a skill that isn't built yet: shown on skill trees, but it can't be learned
@export var stub := ""  # the open question(s) in todo.md it waits on: "?3", "?2 ?11"
@export_multiline var plan := ""  # what it's meant to do, until it's built

const STAT_TAGS := {&"str": &"strength", &"dex": &"dexterity", &"con": &"constitution",
		&"int": &"intelligence", &"wis": &"wisdom", &"cha": &"charisma"}
const CATEGORIES := {&"magical": "Magic", &"martial": "Martial", &"specialist": "Specialist"}


func tier(rank: int) -> Tier:
	var best: Tier = null
	for t in tiers:
		if t.rank <= rank and (best == null or t.rank > best.rank):
			best = t
	return best


# Has a part its holder works by hand - it's cast, or switched on and off - so it goes on the hotbar.
func fits_bar() -> bool:
	return not passive or toggle


# Aimed at a tile rather than a unit: area skills and trap skills.
func on_tile() -> bool:
	return zone != &"" or lays != null


# Can be used on foes: hostile skills, and dual ones.
func for_foes() -> bool:
	return hostile or dual


# Can be used on allies: support skills, and dual ones.
func for_allies() -> bool:
	return not hostile or dual


# Rolls to hit a foe before it does anything to it.
func attacks() -> bool:
	return for_foes() and rolls and not on_tile()


# Its cost at a rank (starter spells: cost x rank).
func price(rank: int) -> int:
	return cost * (maxi(rank, 1) if cost_per_rank else 1)


# How many of the target's turns the effects it puts on last, at a rank.
func lasts(rank: int) -> int:
	return turns + turns_per_rank * rank


# Its range for a caster, before reach and size: radius, plus its mod in radius_mod - at least 1,
# so it reaches an adjacent unit.
func span(u: Unit) -> float:
	if not radius_mod:
		return radius
	return maxf(radius + u.mod(radius_mod, tags), 1.0)


# Up to 2 characters for it on skill trees: a stub's question ("?3"), its glyph, or its initials.
func mark() -> String:
	if stub:
		return stub.split(" ")[0]
	if glyph:
		return glyph
	var words := name.split(" ", false)
	if words.size() > 1:
		return words[0].left(1) + words[1].left(1)
	return name.left(2)


# "Waits on open question 3", "...questions 2 and 11".
func waits() -> String:
	var ids := Array(stub.replace("?", "").split(" ", false))
	if ids.size() == 1:
		return "Waits on open question %s (todo.md)" % ids[0]
	return "Waits on open questions %s and %s (todo.md)" % [", ".join(ids.slice(0, -1)), ids[-1]]


# The stat it's used with, for its attack roll: the one its tags name (str, wis...), else the one its
# damage scales on, else strength.
func stat() -> StringName:
	for t in tags:
		if t in STAT_TAGS:
			return STAT_TAGS[t]
	for t in tiers:
		if t.stat:
			return t.stat
	return &"strength"


static func roman(n: int) -> String:
	var out := ""
	for pair in [[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while n >= pair[0]:
			out += pair[1]
			n -= pair[0]
	return out


# One line for lists: what using it takes, or how a passive works.
func summary() -> String:
	if stub:
		return "Not built yet"
	if passive:
		return "Toggle" if toggle else "Always on"
	var parts := ["%s AP" % num(ap)]
	if cost:
		parts.append("%d cost%s" % [cost, " x rank" if cost_per_rank else ""])
	if zone:
		parts.append("area %s" % num(radius))
	elif radius_mod:
		parts.append("range %s%s mod" % [num(radius) + " + " if radius else "", String(radius_mod).left(3)])
	else:
		parts.append("range %s" % num(radius))
	return " · ".join(parts)


# Everything it does at this rank, for tooltips and the spellbook.
func describe(rank := 1) -> String:
	var lines: PackedStringArray = []
	if stub:
		lines.append("Not built yet. " + waits())
		if plan:
			lines.append(plan)
		return "\n".join(lines)
	var foe := "On a foe: " if dual else ""
	var ally := "On an ally: " if dual else ""
	if passive:
		lines.append("Passive" + (", switched on and off" if toggle else ", always on"))
	else:
		var kind := "Area" if zone else ("Ally or foe" if dual else ("Attack" if hostile else "Support"))
		lines.append("%s · %s" % [kind, summary()])
		for r: Reserve in ap_with:
			lines.append("%s AP paid with %s" % [share(ap_with[r]), r.name])
		for r: Reserve in cost_with:  # the skill opening a reserve goes by its name (Mana)
			lines.append("%s cost paid with %s, once the caster's %s rank reaches its tier" % [share(cost_with[r]), r.name, r.name])
		if attacks():
			lines.append("%s%s d20 + %s mod against Defense; a natural 20 doubles damage" % [foe, "rolls" if dual else "Rolls", String(stat()).left(3)])
		if zone:
			lines.append("Lays %s concealment around a tile for %d turns" % [zone, turns])
		if lays:
			var bonus := " + %s" % String(lays.bonus_stat).left(3) if lays.bonus_stat else ""
			lines.append("Sets a %s: concealment %d, %dd%d x %d%s %s" % [lays.name.to_lower(), lays.concealment * rank,
					lays.dice.x, lays.dice.y, lays.times * rank, bonus, " ".join(lays.damage_tags.filter(func(t): return t != &"trap"))])
			if &"trap" in tags:
				lines.append("Allies within its charisma mod in tiles learn where it is")
		var t := tier(rank)
		if t:
			var dmg := _damage(t)
			if hits_per_rank and rank > 1:
				dmg = "%d hits of %s" % [rank, dmg]
			lines.append(foe + ("deals " if dual else "Deals ") + dmg)
		if grants:
			lines.append("Gives %s for %d turns" % [grants.name, lasts(rank)])
	for e in effects:
		var n := lasts(rank)
		lines.append(ally + e.describe(rank) + (" for %d turn%s" % [n, "" if n == 1 else "s"] if not passive and n else ""))
	if not energy_as.is_empty():
		lines.append("Energy paid for %s skills counts as their own resources, with the bonuses those give" %
				" or ".join(energy_as.map(func(t): return CATEGORIES.get(t, String(t)).to_lower())))
	if opens:
		lines.append("Cheaper casting with %s: skills up to tier %d get the savings they list for it" % [opens.name, rank])
	if stand_in:
		lines.append("%s stands in for %s on %s skills" % [stand_in.capitalize(),
				", ".join(replaces.map(func(x): return String(x).capitalize())), ", ".join(tags)])
	if not tags.is_empty() and not stand_in:
		lines.append("Tags: " + ", ".join(tags))
	return "\n".join(lines)


func _damage(t: Tier) -> String:
	var parts: PackedStringArray = []
	if t.power:
		parts.append(str(t.power))
	if t.dice != Vector2i.ZERO:
		parts.append("%dd%d" % [t.dice.x, t.dice.y])
	if t.stat:
		parts.append(String(t.stat).left(3))
	return " + ".join(parts) + (", unblockable" if t.direct else "")


# "Half", "A quarter", "x0.75": a cost or AP factor.
static func share(f: float) -> String:
	if is_equal_approx(f, 0.5):
		return "Half"
	if is_equal_approx(f, 0.25):
		return "A quarter"
	return "x" + num(f)


static func num(x: float) -> String:
	return str(roundi(x)) if is_equal_approx(x, roundf(x)) else String.num(x, 2)
