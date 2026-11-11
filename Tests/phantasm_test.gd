extends Test

# Phantasm: a foe in reach saves (wis) or is Haunted, recon -rank, for rank turns: it makes out less.

var phantasm: Skill = load("res://Skills/phantasm.tres")


func test_phantasm() -> void:
	v(1).learned.append(slot(phantasm, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).charisma = 60
	v(3).wisdom = 1
	var recon := v(3).stat(&"recon")
	ok(b.cast(v(1), phantasm, v(3)) and is_equal_approx(v(3).stat(&"recon"), recon - 2.0), "Haunted: recon -2")
