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
var building_data: BuildingDataRes = null # Acts as is_active flag, null = inactive
var is_valid_placement: bool = true

# Preview Scene
var preview_visual_base: BuildingVisualRoot = null
var preview_tween: Tween = null

# Constant Colors
const modulate_valid: Color = Color.WHITE
const modulate_invalid: Color = Color(1.1, 0.5, 0.5, 1.0)

# Current Effects, set to maximums when shaking/flashing, tweened to zero
var curr_shake_offset: Vector2 = Vector2.ZERO
var curr_modulate_red_offset: Color = Color(0.0, 0.0, 0.0, 0.0)

var curr_modulate_validity: Color = modulate_valid


func _ready() -> void:
	set_building_data(null)


func _process(delta: float) -> void:
	if not building_data:
		return

	# Mouse position follows automatically via Node2D position
	# Update position snapped to grid and current cell
	curr_cell = Global.level.sample_cell_at_world_pos(global_position)

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
			curr_shake_offset = Vector2.ZERO
			curr_modulate_red_offset = Color(0.0, 0.0, 0.0, 0.0)

	# Snap Preview Scene to cell position
	preview_visual_base.global_position = curr_cell.get_building_origin_point() + curr_shake_offset

	# Apply red flash modulate
	preview_visual_base.modulate = curr_modulate_validity + curr_modulate_red_offset

	# Update validity
	_update_is_valid_placement(PlacementChecks.is_placeable_at(building_data, grid_pos))


func attempt_to_place_preview_building(finish_instantly: bool = false) -> bool:
	if building_data == null:
		return false

	_update_is_valid_placement(PlacementChecks.is_placeable_at(building_data, grid_pos))
	if not is_valid_placement:
		# Visual feedback for invalid placement
		_shake_and_flash_red(0.3, 20.0)
		return false

	var building := Actions.place_building(curr_cell, building_data, finish_instantly)
	if building == null:
		return false

	return true


func set_building_data(building_data_new: BuildingDataRes) -> void:
	if building_data == building_data_new:
		return

	building_data = building_data_new

	# Clear previous preview scene
	if preview_visual_base != null:
		preview_visual_base.queue_free()

	# Disable if no building data
	if building_data == null:
		visible = false
		return
	else:
		visible = true

	# Instantiate new preview scene
	preview_visual_base = Util.instantiate_building_visual_base(building_data.type)
	if preview_visual_base == null:
		visible = false
		building_data = null
		return

	add_child(preview_visual_base)
	preview_visual_base.top_level = true
	# Always show as fully built, the red flash will indicate invalid placement
	preview_visual_base.update_building_progress(1.0)


func _update_is_valid_placement(is_valid: bool) -> void:
	is_valid_placement = is_valid
	if is_valid_placement:
		curr_modulate_validity = modulate_valid
	else:
		curr_modulate_validity = modulate_invalid


func _shake_and_flash_red(duration: float, strength: float) -> void:
	if preview_tween != null:
		preview_tween.kill()

	preview_tween = get_tree().create_tween()
	preview_tween.set_ease(Tween.EASE_OUT)
	preview_tween.set_trans(Tween.TRANS_BOUNCE)

	# Shake
	var angle_rad := deg_to_rad(-20) # towards top-right
	var max_offset := (Vector2(1, 0) * strength).rotated(angle_rad)
	self.curr_shake_offset = max_offset
	preview_tween.tween_property(self , "curr_shake_offset", Vector2.ZERO, duration)

	# Red flash
	const modulate_red_flash: Color = Color(0.45, 0.0, 0.0, 0.0)
	self.curr_modulate_red_offset = modulate_red_flash
	preview_tween.parallel().tween_property(self , "curr_modulate_red_offset", Color(0.0, 0.0, 0.0, 0.0), duration)
