extends Test

# Slam Jam (Skills/slam_jam.tres, Behaviours/slam_jam.gd): after Jam. 1d10 + str; a hit: str + rank
# against its con save to interrupt (Jam's), and 1 / (rank + 2) of its AP and cost back.

var slam: Skill = load("res://Skills/slam_jam.tres")
var jam: Skill = load("res://Skills/jam.tres")
var metea: Skill = load("res://Skills/metea.tres")


func test_slam() -> void:
	v(1).learned.append(slot(slam, 1))
	v(1).strength = 60
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(1).energy = 10
	v(3).max_hp = 300
	v(3).hp = 300
	v(3).constitution = 1
	v(3).channel = Unit.Channel.new(metea, Vector2i(2, 2))
	var ap := v(1).ap_left()
	ok(b.cast(v(1), slam, v(3)), "used")
	ok(v(3).channel == null and v(3).stat(&"jammed") > 0.0, "interrupted and Jammed")
	ok(v(1).energy == 8 and is_equal_approx(ap - v(1).ap_left(), 4.0), "a third back at rank I: 2 Energy, 4 AP (%d, %s)" % [v(1).energy, ap - v(1).ap_left()])


func test_tree() -> void:
	var br: Branch = load("res://Trees/slayer.tres").branches.filter(func(x: Branch): return x.skill == slam)[0]
	ok(jam in br.after, "uptree from Jam")
	ok(not slam.ai and slam.name == "Slam Jam", "the user's")
