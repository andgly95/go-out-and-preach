extends CanvasLayer
## Visible meter readouts (GDD § 5.1). Reusable across week_view, territory
## map, meeting hall, etc. Doubt is intentionally excluded — that's M4.

@onready var _conviction_label: Label = $MarginContainer/VBoxContainer/ConvictionLabel
@onready var _elders_label: Label = $MarginContainer/VBoxContainer/EldersLabel
@onready var _congregation_label: Label = $MarginContainer/VBoxContainer/CongregationLabel
@onready var _family_label: Label = $MarginContainer/VBoxContainer/FamilyLabel
@onready var _energy_label: Label = $MarginContainer/VBoxContainer/EnergyLabel
@onready var _hours_label: Label = $MarginContainer/VBoxContainer/HoursLabel


func _ready() -> void:
	SignalBus.resource_changed.connect(_on_resource_changed)
	_refresh_all()


func _refresh_all() -> void:
	_conviction_label.text = tr("Conviction: %d") % ResourceManager.conviction
	_elders_label.text = tr("Elders: %d") % ResourceManager.standing_elders
	_congregation_label.text = tr("Congregation: %d") % ResourceManager.standing_congregation
	_family_label.text = tr("Family: %d") % ResourceManager.standing_family
	_energy_label.text = tr("Energy: %d / %d") % [ResourceManager.energy, ResourceManager.energy_max]
	_hours_label.text = tr("Hours this month: %.1f") % ResourceManager.field_service_hours


func _on_resource_changed(_name: String, _value: float) -> void:
	_refresh_all()
