extends Test

# SlotColumns (the hotbar and trait lists): one column while it fits max_height, else the fewest columns that do,
# slots shared evenly top to bottom; no minimum width at one column, MIN_WIDTH each past it, squeezed into max_width.


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
