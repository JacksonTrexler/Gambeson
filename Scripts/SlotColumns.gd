class_name SlotColumns
extends Container

# The hotbar and the trait list: a stack of slots that wraps into more columns, top to bottom, when it
# would run taller than `max_height` (the HUD's panel is as tall as the window, and a widescreen window
# is wider, not taller). One column while it fits: no minimum width, so the panel stays as narrow as a
# plain VBoxContainer made it. More than one: each column is at least MIN_WIDTH wide (a name needs room)
# unless `max_width` can't hold that many, and then they share what there is.

const GAP := 2.0  # between slots, down and across
const MIN_WIDTH := 62.0  # a column of slots, wrapped; narrower and names are cut to nothing
const FLOOR_WIDTH := 40.0  # even squeezed into max_width, no narrower than this

var max_height := INF  # the tallest the stack may stand before it wraps
var max_width := INF  # the widest all its columns may be together (before FLOOR_WIDTH)


func set_limits(h: float, w: float) -> void:
	if is_equal_approx(h, max_height) and is_equal_approx(w, max_width):
		return
	max_height = h
	max_width = w
	update_minimum_size()
	queue_sort()


func _slots() -> Array[Control]:
	var out: Array[Control] = []
	for c in get_children():
		if c is Control and c.visible:
			out.append(c)
	return out


func _row_height() -> float:
	var h := 0.0
	for c in _slots():
		h = maxf(h, c.get_combined_minimum_size().y)
	return h


# [columns, rows per column]: as few columns as fit max_height, the slots shared evenly between them.
func layout_for(n: int, row_h: float) -> Vector2i:
	if n == 0:
		return Vector2i(0, 0)
	var fit := maxi(1, floori((max_height + GAP) / (row_h + GAP))) if is_finite(max_height) else n
	var cols := ceili(float(n) / fit)
	return Vector2i(cols, ceili(float(n) / cols))


func column_width(cols: int, width: float) -> float:
	var each := (width - GAP * (cols - 1)) / cols
	return each


func _min_width(cols: int) -> float:
	if cols <= 1:
		return 0.0
	var each := MIN_WIDTH
	if is_finite(max_width):
		each = clampf((max_width - GAP * (cols - 1)) / cols, FLOOR_WIDTH, MIN_WIDTH)
	return each * cols + GAP * (cols - 1)


func _get_minimum_size() -> Vector2:
	var row_h := _row_height()
	var l := layout_for(_slots().size(), row_h)
	if l.x == 0:
		return Vector2.ZERO
	return Vector2(_min_width(l.x), l.y * row_h + GAP * (l.y - 1))


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var kids := _slots()
	var row_h := _row_height()
	var l := layout_for(kids.size(), row_h)
	if l.x == 0:
		return
	var w := column_width(l.x, size.x)
	for i in kids.size():
		var col := i / l.y
		var row := i % l.y
		fit_child_in_rect(kids[i], Rect2(col * (w + GAP), row * (row_h + GAP), w, row_h))
