@abstract
@tool
class_name BuildingBase
extends GridObject2D


@export var building_data: BuildingData

var build_process: float = 0.0
var is_complete: bool = false

const modulate_done: Color = Color(1, 1, 1, 1.0)
const modulate_unfinished: Color = Color(0.5, 0.5, 0.5, 1.0)
const light_mask_done: int = 1
const light_mask_unfinished: int = 0


func setup_building(grid_pos_: Vector2i, building_data_: BuildingData) -> void:
	super.setup(grid_pos_, Vector2.ZERO)

	# Instantiate building data (incl patterns) at position
	self.building_data = building_data_.instantiate_building_data(grid_pos)

	self.z_index = Enum.ZIndex.BUILDINGS
	self.modulate = modulate_unfinished
	self.light_mask = light_mask_unfinished

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
	self.modulate = modulate_done
	self.light_mask = light_mask_done

	# Update nav for all building cells
	for pos in building_data.pattern_building.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell != null:
			cell.queue_nav_update()
