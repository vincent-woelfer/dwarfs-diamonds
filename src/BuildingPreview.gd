class_name BuildingPreview
extends Node2D

########################################################################################################################
# Mouse-Pointer attached preview of a building being placed
# This is NOT a unfinished building, just a visual preview
########################################################################################################################

# Positions
var grid_pos: Vector2i
var curr_cell: Cell = null

# State
var building_data: BuildingData = null # Actts as is_active flag, null = inactive
var is_valid_placement: bool = true

# Preview Sprite
var preview_scene: Node2D = null


# Constant Colors
const modulate_valid: Color = Color(1, 1, 1, 0.5)
const modulate_invalid: Color = Color(1, 0.3, 0.3, 0.5)


func _ready() -> void:
	self.modulate = modulate_valid
	set_building_data(null)


func _process(delta: float) -> void:
	if not building_data:
		return

	# Mouse position follows automatically via Node2D position
	# Update position snapped to grid and current cell
	grid_pos = Global.level.get_cell_at_world_pos(global_position).grid_pos
	curr_cell = Global.level.get_cell(grid_pos)

	# Abort if no current cell
	if curr_cell == null:
		visible = false
		return

	# Snap Preview Scene to cell position
	preview_scene.global_position = curr_cell.global_position + Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR

	# Update validity
	if building_data.is_placeable_at(grid_pos):
		_set_validity(true)
	else:
		_set_validity(false)


func set_building_data(building_data_new: BuildingData) -> void:
	if building_data == building_data_new:
		return

	building_data = building_data_new

	# Clear previous preview scene
	if preview_scene != null:
		preview_scene.queue_free()

	# Disable if no building data
	if building_data == null:
		visible = false
		return
	else:
		visible = true

	# Instantiate new preview scene
	preview_scene = building_data.instantiate_preview_scene()
	if preview_scene == null:
		visible = false
		building_data = null
		return

	add_child(preview_scene)
	preview_scene.top_level = true


func _set_validity(is_valid: bool) -> void:
	is_valid_placement = is_valid
	if is_valid_placement:
		self.modulate = modulate_valid
	else:
		self.modulate = modulate_invalid
