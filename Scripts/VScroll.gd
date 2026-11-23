class_name VScroll
extends ScrollContainer

# A menu that scrolls up and down where it's taller than the screen (the HScroll's twin for a column).
# Put the menu's content in it (a scene's own child nodes, or `VScroll.wrap(content)`): it asks its parent for
# the content's height but no more than the screen's less `reserve` (what the rest of the menu around it takes:
# its panel's margins, the heads and buttons beside it), so a panel holding it stops at the screen's edge and the
# content scrolls inside. Filling the screen itself (a whole page), it is simply the screen's size.
# The wheel, a trackpad pan and keyboard focus (follow_focus) scroll it; the bar shows only while it's needed.
# Not HScroll's arrows and drag: a column has room for a bar, and the wheel is what a menu's reader reaches for.

@export var reserve := 16.0:  # px of the screen the menu around it keeps, so it ends just short of the edge
	set(v):
		reserve = v
		if is_node_ready():
			_fit()


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	child_entered_tree.connect(func(c: Node) -> void:
		if c is Control:
			c.minimum_size_changed.connect(_fit)
			c.visibility_changed.connect(_fit))


func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit()


# `content` in a new VScroll that takes its place under its parent (or alone, if it has none yet).
static func wrap(content: Control, keep := 16.0) -> VScroll:
	var s := VScroll.new()
	s.reserve = keep
	var at := content.get_parent()
	var i := content.get_index() if at else 0
	if at:
		at.remove_child(content)
	s.add_child(content)
	if at:
		at.add_child(s)
		at.move_child(s, i)
	return s


# The height it asks for: the content's, to the most the screen has to give.
func _fit() -> void:
	var need := 0.0
	for c in get_children():
		if c is Control and c.visible:
			need = maxf(need, c.get_combined_minimum_size().y)
	custom_minimum_size.y = minf(need, maxf(get_viewport_rect().size.y - reserve, 0.0))
