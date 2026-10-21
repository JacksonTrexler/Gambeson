class_name Skill
extends Resource

@export var name := ""
@export var passive := false  # works while its slot is on; costs nothing, can't be cast
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
