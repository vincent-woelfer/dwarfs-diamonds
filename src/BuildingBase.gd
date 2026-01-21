@abstract
@tool
class_name BuildingBase
extends GridObject2D

## Set in editor for actual buildings to define type
@export var building_data: BuildingDataRes

## Building construction process
var build_process: float = 0.0
var is_complete: bool = false

# Color modulation for unfinished vs finished buildings and highlighted-for-destroy 
var internal_modulate: Color = Color.WHITE
var external_modulate: Color = Color.WHITE

# Build job associated with this building
var build_job: Job = null

# Action Points
var action_points: Array[ActionPoint] = []

# For dev
var building_color: Color


########################################################################################################################
# SETUP
########################################################################################################################
func setup_building_as_uncompleted(grid_pos_: Vector2i, building_data_: BuildingDataRes) -> void:
	super.setup(grid_pos_, Vector2.ZERO)

	building_color = Colors.get_rand_building_color()

	# Instantiate building data (incl patterns) at position
	self.building_data = building_data_.instantiate_building_data(grid_pos)

	self.z_index = Enum.ZIndex.BUILDINGS
	_set_modulate_internal(Colors.building_modulate_unfinished)
	self.light_mask = Colors.building_light_mask_unfinished

	# Initial Position
	global_position = Global.level.get_cell(grid_pos).global_position + Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR


func setup_action_points() -> void:
	action_points.clear()

	for ap_res: ActionPointRes in building_data.action_points:
		var ap := ActionPoint.new()
		var pos: Vector2i = grid_pos + ap_res.local_grid_offset
		ap.setup_action_point(pos, ap_res.type)
		action_points.append(ap)


func _ready() -> void:
	# Add pickup job
	build_job = Job.new(Job.Type.BUILD, curr_cell)
	build_job.building = self
	Global.level.job_manager.add_job(build_job)

########################################################################################################################
# Public API
########################################################################################################################
func update_build_process(building_speed_with_delta: float) -> void:
	if is_complete:
		return

	var building_with_duration := building_speed_with_delta / building_data.build_time
	build_process = clamp(build_process + building_with_duration, 0.0, 1.0)

	if build_process >= 1.0:
		_complete_construction()


func destroy_building() -> void:
	if build_job != null:
		Actions.archive_job(build_job, false)


func _set_modulate_internal(color: Color) -> void:
	internal_modulate = color
	self.modulate = internal_modulate * external_modulate

func set_modulate_external(color: Color) -> void:
	external_modulate = color
	self.modulate = internal_modulate * external_modulate


########################################################################################################################
# PRIVATE
########################################################################################################################
func _complete_construction() -> void:
	if is_complete:
		return

	print_rich("%s completed" % [self])
	is_complete = true

	# Complete build job and delete reference
	Actions.archive_job(build_job, true)
	build_job = null
	
	# Update visual
	_set_modulate_internal(Colors.building_modulate_finished)
	self.light_mask = Colors.building_light_mask_finished

	# Flash & audio effect
	_flash(Color(3, 3, 3), 0.25)
	Audio.play_at_pos("building_complete", global_position)

	# Update nav for all building cells
	for pos in building_data.pattern_building.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell != null:
			cell.queue_nav_update()

	# Action Points setup
	setup_action_points()
	Global.level.building_manager.register_action_points(self)


func _flash(color: Color, duration: float) -> void:
	var start_color: Color = internal_modulate
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _set_modulate_internal(color))
	tween.tween_interval(duration)
	tween.tween_callback(func() -> void: _set_modulate_internal(start_color))


func _to_string() -> String:
	var print_color := Colors.to_print_color(building_color)
	return Util.color_string("%s @%s" % [building_data.name, grid_pos], print_color)
