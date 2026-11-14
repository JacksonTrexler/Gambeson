extends Test

# The foresight Effect stat: hazard estimates a turn on top of the int mod (HUD.foresight_allowance(); the
# will-consume forecast of known traps and fire). Where it acts is tested beside the forecast: hud_test
# test_foresight_stat and test_forecast_fire_and_wounds.


func test_foresight() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	ok(v(1).stat(&"foresight") == 0.0, "none by default: the allowance is the int mod alone")
	v(1).afflict(effect("foresight", 1.0), 5)
	v(1).afflict(effect("foresight", 2.0), 5)
	ok(v(1).stat(&"foresight") == 3.0, "effects add up through Unit.stat()")
