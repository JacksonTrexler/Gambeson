extends Control

# Start screen: pick a side, a starter class, a scenario, a name and the level it starts at (a skill
# point a level past the first, Battle.starter()); Play (or Enter) opens the battle
# with that starter. It starts on the demo's defaults, so Enter alone starts the demo: the name box shows the
# default name muted (its placeholder) and uses it until something else is typed.

const HUMAN := preload("res://Races/human.tres")
const RING := preload("res://Items/red_spinel_ring.tres")  # every player starts with one in the stash

@export var sides: Array[Faction] = []
@export var roles: Array[Role] = []
@export_file("*.tscn") var next_scene := "res://Scenes/play.tscn"  # the first scenario's
# Scenarios by name: the scene each opens (a battle with the HUD).
@export var scenarios: Dictionary[String, String] = {"Museum": "res://Scenes/play.tscn", "Astral Envoy": "res://Scenes/envoy_play.tscn", "Gamut's Tower": "res://Scenes/gamuts_tower.tscn"}
@export var default_side: Faction  # Lancin
@export var default_role: Role  # Adventurer
@export var default_name := "Shrike"

@onready var side: Choice = %Side
@onready var role: Choice = %Role
@onready var scenario: Choice = %Scenario
@onready var starter_name: LineEdit = %Name
@onready var level: SpinBox = %Level
@onready var play: Button = %Play
@onready var wipe: Button = %Delete  # New game: clears the save, after a second press
@onready var resume: Button = %Continue  # the saved starter, as it was left (Save)
@onready var party: Button = %Party  # who goes with it (PartyPanel)


func _ready() -> void:
	for f in sides:
		side.add(f.name, f.icon, f)
	for r in roles:
		role.add(r.name if not r.race or r.race == HUMAN else "%s\n%s" % [r.name, r.race.name], r.look, r)
	for k in scenarios:
		scenario.add(k, null, scenarios[k])
	scenario.pick(next_scene)
	side.changed.connect(_check.unbind(2))
	role.changed.connect(_check.unbind(2))
	starter_name.text_submitted.connect(_submit.unbind(1))
	play.pressed.connect(_play)
	resume.pressed.connect(_continue)
	wipe.pressed.connect(_delete)
	party.pressed.connect(open_party)
	Save.load_once()
	_show_save()
	side.pick(default_side)
	role.pick(default_role)
	starter_name.placeholder_text = default_name
	_check()
	starter_name.grab_focus.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		_submit()


# Enter: play, if everything's chosen.
func _submit() -> void:
	if not play.disabled:
		_play()


func _check() -> void:
	play.disabled = side.value == null or role.value == null


# What's typed, or the default name while the box is blank.
func chosen_name() -> String:
	var typed := starter_name.text.strip_edges()
	return typed if typed else default_name


# Continue is offered when there's a saved starter: "Shrike, Adventurer, level 3".
func _show_save() -> void:
	wipe.text = "New game: delete the save"
	wipe.visible = not Game.hero.is_empty() or FileAccess.file_exists(Save.PATH)
	resume.visible = not Game.hero.is_empty()
	party.visible = Game.roster.size() > 1
	party.text = "Party: %d of %d" % [Game.party_now().size(), Game.leader_party_size()]
	if resume.visible:
		resume.text = "Continue: %s, %s, level %d" % [Game.hero.name, Game.hero.role.name, Game.level]


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.save()


# Delete save: the first press asks, the second clears the save and Game (a new game).
func _delete() -> void:
	if wipe.text.begins_with("Sure"):
		Save.erase()
		_show_save()
	else:
		wipe.text = "Sure? Press again to delete the save"


# The saved starter again, with its level, outfit, hearts and the stash as they were.
func _continue() -> void:
	Game.starter = Game.hero.duplicate()
	Game.starter.prep = true
	_enter()


func _play() -> void:
	Game.starter = {faction = side.value, role = role.value, name = chosen_name(), prep = true}  # it opens with a look round (Battle.prep)
	Game.hero = {faction = side.value, role = role.value, name = chosen_name()}
	Game.outfit = role.value.outfit()  # a new starter, in its class's starting items
	Game.hearts = 0
	Game.level = clampi(roundi(level.value), 1, Unit.MAX_LEVEL)  # a new starter starts over, at the level picked
	Game.xp = 0
	Game.equipped = []  # its class's default bar
	Game.roster.assign([recruit(side.value, role.value, chosen_name(), Game.outfit)])  # it leads; one of each other class may go with it, as new as it
	for r in roles:
		if r != role.value:
			Game.roster.append(recruit(side.value, r, r.name, r.outfit()))
	Game.party.assign(range(Game.roster.size()))
	Game.party = Game.party_now()  # the first that fit
	if not Game.stash.any(func(it: Item): return it == RING):
		Game.stash.append(RING)  # the player's own trinket: a life once a battle
	Save.save()
	_enter()


# A new roster entry (Unit.to_dict()'s shape): a unit of class r at the level picked, in what it's given.
func recruit(f: Faction, r: Role, nick: String, worn: Dictionary) -> Dictionary:
	var out := {}
	for slot in worn:
		out[slot] = Save.item_out(worn[slot])
	return {faction = f.resource_path, role = r.resource_path, name = nick, level = Game.level, outfit = out}


# The Party screen over this one; the button's count follows it.
func open_party() -> PartyPanel:
	var p := PartyPanel.new()
	p.closed.connect(_show_save)
	add_child(p)
	return p


func _enter() -> void:
	if next_scene:  # empty: stay (tests)
		get_tree().change_scene_to_file(scenario.value if scenario.value else next_scene)
