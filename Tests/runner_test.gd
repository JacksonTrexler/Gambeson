extends Test

# The runner's own rules (Tests/run.gd). Reverse order and soak are exercised by running the suite so.


# A script error mid-test is seen by the logger run.gd installs, and handed to the runner to fail the
# test. (The error is delivered by hand: a real one prints "SCRIPT ERROR", which the run helper treats
# as a compile failure and kills the run.)
func test_crash_is_reported() -> void:
	ScriptErrors.take()
	var log := ScriptErrors.new()
	log._log_error("test_x", "res://Tests/x_test.gd", 12, "", "Invalid access to index 5", false, Logger.ERROR_TYPE_SCRIPT, [])
	log._log_error("f", "res://Scripts/Unit.gd", 3, "x", "a push_error, not a crash", false, Logger.ERROR_TYPE_ERROR, [])
	var seen := ScriptErrors.take()
	ok(seen.size() == 1 and "Invalid access to index 5" in seen[0] and "x_test.gd:12" in seen[0], "a script error is kept, with where it was (%s)" % [seen])
	ok(ScriptErrors.take().is_empty(), "taking them forgets them")
