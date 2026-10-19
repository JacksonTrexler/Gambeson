class_name Effect
extends Resource

# LUCK: +/- luck. MITIGATE: fraction of damage blocked for matching tags (0.01 = 1%).
# INITIATIVE: bonus to the faction's initiative total; faction-wide, doesn't stack.
enum Kind { LUCK, MITIGATE, INITIATIVE }

@export var kind := Kind.LUCK
@export var amount := 1.0
@export var tags: Array[StringName] = []  # MITIGATE: which damage it applies to
@export var per_stat := &""  # optional scaling, e.g. charisma: amount x floor(charisma / per)
@export var per := 10
@export var turns := 0  # set by actives: how many of the target's turns it lasts
