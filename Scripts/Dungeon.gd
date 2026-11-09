class_name Dungeon
extends Resource

# A dungeon instance behind one of Gamut's Tower's portals: where it leads, and what its menu tells you
# before you step through (GamutsTower.open_menu()) - how it's won, its enemies, and what winning it
# can bring at the floor's difficulty.
@export var name := ""
@export_file("*.tscn") var scene := ""
@export_multiline var blurb := ""
@export_multiline var goal := ""  # how it's won; {turns}: its escape portal's turns at the floor's difficulty (3 x it, rounded up)
@export var enemies: Array[PackedScene] = []  # what you'll meet there, each by its unit scene
@export var rewards: Array[Item] = []  # what winning brings, by floor (reward_floors)
@export var reward_floors: Array[float] = []  # the least difficulty each reward needs, in order; missing: any floor
@export var color := Color("#b58cff")  # its portal's


# What winning it brings at difficulty d.
func rewards_at(d: float) -> Array[Item]:
	var out: Array[Item] = []
	for i in rewards.size():
		if rewards[i] and (i >= reward_floors.size() or d >= reward_floors[i] - 0.001):
			out.append(rewards[i])
	return out


# How it's won at difficulty d.
func goal_at(d: float) -> String:
	return goal.format({turns = ceili(3.0 * d)})


# Its enemies as the menu lists them: name, vibe, max HP, and the skills they bring.
func enemy_lines() -> Array[String]:
	var out: Array[String] = []
	for e in enemies:
		if not e:
			continue
		var u: Unit = e.instantiate()
		var skills: Array = u.learned.filter(func(x: Slot): return x and x.skill).map(func(x: Slot): return x.skill.title())
		out.append("%s · %s · %d HP: %s" % [u.name, u.vibe, u.max_hp, ", ".join(skills)])
		u.free()
	return out
