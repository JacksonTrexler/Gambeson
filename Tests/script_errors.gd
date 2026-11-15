class_name ScriptErrors
extends Logger

# A crash inside a test (a SCRIPT ERROR: a bad call, an index out of range) aborts that test method
# where it stands; its remaining ok() calls never run, so nothing counts it failed. Tests/run.gd adds one
# of these as an engine logger, and after each test takes what it saw and fails the test for it.

static var seen: Array[String] = []


# What the engine reports for each error it logs; only script errors are kept.
func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == Logger.ERROR_TYPE_SCRIPT:
		seen.append("%s (%s:%d, %s)" % [rationale if rationale else code, file.get_file(), line, function])


# The errors since the last call, and forgets them.
static func take() -> Array[String]:
	var out := seen.duplicate()
	seen.clear()
	return out
