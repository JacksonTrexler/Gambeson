extends SceneTree
func _initialize() -> void:
	var root := Node.new()
	get_root().add_child(root)
	for f in DirAccess.get_files_at("res://Scenes"):
		if not f.ends_with(".tscn"): continue
		var ps: PackedScene = load("res://Scenes/" + f)
		var n := ps.instantiate()
		root.add_child(n)
		var units: Array = [n] if n is Unit else n.find_children("*", "Unit", true, false)
		for u: Unit in units:
			var off := u.slots.filter(func(x: Slot): return x.skill.fits_bar() and not u.equipped(x.skill)).map(func(x: Slot): return x.skill.name)
			if not off.is_empty():
				print("%s/%s lv%d bar%d: OFF %s" % [f, u.name, u.level, u.bar_size(), off])
		n.queue_free()
	for f in DirAccess.get_files_at("res://Roles"):
		if not f.ends_with(".tres"): continue
		var r: Role = load("res://Roles/" + f)
		var u: Unit = load("res://Scenes/unit.tscn").instantiate()
		u.role = r
		root.add_child(u)
		var off := u.slots.filter(func(x: Slot): return x.skill.fits_bar() and not u.equipped(x.skill)).map(func(x: Slot): return x.skill.name)
		print("role %s bar%d: %s OFF %s" % [f, u.bar_size(), u.hotbar.map(func(s): return s.name if s else "-"), off])
		u.queue_free()
	quit()
