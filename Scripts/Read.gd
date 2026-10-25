class_name Read
extends RefCounted

# What one unit knows about another unit, or a tile. Fields it can't make out stay null/empty.
# net = recon - concealment: 0..3 open recon tiers, -1..-4 are concealment tiers:
#   -4 nothing at all         -3 an aura and an area of suspicion   -2 a vague shape (hint)
#   -1 there, but no details   0 name, faction, HP / tile name, movement cost
#    1 identity, stats, vibe, good or bad ground   2 level, class   3 skills, effects
# A tile seen at 0 also gives what it does to whoever stands or steps on it.

var net := 0
var seen := true  # no sight concealment left (dark, light, plain)
var heard := true  # no sound concealment left
var deceived := false  # its trickery matches the observer's recon
var twist := 0.0  # 0..1: how far the lies go (1: everything consistently inverted)

var cell: Variant = null  # where it is, once located (-2 up)
var area: Array[Vector2i] = []  # area of suspicion (-3)
var hint := ""  # "disturbed earth?" (-2), "a prickle of unease" (-3)
var aura: Variant = null  # -2 ominous .. +2 benevolent (-3 up)

var name := ""  # unit name, tile name (or what the tile looks like)
var faction: Faction
var hp: Variant = null
var max_hp: Variant = null
var energy: Variant = null
var stores := {}  # reserves (mana...) -> amount
var healthy: Variant = null  # unbloodied: above half HP
var cost: Variant = null  # tile: movement to enter
var exit: Variant = null  # tile: extra movement to leave
var trap: Variant = null  # tile: springs when entered

var tags: Array[StringName] = []  # identity: race, role, unit tags (Halfling Paladin, holy); tile: what the ground is (water, sticky)
var stats := {}
var strengths: Array[StringName] = []
var weaknesses: Array[StringName] = []
var vibe := ""
var affected: Variant = null  # under timed effects (buffs and debuffs aren't told apart yet)
var worth: Variant = null  # tile: +1 beneficial, -1 detrimental (Terrain.worth())

var level: Variant = null
var role: Role

var skills: Array[Skill] = []
var effects: Array[Effect] = []  # unit: timed effects on it (3); tile: on whoever stands there (0)
var afflicts: Array[Effect] = []  # tile: put on whoever steps there (0)


func located() -> bool:
	return cell != null


# Ground it knows is bad (or knows is a trap).
func known_bad() -> bool:
	return (worth != null and worth < 0) or trap == true
