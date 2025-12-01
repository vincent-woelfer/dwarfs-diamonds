@abstract
@tool
class_name BuildingBase
extends GridObject2D

## Set in editor for actual buildings to define type
@export var building_data: BuildingData

## Building construction process
var build_process: float = 0.0
var is_complete: bool = false


func setup_building(grid_pos_: Vector2i, building_data_: BuildingData) -> void:
	super.setup(grid_pos_, Vector2.ZERO)

	# Instantiate building data (incl patterns) at position
	self.building_data = building_data_.instantiate_building_data(grid_pos)

	self.z_index = Enum.ZIndex.BUILDINGS
	self.modulate = Colors.building_modulate_unfinished
	self.light_mask = Colors.building_light_mask_unfinished

	# Initial Position
	global_position = Global.level.get_cell(grid_pos).global_position + Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR


func update_build_process(building_speed_with_delta: float) -> void:
	if is_complete:
		return

	var building_with_duration := building_speed_with_delta / building_data.build_time
	build_process = clamp(build_process + building_with_duration, 0.0, 1.0)

	if build_process >= 1.0:
		_complete()

		
func _complete() -> void:
	print_rich("Building %s completed at %s" % [building_data.name, grid_pos])
	is_complete = true
	self.modulate = Colors.building_modulate_finished
	self.light_mask = Colors.building_light_mask_finished

	# Update nav for all building cells
	for pos in building_data.pattern_building.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell != null:
			cell.queue_nav_update()
