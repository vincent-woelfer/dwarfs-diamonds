class_name BuildingComponent
extends Node2D

## Emitted when building completed
signal Signal_OnBuildingCompleted(building: BuildingBase)

# per second
@export var building_speed: float = 1.0

# internal
## The cell where the building is being constructed (one of the building's cells)
var _curr_building_cell: Cell = null

## The cell from which the building is being constructed (one of the jobs workable-from and one of the buildings buildable-from cells)
var _curr_building_from_cell: Cell = null

## The building instance being constructed
var _curr_building_building: BuildingBase = null

# Reference to the used audio player
var _audio_player: AudioStreamPlayer2D = null

# ########################################################################################################################
# # PUBLIC METHODS
# ########################################################################################################################
func start_building(cell: Cell, cell_from: Cell, building: BuildingBase) -> void:
	# Check for errors
	if is_currently_building() or (cell == null or cell_from == null or building == null):
		assert(false)
		return

	# Verify that the building is being built on the correct cell
	assert(cell.buildings.count(building) == 1)

	_curr_building_cell = cell
	_curr_building_from_cell = cell_from
	_curr_building_building = building

	_audio_player = Audio.play_at_pos("hammering_looped", building.global_position)


func stop_building() -> void:
	_curr_building_cell = null
	_curr_building_from_cell = null
	_curr_building_building = null

	if _audio_player != null:
		Audio.stop_player(_audio_player)
		_audio_player = null


func is_currently_building() -> bool:
	if _curr_building_cell == null:
		assert(_curr_building_from_cell == null and _curr_building_building == null)
		return false
		
	return _curr_building_building != null


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
