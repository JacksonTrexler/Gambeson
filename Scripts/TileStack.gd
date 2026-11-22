class_name TileStack
extends Resource

# Layers a scene lays over its ground at the start (Battle.stacked, bottom-up in list order): a terrain
# on some cells - leaves, glass, starpanes, startiles. An overlay lets the ground beneath act too; a
# standalone layer is all a unit on it deals with. "as is" goes by the terrain's own `passes`.
@export var terrain: Terrain
@export var cells: Array[Vector2i] = []
@export_enum("as is", "overlay", "standalone") var mode := "as is"


func passes() -> bool:
	return terrain.passes if mode == "as is" else mode == "overlay"
