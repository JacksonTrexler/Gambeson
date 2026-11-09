class_name Meadows
extends Node

# Infernal Meadows (Scenes/meadows.tscn), a child of its Battle: a "Paradise" of grass, light brush, a
# few ponds and thin streams, generated in chunks around the party as it goes. Demons spawn beyond the
# whole party's perception in formations (Formation) beside the ground they keep to, up to the party's
# count x the area's difficulty alive at once. Once `kills_needed` are slain, the escape portal forms
# where the last one fell; it opens after more turns the higher the difficulty, spawning ramping up
# meanwhile, and one of the party stepping onto it once it's open wins the battle at once.

signal portal_formed(c: Vector2i, turns: int)
signal portal_opened(c: Vector2i)

const CHUNK := 12  # tiles a side
const NEAR := 1  # chunks kept generated around each of the party
const CLEAR := 4.0  # the landing kept dry: grass this far around the origin
const TILES := {&"grass": [Vector2i(0, 0), 0], &"brush": [Vector2i(0, 0), 3], &"pond": [Vector2i(3, 0), 0],
		&"shallows": [Vector2i(3, 0), 2], &"stream": [Vector2i(3, 0), 3]}  # ground -> [atlas coords, alternative] in its tile set

@export var demons: Faction
@export var formations: Array[Formation] = []
@export var kills_needed := 30
@export var seed := 0  # 0: a fresh plane each time
@export var spawns := true  # demons keep coming (off for tests that place their own)

var battle: Battle
var map: TileMapLayer  # the battle's (its own @onready isn't set until after this one's _ready)
var kills := 0
var portal: Variant = null  # where the escape portal forms (Vector2i), once enough have fallen
var portal_turns := 0  # its side's turns left before it opens
var opened := false
var mark: PortalMark
var rng := RandomNumberGenerator.new()
var _chunks := {}  # chunk -> true: generated
var _water := FastNoiseLite.new()
var _streams := FastNoiseLite.new()
var _brush := FastNoiseLite.new()
var _tally: Label


func _ready() -> void:
	battle = get_parent()
	map = battle.get_node("Map")
	if Game.difficulty > 0.0:
		battle.difficulty = Game.difficulty
		Game.difficulty = 0.0
	if Game.dungeon:
		battle.rewards = Game.dungeon.rewards_at(battle.difficulty)
		Game.dungeon = null
	rng.seed = seed if seed else randi()
	_water.seed = rng.randi()
	_water.frequency = 0.07
	_streams.seed = rng.randi()
	_streams.frequency = 0.025
	_brush.seed = rng.randi()
	_brush.frequency = 0.18
	if demons and demons not in battle.lasting:
		battle.lasting.append(demons)
	for c in battle.spawns.values():
		ensure_around(c)
	for u: Unit in battle.get_node("Units").get_children():
		ensure_around(u.cell)
	ensure_around(Vector2i.ZERO)
	battle.traveled.connect(_on_traveled)
	battle.turn_changed.connect(_on_turn)
	_tally = Label.new()
	_tally.add_theme_font_size_override(&"font_size", 7)
	_tally.position = Vector2(170, 2)
	var layer := CanvasLayer.new()
	layer.layer = 5
	layer.add_child(_tally)
	add_child(layer)
	_show_tally()


# --- The plane

func _chunk_of(c: Vector2i) -> Vector2i:
	return Vector2i(floori(c.x / float(CHUNK)), floori(c.y / float(CHUNK)))


# Generates the chunks within NEAR of c's that aren't yet.
func ensure_around(c: Vector2i) -> void:
	var k := _chunk_of(c)
	for dx in range(-NEAR, NEAR + 1):
		for dy in range(-NEAR, NEAR + 1):
			_generate(k + Vector2i(dx, dy))


func _generate(k: Vector2i) -> void:
	if k in _chunks:
		return
	_chunks[k] = true
	for x in CHUNK:
		for y in CHUNK:
			var c := k * CHUNK + Vector2i(x, y)
			var t: Array = TILES[ground_at(c)]
			map.set_cell(c, 0, t[0], t[1])


# What the plane is at c: mostly grass; a pond where the water noise runs high, shallows round it; a
# thin stream along the stream noise's zero line; light brush in patches.
func ground_at(c: Vector2i) -> StringName:
	if Vector2(c).length() < CLEAR:
		return &"grass"
	var w := _water.get_noise_2d(c.x, c.y)
	if w > 0.6:
		return &"pond"
	if w > 0.5:
		return &"shallows"
	if absf(_streams.get_noise_2d(c.x, c.y)) < 0.02:
		return &"stream"
	if _brush.get_noise_2d(c.x, c.y) > 0.5:
		return &"brush"
	return &"grass"


# --- The party and the demons

func party() -> Array[Unit]:
	return battle.members(battle.player.faction) if battle.player else ([] as Array[Unit])


func alive_demons() -> int:
	return battle.members(demons).size() if demons else 0


# How many demons may be alive at once: the party's count x the area's difficulty, doubled while the
# portal forms.
func cap() -> int:
	return maxi(ceili(party().size() * battle.difficulty), 1) * (2 if portal != null and not opened else 1)


# Out of the whole party's perception: every one of them farther away than it perceives.
func unseen(c: Vector2i) -> bool:
	for u in party():
		var reach := battle.perception_range(u)
		if Vector2(u.cell).distance_to(Vector2(c)) <= (reach if reach >= 0.0 else 12.0) + 0.0001:
			return false
	return true


# A spot for formation f: dry, free, out of every party member's perception, beside the ground it keeps
# to (water within 2 tiles), a ring or so beyond the party. Null when no try finds one.
func spot_for(f: Formation) -> Variant:
	var members := party()
	if members.is_empty():
		return null
	var mid := Vector2.ZERO
	var far := 6.0
	for u in members:
		mid += Vector2(u.cell)
		far = maxf(far, battle.perception_range(u))
	mid /= members.size()
	for i in 60:
		var a := rng.randf() * TAU
		var c := Vector2i((mid + Vector2.from_angle(a) * (far + 2.0 + rng.randf() * 6.0)).round())
		ensure_around(c)
		if not battle.on_map(c) or battle.unit_at(c) or battle.depth(c) > 0 or not unseen(c):
			continue
		if f.near and not _beside(c, f.near):
			continue
		return c
	return null


func _beside(c: Vector2i, tag: StringName) -> bool:
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if tag in battle.terrain(c + Vector2i(dx, dy)).tags:
				return true
	return false


# Spawns formation f at its spot: its roster, at their offsets (else the nearest free tiles).
func spawn(f: Formation) -> Array[Unit]:
	var out: Array[Unit] = []
	var at: Variant = spot_for(f)
	if at == null:
		return out
	var roster := f.roster(battle.difficulty)
	for i in roster.size():
		var off: Vector2i = f.offsets[i] if i < f.offsets.size() else Vector2i(i % 3, i / 3)
		var u := battle.summon(roster[i], demons, at + off)
		if u:
			u.died.connect(_on_kill)
			out.append(u)
	for p in party():
		battle.sighted(demons, p, p.cell)  # they arrive knowing where the living are
	return out


func _pick() -> Formation:
	var total := 0.0
	for f in formations:
		total += f.weight
	var roll := rng.randf() * total
	for f in formations:
		roll -= f.weight
		if roll <= 0.0:
			return f
	return formations[-1] if not formations.is_empty() else null


# As the demons' turn opens: a formation joins them while they're under the cap - two while the
# portal forms. As the party's turn opens, a forming portal comes a turn closer.
func _on_turn(_was: Faction, now: Faction) -> void:
	if now == demons and spawns and not formations.is_empty():
		for i in (2 if portal != null and not opened else 1):
			if alive_demons() < cap():
				spawn(_pick())
	elif battle.player and now == battle.player.faction and portal != null and not opened:
		portal_turns -= 1
		if portal_turns <= 0:
			_open()
		else:
			mark.turns = portal_turns
	_show_tally()


func _on_kill(u: Unit) -> void:
	kills += 1
	if kills >= kills_needed and portal == null:
		form_portal(u.cell)
	_show_tally()


# The escape portal forms at c, opening after 3 x the area's difficulty turns (rounded up).
func form_portal(c: Vector2i) -> void:
	portal = c
	portal_turns = ceili(3.0 * battle.difficulty)
	mark = PortalMark.new()
	mark.turns = portal_turns
	battle.add_child(mark)
	battle.move_child(mark, battle.get_node("Map").get_index() + 1)
	mark.position = map.map_to_local(c)
	portal_formed.emit(c, portal_turns)


# Emergency Exit: the portal forming opens `n` turns sooner.
func hasten(n: int) -> void:
	portal_turns -= n
	if portal_turns <= 0:
		_open()
	else:
		mark.turns = portal_turns
	_show_tally()


func _open() -> void:
	opened = true
	mark.turns = 0
	portal_opened.emit(portal)
	var u := battle.unit_at(portal)
	if u and battle.player and Faction.friends(u.faction, battle.player.faction):
		battle.escape(u)


func _on_traveled(u: Unit, _from: Vector2i, path: Array[Vector2i]) -> void:
	if battle.player and Faction.friends(u.faction, battle.player.faction):
		ensure_around(u.cell)
		if opened and (portal in path or u.cell == portal):
			battle.escape(u)


func _show_tally() -> void:
	if _tally:
		_tally.text = "Demons slain: %d / %d%s" % [kills, kills_needed,
				("" if portal == null else (" · the portal is open" if opened else " · the portal opens in %d" % portal_turns))]
