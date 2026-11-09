class_name Formation
extends Resource

# A group of units that spawns together (the Meadows' demons): a prefab to tweak, scale and reuse. Its
# units stand at their offsets from where it's placed, beside the feature it keeps to; harder areas
# bring more of them (count()).
@export var name := ""
@export var units: Array[PackedScene] = []
@export var offsets: Array[Vector2i] = []  # where each stands from the anchor, in order; past the end: wherever's free nearby
@export var near := &""  # ground it spawns beside, by tag (water: a pond or stream); empty: anywhere
@export var weight := 1.0  # how often it's picked against the others
@export var scales := true  # more units at a harder area (Battle.difficulty), fewer at an easier one


# How many it brings at difficulty d: its own count scaled, at least 1.
func count(d: float) -> int:
	return maxi(roundi(units.size() * d), 1) if scales else units.size()


# The unit scenes it brings at difficulty d, in order: its own, repeated as it scales up.
func roster(d: float) -> Array[PackedScene]:
	var out: Array[PackedScene] = []
	for i in count(d):
		out.append(units[i % units.size()])
	return out
