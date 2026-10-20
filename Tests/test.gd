class_name Test
extends RefCounted

# Base for test suites. Tests/run.gd builds a fresh, seeded museum battle for every test_* method.
# Villagers 1-2 are Lancin (Favour), 3-4 Nemes (Wary, Hex); all have Strike.

var b: Battle
var tree: SceneTree  # for tests that build their own battles
var lancin: Faction = load("res://Factions/lancin.tres")
var nemes: Faction = load("res://Factions/nemes.tres")
var favour: Skill = load("res://Skills/favour.tres")
var wary: Skill = load("res://Skills/wary.tres")
var hex: Skill = load("res://Skills/hex.tres")
var strike: Skill = load("res://Skills/strike.tres")
var manifest: Skill = load("res://Skills/manifest.tres")
var checks := 0
var failures: Array[String] = []


func ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures.append(what)


func v(i: int) -> Unit:
	return b.get_node("Units/Villager%d" % i)


func effect(stat: String, amount: float, tags: Array[StringName] = []) -> Effect:
	var e := Effect.new()
	e.stat = stat
	e.amount = amount
	e.tags = tags
	e.turns = 99
	return e


# Clears the board except the given units, placed at the given cells, and starts f's turn.
func stage(f: Faction, placed: Dictionary) -> void:
	for u: Unit in b.units.values():
		b.units.erase(u.cell)
		u.cell = Vector2i(-99, -99)
	for u: Unit in placed:
		b.move(u, placed[u])
	b.order.assign([lancin, nemes])
	b.turn = null
	b.turn = f
