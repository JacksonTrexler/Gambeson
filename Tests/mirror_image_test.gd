extends Test

# Mirror Image: images of itself take blows meant for it - a tenth of each hit a rank, for rank turns.

var mirror: Skill = load("res://Skills/mirror_image.tres")


func test_mirror_image() -> void:
	v(1).learned.append(slot(mirror, 3))
	stage(lancin, {v(1): Vector2i(4, 3)})
	var m := v(1).mitigation([&"physical"])
	ok(b.cast(v(1), mirror, v(1)) and is_equal_approx(v(1).mitigation([&"physical"]) - m, 0.3), "rank III: 0.3 more of a hit mitigated (%s -> %s)" % [m, v(1).mitigation([&"physical"])])
