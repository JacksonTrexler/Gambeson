class_name Spellbook
extends PanelContainer

# A unit's skills: actives and passives side by side, highest rank first, each with its rank in
# numerals. Skills with an active part drag onto the hotbar; toggled passives switch from here.

signal switched(skill: Skill)

var unit: Unit

@onready var heading: Label = %BookTitle
@onready var actives: VBoxContainer = %Actives
@onready var passives: VBoxContainer = %Passives
@onready var footer: Label = %BookHint


func _ready() -> void:
	%BookClose.pressed.connect(hide)


# can_switch(skill): whether that toggled passive may be switched right now.
func open(u: Unit, title: String, can_edit: bool, can_switch: Callable) -> void:
	unit = u
	fill(title, can_edit, can_switch)
	show()


func fill(title: String, can_edit: bool, can_switch: Callable) -> void:
	heading.text = "Spellbook · " + title
	for c in actives.get_children() + passives.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	var entries: Array[Slot] = unit.slots
	entries.sort_custom(func(a: Slot, b: Slot) -> bool:
		return a.rank > b.rank or (a.rank == b.rank and a.skill.name < b.skill.name))
	for x in entries:
		var e := SkillEntry.new(x.skill, x.rank, x.on, can_edit, can_switch.call(x.skill))
		e.switched.connect(switched.emit)
		(passives if x.skill.passive else actives).add_child(e)
	for list in [actives, passives]:
		if list.get_child_count() == 0:
			var none := Label.new()
			none.theme_type_variation = &"Muted"
			none.text = "None"
			list.add_child(none)
	footer.text = "Drag a skill onto a hotbar slot · right-click a slot to empty it" if can_edit \
			else "Only your own units' hotbars can be changed."
