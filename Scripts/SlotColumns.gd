class_name SlotColumns
extends Container

# The hotbar and the band after it (and the trait list): a stack of slots that wraps into more columns, top to bottom, when it
# would run taller than `max_height` (the HUD's panel is as tall as the window, and a widescreen window
# is wider, not taller). One column while it fits: no minimum width, so the panel stays as narrow as a
# plain VBoxContainer made it. More than one: each column is at least MIN_WIDTH wide (a name needs room)
# unless `max_width` can't hold that many, and then they share what there is.
#
# Two things a child may say of itself (meta, so any Control will do):
#  - WANT: the width its content needs (a skill's whole name). Names first: when that many columns would not fit max_width
#    each that wide, there are fewer, taller columns, provided the room (max_height) still holds the rows; if it doesn't,
#    the columns squeeze as before and the names are cut (the tooltip has them whole).
#  - RUN: how many slots it spans, itself and the RUN-1 children after it (a skill that takes several slots). A run stays in
#    one column (the break moves off it, never adding a column) and is laid as one tall button over its slots; the slots it
#    covers stay beneath it, unseen, so a drop or a click reaching one of them is still its own.

const GAP := 2.0  # between slots, down and across
const MIN_WIDTH := 62.0  # a column of slots, wrapped; narrower and names are cut to nothing
const FLOOR_WIDTH := 40.0  # even squeezed into max_width, no narrower than this
const WANT := &"want"
const RUN := &"run"

var max_height := INF  # the tallest the stack may stand before it wraps
var max_width := INF  # the widest all its columns may be together (before FLOOR_WIDTH)
var _want := 0.0  # the widest WANT among the slots, as last planned


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
	var cols := ceili(float(n) / _fit_rows(row_h, n))
	return Vector2i(cols, ceili(float(n) / cols))


# How many rows max_height holds (n: no limit).
func _fit_rows(row_h: float, n: int) -> int:
	return maxi(1, floori((max_height + GAP) / (row_h + GAP))) if is_finite(max_height) else n


func column_width(cols: int, width: float) -> float:
	var each := (width - GAP * (cols - 1)) / cols
	return each


# The widest WANT among the slots (0: none says).
func _widest() -> float:
	var w := 0.0
	for c in _slots():
		w = maxf(w, float(c.get_meta(WANT, 0.0)))
	return w


# How many rows it stands in once its names are whole: n when no slot says what it wants (one column to start with), else
# in as many columns as are that wide within max_width. What a neighbour above it should leave room for.
func standing_rows() -> int:
	var n := _slots().size()
	var want := _widest()
	if n == 0 or want <= 0.0 or not is_finite(max_width):
		return n
	return ceili(float(n) / clampi(floori((max_width + GAP) / (want + GAP)), 1, n))


# The first slot of each column. runs[i]: how many slots slot i spans (1 for most). The columns are the evenly shared ones
# of layout_for(), but a break that would fall inside a run moves to either end of it (the nearer, whichever keeps every
# column within `fit` rows); never more than `cols` columns. If nothing does, the break stays.
static func starts(runs: Array[int], cols: int, fit: int) -> Array[int]:
	var n := runs.size()
	var out: Array[int] = []
	if n > 0:
		out.append(0)
	for k in range(1, cols):
		var prev: int = out[k - 1]
		var t := prev + ceili(float(n - prev) / (cols - k + 1))  # the rest shared evenly between the columns left
		if t >= n:
			break
		var a := t - 1
		while a > prev and a + runs[a] <= t:
			a -= 1
		if a + runs[a] > t:  # the run from a spans the break
			var best := t
			var gap := n
			for c: int in [a, a + runs[a]]:
				if c > prev and c < n and c - prev <= fit and n - c <= (cols - k) * fit and absi(c - t) < gap:
					best = c
					gap = absi(c - t)
			t = best
		out.append(t)
	return out


# The columns' first slots for kids as they are now.
func _plan(kids: Array[Control], row_h: float) -> Array[int]:
	var n := kids.size()
	var runs: Array[int] = []
	_want = 0.0
	for c in kids:
		runs.append(maxi(1, int(c.get_meta(RUN, 1))))
		_want = maxf(_want, float(c.get_meta(WANT, 0.0)))
	var fit := _fit_rows(row_h, n)
	var cols := layout_for(n, row_h).x
	if _want > 0.0 and cols > 1 and is_finite(max_width):
		var by_width := maxi(1, floori((max_width + GAP) / (_want + GAP)))  # names first: as many columns as are that wide
		if by_width < cols and ceili(float(n) / by_width) <= fit:
			cols = by_width
	return starts(runs, cols, fit)


func _min_width(cols: int) -> float:
	if cols <= 1:
		return 0.0
	var each := maxf(MIN_WIDTH, _want)
	if is_finite(max_width):
		each = clampf((max_width - GAP * (cols - 1)) / cols, FLOOR_WIDTH, each)
	return each * cols + GAP * (cols - 1)


func _rows(starts_: Array[int], n: int) -> int:
	var rows := 0
	for k in starts_.size():
		rows = maxi(rows, (starts_[k + 1] if k + 1 < starts_.size() else n) - starts_[k])
	return rows


func _get_minimum_size() -> Vector2:
	var kids := _slots()
	var row_h := _row_height()
	var st := _plan(kids, row_h)
	if st.is_empty():
		return Vector2.ZERO
	var rows := _rows(st, kids.size())
	return Vector2(_min_width(st.size()), rows * row_h + GAP * (rows - 1))


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var kids := _slots()
	var row_h := _row_height()
	var st := _plan(kids, row_h)
	if st.is_empty():
		return
	var w := column_width(st.size(), size.x)
	for c in kids:
		c.self_modulate.a = 1.0
		c.z_index = 0
	for k in st.size():
		var end: int = st[k + 1] if k + 1 < st.size() else kids.size()
		for i in range(st[k], end):
			var run := mini(int(kids[i].get_meta(RUN, 1)), end - i)  # (a run cut by a break it couldn't avoid: what is in this column)
			var rect := Rect2(k * (w + GAP), (i - st[k]) * (row_h + GAP), w, row_h)
			if run > 1:
				rect.size.y = run * row_h + (run - 1) * GAP
				kids[i].z_index = 1
				for j in range(i + 1, i + run):
					kids[j].self_modulate.a = 0.0
			fit_child_in_rect(kids[i], rect)
