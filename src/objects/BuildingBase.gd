@abstract
@tool
class_name BuildingBase
extends GridObject2D

## Set in editor for actual buildings to define type, gets instantiated for actual building pos when placed.
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


@onready var building_sprite: Sprite2D = $Sprite2D


########################################################################################################################
# SETUP
########################################################################################################################
# Called from Actions.place_building
func setup_building_as_uncompleted(grid_pos_: Vector2i, building_data_: BuildingDataRes) -> void:
	super.setup(grid_pos_, Vector2.ZERO)

	building_color = Colors.get_rand_building_color()

	# Instantiate building data (incl patterns) at position
	self.building_data = building_data_.instantiate_building_data(grid_pos)

	self.z_index = Enum.ZIndex.BUILDINGS
	self.light_mask = Colors.building_light_mask_unfinished
	_set_modulate_internal(Colors.building_modulate_unfinished)

	# Initial Position
	global_position = Global.level.get_cell(grid_pos).global_position + Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR

	# Play sound effect
	Audio.play_at_pos("building_placed", global_position)


# Called internally when building is completed
func _setup_action_points() -> void:
	action_points.clear()

	for ap_res: ActionPointRes in building_data.action_points:
		var ap := ActionPoint.new()
		var pos: Vector2i = grid_pos + ap_res.local_grid_offset
		ap.setup_action_point(pos, ap_res.type)
		action_points.append(ap)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	# Add build job
	build_job = Job.new(Job.Type.BUILD, curr_cell)
	build_job.building = self
	Global.level.job_manager.add_job(build_job)

	# Signals
	EventBus.Signal_CellDestroyed.connect(_check_solid_ground)

	# Sprite
	building_sprite.texture = building_data.get_building_texture(0.0)

########################################################################################################################
# Public API
########################################################################################################################
func update_build_process(building_speed_with_delta: float) -> void:
	if is_complete:
		return

	var building_with_duration := building_speed_with_delta / building_data.build_time
	build_process = clamp(build_process + building_with_duration, 0.0, 1.0)

	# Update texture
	var new_texture := building_data.get_building_texture(build_process)
	if new_texture != building_sprite.texture:
		building_sprite.texture = new_texture

	if build_process >= 1.0:
		_complete_construction()


# Called from Actions.remove_building which handles most logic
func on_destroy() -> void:
	Actions.archive_job(build_job, false)

	# Flash & audio effect
	var effect_duration := 0.25 * 3
	_flash(Color(3, 0, 0), effect_duration)
	Audio.play_at_pos("building_on_destroy", global_position)

	await Util.await_time(effect_duration)
	Global.level.building_manager.remove_building(self )


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

	is_complete = true
	print_rich("%s completed" % [ self ])

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
	var building_cells := building_data.pattern_building.get_world_positions()
	for pos in building_cells:
		var cell: Cell = Global.level.get_cell(pos)
		if cell != null:
			cell.on_building_completed(self )
			cell.queue_nav_update()

			# Should not be needed!
			# Additionally update for cell ontop (if exists) as it might be affected if building is a  platform or similar
			# var cell_ontop: Cell = Global.level.get_cell(pos + Global.VEC_UP)
			# if cell_ontop != null and cell_ontop.grid_pos not in building_cells:
			# 	cell_ontop.queue_nav_update()

	# Action Points setup
	_setup_action_points()
	Global.level.building_manager.register_action_points(self )


func _check_solid_ground(destroyed_cell: Cell) -> void:
	if not building_data.has_solid_ground_at(grid_pos):
		Actions.remove_building(self )


func _flash(color: Color, duration: float) -> void:
	var start_color: Color = internal_modulate
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _set_modulate_internal(color))
	tween.tween_interval(duration)
	tween.tween_callback(func() -> void: _set_modulate_internal(start_color))


func _to_string() -> String:
	var print_color := Colors.to_print_color(building_color)
	return Util.color_string("%s @%s" % [building_data.name(), grid_pos], print_color)
