extends Resource
class_name Territory
## A field-service territory: a named collection of houses. v0.1 ships
## one territory of 12 houses; M5+ may add more.

@export var id: StringName
@export var display_name: String = ""
@export var houses: Array[House] = []
