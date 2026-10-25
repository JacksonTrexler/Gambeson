class_name Skill
extends Resource

@export var name := ""
@export var passive := false  # works while its slot is on; costs nothing, can't be cast
@export var toggle := false  # passive: its holder switches it on and off (from the hotbar)
@export var tags: Array[StringName] = []  # e.g. physical, dark, magic, str, wis
@export var effects: Array[Effect] = []  # passives: on the holder; actives: put on the target

@export_group("Active")
@export var ap := 0.0
@export var cost := 0  # paid in Energy, or a reserve that can pay for this skill's tags
@export var ap_with: Dictionary[Reserve, float] = {}  # AP factor when fully paid with a reserve (Hex: mana 0.5)
@export var radius := 0.0  # range before reach and size
@export var hostile := true  # targets enemies (false: allies)
@export var tiers: Array[Tier] = []  # damage by rank; none: no damage
@export var hits_per_rank := false  # Strike III hits three times
@export var grants: Skill  # also puts this skill's effects on the target (Stonegift: Stoneskin)
@export var turns := 0  # how many of the target's turns put-on effects last (zones: the caster's)

@export_group("Area")  # cast on a cell rather than a unit (Darkstone)
@export var zone := &""  # concealment kind laid on tiles: rank - distance from the centre levels
@export var radius_per_rank := 0.0  # range grows with rank (Darkstone: 1 + rank)

@export_group("Stand-in")  # passive: one stat stands in for others on skills sharing a tag with it
@export var stand_in := &""  # Arcanist Perspective: intelligence
@export var replaces: Array[StringName] = []  # wisdom, charisma


func tier(rank: int) -> Tier:
	var best: Tier = null
	for t in tiers:
		if t.rank <= rank and (best == null or t.rank > best.rank):
			best = t
	return best


# Has a part its holder works by hand - it's cast, or switched on and off - so it goes on the hotbar.
func fits_bar() -> bool:
	return not passive or toggle


static func roman(n: int) -> String:
	var out := ""
	for pair in [[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while n >= pair[0]:
			out += pair[1]
			n -= pair[0]
	return out


# One line for lists: what using it takes, or how a passive works.
func summary() -> String:
	if passive:
		return "Toggle" if toggle else "Always on"
	var parts := ["%s AP" % num(ap)]
	if cost:
		parts.append("%d cost" % cost)
	parts.append("area %s" % num(radius) if zone else "range %s" % num(radius))
	return " · ".join(parts)


# Everything it does at this rank, for tooltips and the spellbook.
func describe(rank := 1) -> String:
	var lines: PackedStringArray = []
	if passive:
		lines.append("Passive" + (", switched on and off" if toggle else ", always on"))
	else:
		var kind := "Area" if zone else ("Attack" if hostile else "Support")
		lines.append("%s · %s" % [kind, summary()])
		if zone:
			lines.append("Lays %s concealment around a tile for %d turns" % [zone, turns])
		var t := tier(rank)
		if t:
			var dmg := _damage(t)
			if hits_per_rank and rank > 1:
				dmg = "%d hits of %s" % [rank, dmg]
			lines.append("Deals " + dmg)
		if grants:
			lines.append("Gives %s for %d turns" % [grants.name, turns])
	for e in effects:
		lines.append(e.describe(rank) + (" for %d turns" % turns if not passive and turns else ""))
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


static func num(x: float) -> String:
	return str(roundi(x)) if is_equal_approx(x, roundf(x)) else String.num(x, 2)
