class_name GamutsTower
extends Node2D

# Gamut's Tower: a round hall of stone you walk, a floor for each area difficulty (Difficulty.AREA:
# Gentle, Standard, Harsh, bottom up). A staircase up and one down face each other across a ring of
# portals, each a dungeon instance (Dungeon) at its floor's difficulty: the Infernal Meadows open, the
# rest sealed for now. Stepping onto an open portal opens its menu - how it's won, its enemies, and
# what winning it can bring - to enter or step back; the stairs take you up or down a floor, and down
# from the ground floor out of the tower. Arrow keys or WASD walk a tile at a time; a click walks to
# a tile. Later the overworld's dungeon gates lead here.

const FLOORS: Array[float] = [0.5, 1.0, 1.5]  # each floor's difficulty, bottom up
const RADIUS := 5  # the hall: floor within this many tiles of the centre, a wall round it
const UP := Vector2i(0, -3)
const DOWN := Vector2i(0, 3)
const PORTALS: Array[Vector2i] = [Vector2i(3, 0), Vector2i(2, 2), Vector2i(-2, 2), Vector2i(-3, 0), Vector2i(-2, -2), Vector2i(2, -2)]  # the ring between the stairs, the first east
const TILE := 32
const STONE := Vector2i(4, 0)  # its tile in Tiles/placeholder.png
const TINTS := {0.5: Color(0.95, 0.92, 0.84), 1.0: Color(0.74, 0.8, 0.92), 1.5: Color(0.9, 0.62, 0.6)}  # each floor's stone
const SEALED := Color(0.55, 0.55, 0.6)
const DARK := Color("#141218")  # beyond the walls
const ENTRY := "res://Scenes/entry.tscn"
const DIRS := {KEY_W: Vector2i.UP, KEY_UP: Vector2i.UP, KEY_S: Vector2i.DOWN, KEY_DOWN: Vector2i.DOWN,
		KEY_A: Vector2i.LEFT, KEY_LEFT: Vector2i.LEFT, KEY_D: Vector2i.RIGHT, KEY_RIGHT: Vector2i.RIGHT}

@export var dungeons: Array[Dungeon] = []  # behind the ring's portals in order (PORTALS); the rest stand sealed
@export var travels := true  # entering a portal or leaving changes the scene (off for tests)

static var level := 0  # the floor it's on (FLOORS), kept between visits

var cell := Vector2i.ZERO  # where the walker stands
var pace := 0.09  # seconds a step takes; 0: at once
var menu: Control  # an open portal's menu, while it's up
var entered: Dungeon  # the dungeon stepped into (travels off: where it would have gone)
var map: TileMapLayer
var walker: Sprite2D
var _marks: Node2D
var _astar := AStarGrid2D.new()
var _path: Array[Vector2i] = []
var _moving := false
var _tween: Tween
var _ui: CanvasLayer
var _root: Control
var _floor_label: Label
var _note: Label


func _ready() -> void:
	var back := CanvasLayer.new()
	back.layer = -1
	var dark := ColorRect.new()
	dark.color = DARK
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.add_child(dark)
	add_child(back)
	map = TileMapLayer.new()
	map.tile_set = _tiles()
	add_child(map)
	_marks = Node2D.new()
	_marks.draw.connect(_draw_marks)
	add_child(_marks)
	walker = Sprite2D.new()
	var look: Texture2D = Game.starter.role.look if Game.starter and Game.starter.get("role") else load("res://Units/Journeyer.png")
	walker.texture = look
	add_child(walker)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	walker.add_child(cam)
	for x in range(-RADIUS - 1, RADIUS + 2):
		for y in range(-RADIUS - 1, RADIUS + 2):
			var c := Vector2i(x, y)
			if walkable(c):
				map.set_cell(c, 0, STONE, 0)
			elif Vector2(c).length() <= RADIUS + 1.4:
				map.set_cell(c, 0, STONE, 1)  # the wall
	_astar.region = Rect2i(-RADIUS - 1, -RADIUS - 1, 2 * RADIUS + 3, 2 * RADIUS + 3)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for x in range(-RADIUS - 1, RADIUS + 2):
		for y in range(-RADIUS - 1, RADIUS + 2):
			var c := Vector2i(x, y)
			_astar.set_point_solid(c, not walkable(c) or feature(c))
	_build_ui()
	_show_floor()
	place(Vector2i.ZERO)


func _tiles() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://Tiles/placeholder.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	src.create_tile(STONE)
	ts.add_source(src, 0)
	var wall := src.create_alternative_tile(STONE)
	src.get_tile_data(STONE, wall).modulate = Color(0.32, 0.32, 0.38)
	return ts


# --- The hall

func difficulty() -> float:
	return FLOORS[level]


# Floor underfoot: within RADIUS of the centre.
func walkable(c: Vector2i) -> bool:
	return Vector2(c).length() <= RADIUS + 0.4


# Whether c holds a staircase or a portal (stepping onto it does something).
func feature(c: Vector2i) -> bool:
	return c == UP or c == DOWN or c in PORTALS


# The dungeon behind the portal at c, or null (sealed, or no portal).
func dungeon_at(c: Vector2i) -> Dungeon:
	var i := PORTALS.find(c)
	return dungeons[i] if i >= 0 and i < dungeons.size() else null


func _show_floor() -> void:
	var d := difficulty()
	map.modulate = TINTS[d]
	_floor_label.text = "Gamut's Tower · floor %d of %d: %s (%s)" % [level + 1, FLOORS.size(), Difficulty.AREA_NAMES[d], Skill.num(d)]
	_marks.queue_redraw()


# --- Walking

# Puts the walker on c at once.
func place(c: Vector2i) -> void:
	if _tween:
		_tween.kill()
	cell = c
	_path.clear()
	_moving = false
	walker.position = map.map_to_local(c)


# One tile in dir (arrow keys, WASD). False where there's no floor, or it's busy.
func step(dir: Vector2i) -> bool:
	if menu or _moving:
		return false
	_path.clear()
	return _step_to(cell + dir)


# Walks to c by the shortest way round the ring (a click). False if there's no way.
func walk_to(c: Vector2i) -> bool:
	if menu or not walkable(c) or c == cell:
		return false
	for x in [cell, c]:
		_astar.set_point_solid(x, false)  # a portal or staircase only at either end of the walk
	var path := _astar.get_id_path(cell, c)
	for x in [cell, c]:
		_astar.set_point_solid(x, feature(x))
	if path.size() < 2:
		return false
	_path.assign(path.slice(1))
	if not _moving:
		_next()
	return true


func _next() -> void:
	if not _path.is_empty() and not menu:
		_step_to(_path.pop_front())


func _step_to(c: Vector2i) -> bool:
	if not walkable(c):
		return false
	cell = c
	_note.text = ""
	if pace <= 0.0:
		walker.position = map.map_to_local(c)
		_arrive()
		if not _path.is_empty():
			_next()
		return true
	_moving = true
	_tween = create_tween()
	_tween.tween_property(walker, ^"position", map.map_to_local(c), pace)
	_tween.finished.connect(func() -> void:
		_moving = false
		_next())
	_arrive()
	return true


# What stepping onto the walker's tile does: stairs climb, an open portal opens its menu, a sealed one
# says so.
func _arrive() -> void:
	if cell == UP:
		climb(1)
	elif cell == DOWN:
		climb(-1)
	elif cell in PORTALS:
		_path.clear()
		var d := dungeon_at(cell)
		if d:
			open_menu(d)
		else:
			_say("A sealed portal. Nothing answers yet.")


# Up (n = 1) or down (-1) a floor: out of the stairs that face back the way it came. Down from the ground
# floor leaves the tower; there's nothing above the top one yet.
func climb(n: int) -> void:
	_path.clear()
	if level + n < 0:
		if travels:
			get_tree().change_scene_to_file(ENTRY)
		else:
			place(DOWN + Vector2i(0, -1))
			_say("Out of the tower")
		return
	if level + n >= FLOORS.size():
		_say("The stairs wind on up, but the way is shut.")
		place(UP + Vector2i(0, 1))
		return
	level += n
	_show_floor()
	place(DOWN + Vector2i(0, -1) if n > 0 else UP + Vector2i(0, 1))
	_say("Floor %d: %s" % [level + 1, Difficulty.AREA_NAMES[difficulty()]])


func _say(text: String) -> void:
	_note.text = text


# --- Input

func _unhandled_input(e: InputEvent) -> void:
	if menu:
		if e.is_action_pressed(&"cancel") or e.is_action_pressed(&"ui_cancel"):
			close_menu()
			get_viewport().set_input_as_handled()
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		walk_to(map.local_to_map(map.get_local_mouse_position()))
		get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and DIRS.has(e.keycode):
		step(DIRS[e.keycode])
		get_viewport().set_input_as_handled()


# --- The portal's menu

func open_menu(d: Dungeon) -> void:
	close_menu()
	var at := difficulty()
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.07, 0.09, 0.96)
	box.border_color = d.color
	box.set_border_width_all(1)
	box.set_content_margin_all(8)
	panel.add_theme_stylebox_override(&"panel", box)
	centre.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 2)
	panel.add_child(col)
	var head := Label.new()
	head.name = "Title"
	head.text = "%s · %s (%s)" % [d.name, Difficulty.AREA_NAMES[at], Skill.num(at)]
	head.add_theme_font_size_override(&"font_size", 11)
	head.add_theme_color_override(&"font_color", d.color.lightened(0.3))
	col.add_child(head)
	_para(col, d.blurb)
	_para(col, d.goal_at(at), "Goal")
	var enemies := d.enemy_lines()
	_para(col, "\n".join(enemies), "Enemies (up to your party x %s at once)" % Skill.num(at), "Enemies")
	var rewards := d.rewards_at(at).map(func(it: Item): return it.name)
	_para(col, ", ".join(rewards) if rewards else "Nothing at this floor", "Rewards for winning", "Rewards")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var go := Button.new()
	go.name = "Enter"
	go.text = "Enter"
	go.pressed.connect(enter.bind(d))
	row.add_child(go)
	var back := Button.new()
	back.name = "Back"
	back.text = "Step back"
	back.pressed.connect(close_menu)
	row.add_child(back)
	col.add_child(row)
	menu = centre
	_root.add_child(centre)
	go.grab_focus.call_deferred()


func _para(col: VBoxContainer, text: String, heading := "", key := "") -> void:
	if heading:
		var h := Label.new()
		h.text = heading
		h.add_theme_color_override(&"font_color", Color("#e8c547"))
		col.add_child(h)
	var l := Label.new()
	if key:
		l.name = key
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 340
	col.add_child(l)


# Back from the portal's menu, a step toward the middle of the hall.
func close_menu() -> void:
	if menu:
		menu.queue_free()
		menu = null
		if feature(cell):
			place(cell - Vector2i(signi(cell.x), signi(cell.y)))


# Through the portal into d, at the floor's difficulty: the battle picks it up (Game.difficulty,
# Game.dungeon: its rewards).
func enter(d: Dungeon) -> void:
	entered = d
	Game.difficulty = difficulty()
	Game.dungeon = d
	if travels:
		get_tree().change_scene_to_file(d.scene)


# --- Drawing

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var small := Theme.new()  # the entry screen's size
	small.default_font_size = 8
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = small
	_ui.add_child(_root)
	_floor_label = Label.new()
	_floor_label.position = Vector2(6, 4)
	_floor_label.add_theme_font_size_override(&"font_size", 10)
	_root.add_child(_floor_label)
	var hint := Label.new()
	hint.text = "Arrows or WASD to walk, or click a tile. Step onto a portal, or the stairs."
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 6
	hint.offset_top = -16
	hint.add_theme_color_override(&"font_color", Color("#9aa0ae"))
	_root.add_child(hint)
	_note = Label.new()
	_note.anchor_right = 1.0
	_note.offset_top = 20
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_note)


func _draw_marks() -> void:
	var font := ThemeDB.fallback_font
	_stairs(UP, "Up" if level + 1 < FLOORS.size() else "Shut", font)
	_stairs(DOWN, "Down" if level > 0 else "Out", font)
	for i in PORTALS.size():
		var at := map.map_to_local(PORTALS[i])
		var d: Dungeon = dungeons[i] if i < dungeons.size() else null
		var col: Color = d.color if d else SEALED
		_marks.draw_circle(at, 12.0, Color(col, 0.3 if d else 0.1))
		_marks.draw_arc(at, 12.0, 0.0, TAU, 32, Color(col, 1.0 if d else 0.5), 2.0 if d else 1.0)
		_label(font, at + Vector2(0, 22), d.name if d else "Sealed", Color.WHITE if d else SEALED)


func _stairs(c: Vector2i, text: String, font: Font) -> void:
	var at := map.map_to_local(c)
	var r := Rect2(at - Vector2(11, 11), Vector2(22, 22))
	_marks.draw_rect(r, Color(0.12, 0.11, 0.1, 0.85))
	for k in 4:
		var y := r.position.y + 3.0 + k * 5.0
		_marks.draw_line(Vector2(r.position.x + 2.0 + k * 1.5, y), Vector2(r.end.x - 2.0 - k * 1.5, y), Color(0.85, 0.8, 0.7), 1.0)
	_label(font, at + Vector2(0, -15 if c.y < 0 else 24), text, Color("#e8c547"))


func _label(font: Font, at: Vector2, text: String, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	_marks.draw_string(font, at - Vector2(w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, col)
