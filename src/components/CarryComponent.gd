class_name CarryComponent
extends Node2D

## Emitted when building completed
# signal Signal_OnBuildingCompleted(building: BuildingBase)


@export var carry_capacity: float = 10.0

# internal
var _curr_carried_items: Array[CarryableItemComponent] = []
var _curr_total_weight: float = 0.0


# ########################################################################################################################
# # PUBLIC METHODS
# ########################################################################################################################


func pickup(item: CarryableItemComponent) -> bool:
	if item == null or item.is_being_carried:
		return false

	var new_total_weight := _curr_total_weight + item.weight
	if new_total_weight > carry_capacity:
		return false

	_curr_carried_items.append(item)
	_curr_total_weight = new_total_weight
	item.is_being_carried = true
	return true

func is_carrying() -> bool:
	return not _curr_carried_items.is_empty()


func get_carried_weight() -> float:
	return _curr_total_weight


# ########################################################################################################################
# # PRIVATE METHODS
# ########################################################################################################################
# func _ready() -> void:
	# SIGNALS

	
func _physics_process(delta: float) -> void:
	# Exit if not building
	if not is_currently_building():
		return

	# Check for errors
	if _curr_building_building == null:
		stop_building()
		return
	
	# Actual Building
	_curr_building_building.update_build_process(building_speed * delta)

	# Check if building completed - this works for multiple dwarfs building the same building, each is calling this method for themselfes
	if _curr_building_building.is_complete:
		Signal_OnBuildingCompleted.emit(_curr_building_building)
		stop_building()
