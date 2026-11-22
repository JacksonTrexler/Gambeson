class_name Property
extends Resource

# Something a unit is made of or full of (Bio.properties): Aquatic, Energized, Radiant, Rotting. Its
# effects are always on the unit (Unit._gather_effects()) - mostly resistances (mitigate, tagged) and
# vulnerabilities (mitigate below 0) - and those who make out its identity read it (Read.properties).
# Util/mechanic.py property writes one.
@export var name := ""
@export var tags: Array[StringName] = []  # what it makes the unit count as, for skills that ask (Aquatic: water)
@export var effects: Array[Effect] = []  # always on whoever has it
@export var text := ""  # one line: what it does, for the unit card's tooltip
