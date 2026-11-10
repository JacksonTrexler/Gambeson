class_name Bio
extends Resource

# Who a unit is, past its stats (Unit.bio): how it behaves, how it looks, what it's made of and whom it
# has standing with. Scenes/<unit>.tscn carry one; Util/unit.py new writes it.
#   behaviour   drives its AI (AI.act()): timid waits for a stronger ally and backs off the aggressive;
#               brave charges the strongest; aggressive presses the weakest and heals last; helpful goes
#               to the wounded to heal them; stoic does as little as it can - holds, striking what comes.
#   appearance  what it looks like at a glance (Soldier, Knight, Caster): who can't make out its class
#   adjectives  goes by this, with the adjectives before it ("Injured Soldier"), and guesses from them
#               (Perception.looks(), AI._level()).
#   properties  what it's made of or full of (Aquatic, Rotting): their effects are always on it.
#   clout       standing with a side: to that side's units its persona goes this much further (allies)
#               or its trickery does (foes), and doubting it is that much harder (Battle.doubt()).

const BEHAVIOURS: Array[StringName] = [&"timid", &"brave", &"aggressive", &"helpful", &"stoic"]
# How much stronger than itself an observer takes one of each appearance to be, in levels, when it
# can't read the level (AI._level()). Unlisted: as strong as itself.
const STANDING := {"knight": 2, "soldier": 1, "brute": 1, "beast": 1, "caster": 0, "scout": 0, "tradefolk": -1, "everyman": -1}
# What an adjective makes an observer guess: aura (as Unit.aura, -2 ominous .. +2 benevolent) where it
# can't read one, standing (levels, on top of the appearance's), hurt (taken for bloodied).
const ADJECTIVES := {
	"beautiful": {aura = 1}, "precious": {aura = 1}, "radiant": {aura = 1},
	"horrific": {aura = -1, standing = 1}, "repulsive": {aura = -1}, "rotting": {aura = -1},
	"injured": {standing = -1, hurt = true},
}

@export var behaviour := &""  # one of BEHAVIOURS; empty: none in particular (Unit.behaviour's specials still apply)
@export var appearance := ""  # "Knight"; empty: its class's noun (Role.noun)
@export var adjectives: Array[String] = []  # "Beautiful", "Horrific", "Injured", "Repulsive"
@export var properties: Array[Property] = []  # Properties/*.tres: Aquatic, Energized, Radiant, Rotting
@export var clout: Dictionary[Faction, int] = {}  # side -> standing with it
@export_multiline var text := ""  # a line or two about it, shown on its own sheet


# Levels more (or less) than itself an observer guesses one looking like this to be ("Injured Knight": 1).
static func standing(looks: String) -> int:
	var n := 0
	for w in looks.to_lower().split(" ", false):
		n += STANDING.get(w, 0) + ADJECTIVES.get(w, {}).get("standing", 0)
	return n


# The aura one looking like this seems to give off: its adjectives' (Repulsive -1), clamped to -2..2.
static func aura(looks: String) -> int:
	var n := 0
	for w in looks.to_lower().split(" ", false):
		n += ADJECTIVES.get(w, {}).get("aura", 0)
	return clampi(n, -2, 2)


# Whether one looking like this looks hurt ("Injured").
static func hurt(looks: String) -> bool:
	return Array(looks.to_lower().split(" ", false)).any(func(w: String): return ADJECTIVES.get(w, {}).get("hurt", false))
