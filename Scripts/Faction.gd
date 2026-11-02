class_name Faction
extends Resource

@export var name := ""
@export var primary := Color.WHITE    # unit glow, bar trim (darkened)
@export var secondary := Color.BLACK  # HP bar backing
@export var icon: Texture2D  # stands for the side on menus (its champion's sprite)
@export var allies: Array[Faction] = []  # sides it fights beside: neither attacks the other, and they win together - but neither's leaders command the other's units
@export var sides_with_player := false  # allied with whichever side the player's starter is on (the Astral Envoy's Wayfarers; Battle._ready())
@export var neutral := false  # a side in the field but not the fight: the battle ends once one other side is left standing (Starmen)


# The same side, or allied ones (either listing the other).
static func friends(a: Faction, b: Faction) -> bool:
	return a == b or (a != null and b != null and (b in a.allies or a in b.allies))
