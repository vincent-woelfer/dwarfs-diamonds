# @abstract
@tool
class_name BuildingBase
extends GridObject2D


@export var building_data: BuildingData
var build_process: float = 0.0
var is_complete: bool = false

var grid_pattern_build_base: GridPattern

const modulate_done: Color = Color(1, 1, 1, 1.0)
const modulate_unfinished: Color = Color(0.5, 0.5, 0.5, 1.0)


func place_building(grid_pos_: Vector2i, building_data_: BuildingData) -> void:
	super.setup(grid_pos_, Vector2.ZERO)
	self.building_data = building_data_
	self.modulate = modulate_unfinished

	grid_pattern_build_base = GridPattern.new(building_data.grid_pattern.pattern, grid_pos_)


func _ready() -> void:
	self.modulate = modulate_unfinished

	if building_data:
		grid_pattern_build_base = GridPattern.new(building_data.grid_pattern.pattern, Vector2i.ZERO)


func update_build_process(building_speed_with_delta: float) -> void:
	if is_complete:
		return

	var building_with_duration := building_speed_with_delta / building_data.build_time
	build_process = clamp(build_process + building_with_duration, 0.0, 1.0)

	if build_process >= 1.0:
		is_complete = true
		self.modulate = modulate_done
