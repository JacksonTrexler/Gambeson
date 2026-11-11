class_name Spellbook
extends PanelContainer

# A unit's skills: actives and passives side by side, highest rank first, each with its rank in
# numerals. Skills with an active part drag onto the hotbar; toggled passives switch from here. The
# one clicked shows below in full, as the skills screen shows it (SkillDetail), without its buy button.

signal switched(skill: Skill)

var unit: Unit
var picked: Skill  # the skill shown in full below

@onready var heading: Label = %BookTitle
@onready var actives: VBoxContainer = %Actives
@onready var passives: VBoxContainer = %Passives
@onready var footer: Label = %BookHint
@onready var detail: SkillDetail = %BookDetail


func _ready() -> void:
	%BookClose.pressed.connect(hide)


# can_switch(skill): whether that toggled passive may be switched right now.
func open(u: Unit, title: String, can_edit: bool, can_switch: Callable) -> void:
	if u != unit:
		picked = null
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
		e.picked.connect(pick)
		(passives if x.skill.passive else actives).add_child(e)
	for list in [actives, passives]:
		if list.get_child_count() == 0:
			var none := Label.new()
			none.theme_type_variation = &"Muted"
			none.text = "None"
			list.add_child(none)
	if not entries.any(func(x: Slot): return x.skill == picked):
		picked = entries[0].skill if not entries.is_empty() else null
	pick(picked)
	footer.text = "" if can_edit else "Only your own units' hotbars can be changed."
	footer.visible = not can_edit


# Shows s in full below (a click on its entry), its entry lit.
func pick(s: Skill) -> void:
	picked = s
	detail.show_skill(unit, s, false, false)
	for list in [actives, passives]:
		for e in list.get_children():
			if e is SkillEntry:
				e.lit = e.skill == s
