class_name BuildingPlacementManager
extends Node2D

## Holds if cell should be highlighted for building placement for each building type.
## This is not is_placeable_at but all building_cells for each is_placeable_at check.
var placeable_highlight: Array[GridBoolArray] = []

var is_highlighting: bool = false
var curr_highlighted_building_type: Enum.BuildingType

## Settings
const include_cells_above_building_ground_floor: bool = false


########################################################################################################################
# Caching / Refresh Logic
########################################################################################################################
# Only update the building_type upon changing to it. Then as long as its active, update for every cell update.

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func is_cell_highlighted(grid_pos: Vector2i) -> bool:
	if not is_highlighting or not Util.is_grid_pos_valid(grid_pos):
		return false

	var highlight_grid: GridBoolArray = placeable_highlight[curr_highlighted_building_type]
	return highlight_grid.get_value(grid_pos)

# Also enables highlighting
func set_highlighted_building_type(building_type: Enum.BuildingType) -> void:
	if building_type == curr_highlighted_building_type and is_highlighting:
		return

	curr_highlighted_building_type = building_type
	is_highlighting = true

	_update_placement_checks(curr_highlighted_building_type)

func set_enabled(enabled: bool) -> void:
	if enabled == is_highlighting:
		return

	is_highlighting = enabled

	if is_highlighting:
		_update_placement_checks(curr_highlighted_building_type)
	else:
		# Still trigger visual update to remove highlights
		EventBus.Signal_TriggerVisualUpdateAllCells.emit()

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################

func _ready() -> void:
	for building_type: Enum.BuildingType in Enum.BuildingType.values():
		placeable_highlight.append(GridBoolArray.new())

	# Signals
	EventBus.Signal_LightDepthUpdated.connect(_on_level_updated)


func _on_level_updated() -> void:
	if is_highlighting:
		_update_placement_checks(curr_highlighted_building_type)
		

## Almost always for curr_highlighted_building_type
func _update_placement_checks(building_type: Enum.BuildingType) -> void:
	var start_time := Time.get_ticks_msec()

	var building_data: BuildingDataRes = Util.get_building_data(building_type)

	var highlight_grid: GridBoolArray = placeable_highlight[building_type]
	highlight_grid.clear()

	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var grid_pos: Vector2i = Vector2i(x, y)
			if PlacementChecks.is_placeable_at(building_data, grid_pos):
				var building_poses: Array[Vector2i] = building_data.pattern_building.get_positions(grid_pos)

				for pos in building_poses:
					if Util.is_grid_pos_valid(pos):
						if include_cells_above_building_ground_floor:
							highlight_grid.set_value(pos, true)
						elif pos.y == grid_pos.y:
							highlight_grid.set_value(pos, true)

	var duration := Time.get_ticks_msec() - start_time
	# HexLog.print("BuildingPlacement => Updated building placement checks in: %d ms" % [duration], Colors.GENERIC_INFO_PRINT_COLOR)

	EventBus.Signal_TriggerVisualUpdateAllCells.emit()
