extends Test

# SlotColumns (the hotbar and trait lists): one column while it fits max_height, else the fewest columns that do,
# slots shared evenly top to bottom; no minimum width at one column, MIN_WIDTH each past it, squeezed into max_width.
# Names first (WANT): fewer, wider columns while the room holds the rows. A run (RUN: a skill spanning several slots) stays in
# one column, laid as one tall button over its slots, which stay beneath it unseen.


func test_wrap() -> void:
	var c := SlotColumns.new()
	b.add_child(c)
	for i in 12:
		var s := Control.new()
		s.custom_minimum_size = Vector2(0, 13)
		c.add_child(s)
	var rows := {INF: Vector2i(1, 12), 190.0: Vector2i(1, 12), 150.0: Vector2i(2, 6), 100.0: Vector2i(2, 6), 70.0: Vector2i(3, 4), 35.0: Vector2i(6, 2), 1.0: Vector2i(12, 1)}
	for h: float in rows:
		c.set_limits(h, INF)
		ok(c.layout_for(12, 13.0) == rows[h], "12 slots in %s px: %s (got %s)" % [h, rows[h], c.layout_for(12, 13.0)])
	c.set_limits(INF, INF)
	ok(c.get_combined_minimum_size() == Vector2(0, 12 * 13 + 11 * SlotColumns.GAP), "one column: no minimum width")
	c.set_limits(100.0, INF)
	ok(c.get_combined_minimum_size() == Vector2(2 * SlotColumns.MIN_WIDTH + SlotColumns.GAP, 6 * 13 + 5 * SlotColumns.GAP), "two columns: %s" % c.get_combined_minimum_size())
	c.set_limits(70.0, 130.0)
	ok(c.get_combined_minimum_size().x <= 130.0 and c.get_combined_minimum_size().x < 3 * SlotColumns.MIN_WIDTH, "squeezed into max_width: %s" % c.get_combined_minimum_size())
	c.size = c.get_combined_minimum_size()
	c.notification(Container.NOTIFICATION_SORT_CHILDREN)
	var a: Control = c.get_child(0)
	var b: Control = c.get_child(4)  # the fifth slot starts the second column, at the top
	ok(a.position.y == 0.0 and b.position.y == 0.0 and b.position.x > a.position.x and a.position.x == 0.0, "column-major: slot 5 heads the second column (%s, %s)" % [a.position, b.position])
	c.free()


# A column break that would fall inside a span moves off it, never adding a column nor passing the rows that fit.
func test_runs() -> void:
	var runs := func(spec: Array) -> Array:
		var out := []
		for r: int in spec:
			out.append(r)
			for i in r - 1:
				out.append(1)  # (the covered slots: 1 each, as the HUD says of a slot with no skill of its own)
		return out
	var even := func(n: int) -> Array:
		var out := []
		out.resize(n)
		out.fill(1)
		return out
	var plain := SlotColumns.starts(even.call(12), 3, 5)
	ok(plain == ([0, 4, 8] as Array[int]), "no runs: the even columns as ever (%s)" % [plain])
	var odd := SlotColumns.starts(even.call(10), 3, 5)
	ok(odd == ([0, 4, 8] as Array[int]), "...whatever they leave over (%s)" % [odd])
	# a 3-run over the even break (slots 3-5 of 9 in 3 columns of at most 4): the break moves off it
	var r: Array = runs.call([1, 1, 3, 1, 1, 1, 1])  # 9 slots: 0 1 | 2 3 4 | 5 6 7 8
	var st := SlotColumns.starts(r, 3, 4)
	ok(st.size() <= 3 and st.all(func(c: int): return not c in [3, 4]), "a break not inside the span: %s" % [st])
	# over many shapes, against a brute-force search: if some cut of the slots into at most `cols` columns of `fit` rows has no cut
	# inside a span, the plan is one: never more columns, none over the rows, no break inside a span
	var bad := 0
	for n in range(4, 13):
		for cols in range(2, 5):
			for fit in range(3, 6):
				if cols * fit < n:
					continue
				for at in range(0, n - 1):
					for run in range(2, 4):
						var rr: Array = even.call(n)
						rr[at] = run
						var covered := {}
						for c in range(at + 1, mini(at + run, n)):
							covered[c] = true
						var s2 := SlotColumns.starts(rr, cols, fit)
						var heights := []
						for k in s2.size():
							heights.append((s2[k + 1] if k + 1 < s2.size() else n) - s2[k])
						var whole: bool = s2.all(func(c: int): return not covered.has(c)) and heights.max() <= fit
						if s2.size() > cols or whole != _can(0, cols, n, fit, covered):
							bad += 1
	ok(bad == 0, "over 9 sizes, columns, rows and runs: never more columns, never a cut inside a span while one fits the rows (%d bad)" % bad)
	ok(SlotColumns.starts(runs.call([4, 1, 1]), 2, 3).size() == 2, "a run taller than a column can't be kept: the even columns")
	# laid out: the run's first slot is one tall button over its slots, raised, and those are unseen under it; the next column starts after it
	var c := SlotColumns.new()
	b.add_child(c)
	for i in 9:
		var k := Control.new()
		k.custom_minimum_size = Vector2(0, 13)
		k.set_meta(SlotColumns.RUN, 3 if i == 3 else 1)
		c.add_child(k)
	c.set_limits(58.0, INF)  # 4 rows fit: 3 columns, the break inside slots 3-5 moves off
	c.size = c.get_combined_minimum_size()
	c.notification(Container.NOTIFICATION_SORT_CHILDREN)
	var tall: Control = c.get_child(3)
	var rows_ok: bool = tall.size.y == 3 * 13 + 2 * SlotColumns.GAP and tall.z_index == 1
	ok(rows_ok and c.get_child(4).self_modulate.a == 0.0 and c.get_child(5).self_modulate.a == 0.0 and c.get_child(2).self_modulate.a == 1.0, "a span is one tall raised button, its slots unseen beneath")
	ok(c.get_child(4).position.x == tall.position.x and c.get_child(4).position.y == tall.position.y + 13 + SlotColumns.GAP, "...which stay where they were, for a drop or a click there")
	c.free()


# Names (WANT): a column is as wide as the widest name while max_width holds the columns; else squeezed, and a neighbour can ask
# how many rows the names stand in.
func test_names() -> void:
	var c := SlotColumns.new()
	b.add_child(c)
	for i in 6:
		var k := Control.new()
		k.custom_minimum_size = Vector2(0, 13)
		k.set_meta(SlotColumns.WANT, 90.0 if i == 0 else 50.0)
		c.add_child(k)
	c.set_limits(28.0, 200.0)  # 2 rows: 3 columns of 90 don't fit 200 wide: squeezed, names cut
	ok(c.get_combined_minimum_size().x <= 200.0 and c.get_combined_minimum_size().y == 28.0, "no room for wide columns: 3 squeezed into the width (%s)" % c.get_combined_minimum_size())
	ok(c.standing_rows() == 3, "...so it asks for the 3 rows that 2 columns of names stand in")
	c.set_limits(43.0, 200.0)  # 3 rows: 2 columns of 90
	ok(c.get_combined_minimum_size() == Vector2(2 * 90.0 + SlotColumns.GAP, 3 * 13 + 2 * SlotColumns.GAP), "room for the rows: two columns, each as wide as the widest name (%s)" % c.get_combined_minimum_size())
	for k in c.get_children():
		k.set_meta(SlotColumns.WANT, 0.0)
	c.set_limits(28.0, 200.0)
	ok(c.get_combined_minimum_size().x == 3 * SlotColumns.MIN_WIDTH + 2 * SlotColumns.GAP and c.standing_rows() == 6, "slots that say nothing of their width: as before")
	c.free()


# Whether slots at..n can be cut into at most `left` columns of at most `fit` rows, none starting inside a span (covered).
func _can(at: int, left: int, n: int, fit: int, covered: Dictionary) -> bool:
	if at == n:
		return true
	if left == 0:
		return false
	for end in range(at + 1, mini(at + fit, n) + 1):
		if (end == n or not covered.has(end)) and _can(end, left - 1, n, fit, covered):
			return true
	return false
