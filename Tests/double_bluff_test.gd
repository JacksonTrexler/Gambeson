extends Test

# Double Bluff: a passive, embellish +rank: its stats seem other than they are (Perception). That it
# moves embellish is swept (sweep_test); here, that embellish puts on a front.


func test_double_bluff() -> void:
	v(1).learned.append(slot(sk("double_bluff"), 3))
	stage(lancin, {v(1): Vector2i(4, 3)})
	ok(Perception.fronts(v(1)), "it puts on a front")
