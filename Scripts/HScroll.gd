class_name HScroll
extends HBoxContainer

# A row that never wraps: put any wide Control in it (a Choice's options, a tab strip, an icon row) and
# it scrolls sideways instead of widening its menu. Whatever child nodes the scene gives it are moved
# into the strip. Scrolls by the mouse wheel (shift-wheel, or a sideways wheel, too), a trackpad
# pan, dragging the row, or the edge arrows (shown only while there's more that way).
# The one scroll rule is `amount()`; `ensure_visible(c)` brings a child into view.

const STEP := 48.0  # px per wheel notch
const PAN := 8.0  # a trackpad pan's delta is a fraction of the strip's width: width / PAN per unit
const DRAG_FROM := 4.0  # px of drag before it's a drag and not a click

@export var max_width := 420.0  # the widest the strip asks its menu for; past that it scrolls (the arrows and a page's bar still fit 480)

var strip := ScrollContainer.new()
var left := Button.new()
var right := Button.new()
var _drag := -1.0  # where a held left button went down, or -1
var _dragging := false
var _wide := false


func _init() -> void:
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER  # the arrows say it
	strip.follow_focus = true
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for pair: Array in [[left, "<", -1.0], [right, ">", 1.0]]:
		var b: Button = pair[0]
		b.text = pair[1]
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: scroll_by(pair[2] * maxf(strip.size.x - STEP, STEP)))
	add_child(left)
	add_child(strip)
	add_child(right)


func _ready() -> void:
	for c in get_children():
		if c is Control and c != strip and c != left and c != right:
			c.reparent(strip, false)
			c.minimum_size_changed.connect(_fit)
	strip.get_h_scroll_bar().changed.connect(_arrows)
	strip.get_h_scroll_bar().value_changed.connect(func(_v: float) -> void: _arrows())
	strip.resized.connect(_arrows)
	_fit()


# How far (px, + is right) an input event scrolls the row; 0 if it isn't a scroll. The wheel's up/down
# and its sideways notches all go sideways (the row has no up or down); a pan goes by its larger axis.
static func amount(e: InputEvent, width: float) -> float:
	if e is InputEventMouseButton and e.pressed:
		var notch := STEP * maxf(e.factor, 1.0)
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT: return -notch
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT: return notch
	elif e is InputEventPanGesture:
		var d: Vector2 = e.delta
		return (d.x if absf(d.x) > absf(d.y) else d.y) * width / PAN
	elif e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT:
		return -e.relative.x  # dragging the row: it follows the cursor
	return 0.0


func scroll_by(px: float) -> void:
	var bar := strip.get_h_scroll_bar()
	strip.scroll_horizontal = clampi(strip.scroll_horizontal + roundi(px), 0, maxi(0, roundi(bar.max_value - bar.page)))


func ensure_visible(c: Control) -> void:
	strip.ensure_control_visible(c)


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var inside := Rect2(Vector2.ZERO, strip.size).has_point(strip.make_input_local(e).position)
		if e.pressed and inside:
			_drag = 0.0
		elif not e.pressed:
			var was := _dragging  # a drag's release isn't a click on whatever it ended over
			_drag = -1.0
			_dragging = false
			if was:
				get_viewport().set_input_as_handled()
		return
	if not (e is InputEventMouseButton or e is InputEventPanGesture or (e is InputEventMouseMotion and _drag >= 0.0)):
		return
	if e is InputEventMouseMotion:
		_drag += absf(e.relative.x)
		if _drag < DRAG_FROM and not _dragging:
			return
		if not _dragging:  # past the slop: it's a drag, so the button under the cursor lets go
			_dragging = true
			var held := get_viewport().gui_get_focus_owner()
			if held and strip.is_ancestor_of(held):
				held.release_focus()
	elif not Rect2(Vector2.ZERO, strip.size).has_point(strip.make_input_local(e).position):
		return
	var px := amount(e, strip.size.x)
	if px != 0.0 and left.visible:  # a row with nowhere to go lets the wheel through to the page (VScroll) behind it
		scroll_by(px)
		get_viewport().set_input_as_handled()


# The strip asks its menu for the row's width, no more than max_width: the rest scrolls.
func _fit() -> void:
	var need := 0.0
	for c in strip.get_children():
		if c is Control:
			need = maxf(need, c.get_combined_minimum_size().x)
	strip.custom_minimum_size.x = minf(need, max_width)
	_wide = need > max_width
	_arrows()


# Both arrows show while the row scrolls at all (so the strip doesn't resize as one comes and goes); one
# dims at its end.
func _arrows() -> void:
	var bar := strip.get_h_scroll_bar()
	var room := bar.max_value - bar.page
	left.visible = _wide or room > 0.5
	right.visible = left.visible
	left.disabled = strip.scroll_horizontal <= 0
	right.disabled = strip.scroll_horizontal >= room - 0.5
