extends PanelContainer
## Shared top banner with branding + 6-resource HUD. Used by territory_map
## and week_view. Stays in sync with ResourceManager via the existing
## SignalBus.resource_changed signal — no per-scene HUD wiring needed.
##
## The legacy hud.tscn (vertical top-right stack) is still wired into
## door_knock.tscn; replacing that one is a future polish session, not in
## scope here.

@onready var _conviction_value: Label = $BannerMargin/BannerRow/StatRow/ConvictionStat/Value
@onready var _elders_value:     Label = $BannerMargin/BannerRow/StatRow/EldersStat/Value
@onready var _cong_value:       Label = $BannerMargin/BannerRow/StatRow/CongregationStat/Value
@onready var _family_value:     Label = $BannerMargin/BannerRow/StatRow/FamilyStat/Value
@onready var _energy_value:     Label = $BannerMargin/BannerRow/StatRow/EnergyStat/Value
@onready var _hours_value:      Label = $BannerMargin/BannerRow/StatRow/HoursStat/Value


func _ready() -> void:
	SignalBus.resource_changed.connect(_on_resource_changed)
	_refresh()


func _refresh() -> void:
	_conviction_value.text = str(ResourceManager.conviction)
	_elders_value.text     = str(ResourceManager.standing_elders)
	_cong_value.text       = str(ResourceManager.standing_congregation)
	_family_value.text     = str(ResourceManager.standing_family)
	_energy_value.text     = "%d / %d" % [ResourceManager.energy, ResourceManager.energy_max]
	_hours_value.text      = "%.1f" % ResourceManager.field_service_hours


func _on_resource_changed(_resource_name: String, _value: float) -> void:
	_refresh()
