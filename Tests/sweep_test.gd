extends Test

func _all() -> Array[Skill]:
	var out: Array[Skill] = []
	for f in DirAccess.get_files_at("res://Skills"):
		if f.ends_with(".tres"):
			out.append(load("res://Skills/" + f))
	return out


func test_proto() -> void:
	var passives := 0
	var actives := 0
	var odd := []
	for s in _all():
		if s.stub or s.effects.is_empty() or not s.behaviours.is_empty() or s.on_tile():
			continue
		if s.passive:
			passives += 1
		else:
			actives += 1
	print("PROTO ", passives, " ", actives)
	ok(true, "x")
