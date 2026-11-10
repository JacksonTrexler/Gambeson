class_name Read
extends RefCounted

# What one unit knows about another unit, or a tile. Fields it can't make out stay null/empty.
# net = recon - concealment: 0..3 open recon tiers, -1..-4 are concealment tiers:
#   -4 nothing at all         -3 an aura and an area of suspicion   -2 a vague shape (hint)
#   -1 there, but no details   0 name, faction, HP / tile name, movement cost
#    1 identity, stats, vibe, good or bad ground   2 level, class   3 skills, effects
# A tile seen at 0 also gives what it does to whoever stands on it, steps on it, or ends a turn there.

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
var face := ""  # text standing in for the sprite a persona's name claims (";)"); empty: its own
var faction: Faction
var hp: Variant = null
var max_hp: Variant = null
var energy: Variant = null
var stores := {}  # reserves (mana...) -> amount
var healthy: Variant = null  # unbloodied: above half HP
var cost: Variant = null  # tile: movement to enter
var exit: Variant = null  # tile: extra movement to leave
var trap: Variant = null  # tile: springs when entered
var obscured := false  # tile: under a layer that hides what's beneath (Leaves), nobody standing on it
var concealed := false  # unit: something stands between it and the observer - concealment the observer hasn't got through (darkness, fog, its own hiding), sight too far to tell how it looks, or the observer's suspicion of it

var tags: Array[StringName] = []  # identity: race, role, unit tags (Halfling Paladin, holy); tile: what the ground is (water, sticky)
var stats := {}
var strengths: Array[StringName] = []
var weaknesses: Array[StringName] = []
var vibe := ""
var traits: Array[String] = []  # words for it in place of details, from a low-wisdom ally ("Strong")
var looks := ""  # what it looks like, where its class can't be made out ("Injured Soldier"; Perception.looks()) - all an ally of wis mod -4 or less makes out
var properties: Array[Property] = []  # what it's made of (Bio.properties: Aquatic), with its identity (1)
var temper := &""  # how it behaves (Unit.temper()), read by an insightful observer at 2
var stance := &""  # the side it presents as to this observer (Unit.stance, lowercase): friendly, enemy, aggressive, passive, traitor
var insight := ""  # how true its presentation is, read by an insightful observer (Perception.insight())
var intention := ""  # what it means to do, and how it picks its targets: read by an insightful observer at 2 (the Astral Princess)
var strategy: Array[StringName] = []
var affected: Variant = null  # under timed effects (buffs and debuffs aren't told apart yet)
var worth: Variant = null  # tile: +1 beneficial, -1 detrimental (Terrain.worth())

var level: Variant = null
var role: Role

var skills: Array[Skill] = []
var kit: Array[Skill] = []  # an ally's skills, by name only: allies tell each other what they can do (net 0); the details take net 3 (skills)
var effects: Array[Effect] = []  # unit: timed effects on it (3); tile: on whoever stands there (0)
var suspects := {}  # unit: the units it's grown suspicious of -> stacks (3)
var afflicts: Array[Effect] = []  # tile: put on whoever steps there (0)
var at_end: Array[Effect] = []  # tile: put on whoever ends its turn there (0)


# How observer o takes it: &"ally", &"foe", &"avoid" (aggressive), &"ignore" (passive), or &""
# when it can't tell its side.
func attitude(o: Unit) -> StringName:
	if faction == null:
		return &""
	if stance == &"passive":
		return &"ignore"
	if Faction.friends(faction, o.faction):
		return &"ally"
	return &"avoid" if stance == &"aggressive" else &"foe"


func located() -> bool:
	return cell != null


# Drawn as a black shape: what might be a monster in the brush - a unit it has placed, whose side it
# can't tell, that hides, stands in concealment or is one it suspects. One in plain view that it
# only can't identify isn't (it keeps its colours), nor is one whose side shows.
func silhouette() -> bool:
	return located() and faction == null and concealed


# Ground it knows is bad (or knows is a trap).
func known_bad() -> bool:
	return (worth != null and worth < 0) or trap == true
