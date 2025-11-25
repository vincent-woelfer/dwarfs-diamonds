class_name BuildingPreview
extends Node2D

########################################################################################################################
# Mouse-Pointer attached preview of a building being placed
# This is NOT a unfinished building, just a visual preview
########################################################################################################################

# Positions
var grid_pos: Vector2i
var curr_cell: Cell = null
var prev_cell: Cell = null

# State
var building_data: BuildingData = null # Actts as is_active flag, null = inactive
var is_valid_placement: bool = true

# Preview Sprite
var preview_scene: Node2D = null
var preview_tween: Tween = null

# Constant Colors
const modulate_valid: Color = Color(1.0, 1.0, 1.0, 1.0)
const modulate_invalid: Color = Color(1.1, 0.5, 0.5, 1.0)

var shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	self.modulate = modulate_valid
	set_building_data(null)


func _process(delta: float) -> void:
	if not building_data:
		return

	# Mouse position follows automatically via Node2D position
	# Update position snapped to grid and current cell
	curr_cell = Global.level.get_cell_at_world_pos(global_position)

	# Abort if no current cell
	if curr_cell == null:
		visible = false
		prev_cell = null
		return
	else:
		visible = true
		grid_pos = curr_cell.grid_pos

		# Reset shake on new cell
		if prev_cell != curr_cell:
			prev_cell = curr_cell
			if preview_tween != null:
				preview_tween.kill()
			shake_offset = Vector2.ZERO

	# Snap Preview Scene to cell position
	preview_scene.global_position = curr_cell.global_position + Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR + shake_offset

	# Update validity
	_update_is_valid_placement(building_data.is_placeable_at(grid_pos))


func place_building(finish_instantly: bool = false) -> bool:
	if building_data == null:
		return false

	_update_is_valid_placement(building_data.is_placeable_at(grid_pos))
	if not is_valid_placement:
		# Visual feedback for invalid placement
		_shake(0.3, 20.0)
		return false

	var building := Actions.place_building(curr_cell, building_data, finish_instantly)
	if building == null:
		return false

	return true


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


func _update_is_valid_placement(is_valid: bool) -> void:
	is_valid_placement = is_valid
	if is_valid_placement:
		preview_scene.modulate = modulate_valid
	else:
		preview_scene.modulate = modulate_invalid


func _shake(duration: float, strength: float) -> void:
	if preview_tween != null:
		preview_tween.kill()

	preview_tween = get_tree().create_tween()
	preview_tween.set_ease(Tween.EASE_OUT)
	preview_tween.set_trans(Tween.TRANS_BOUNCE)

	# var max_offset := (Vector2.ONE * strength).rotated(randf() * TAU)
	var max_offset := (Vector2(1, 0) * strength)

	self.shake_offset = max_offset
	preview_tween.tween_property(self, "shake_offset", Vector2.ZERO, duration)
