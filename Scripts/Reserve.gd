class_name Reserve
extends Resource

# An energy type beyond the default Energy (mana, stamina, sweet nothings...).
@export var name := ""
@export var color := Color.WHITE
@export var only: Array[StringName] = []  # skill tags it can pay for (mana: magic); empty: any
