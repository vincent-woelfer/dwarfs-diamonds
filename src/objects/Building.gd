@tool
class_name Building
extends GridObject2D

## Set in editor for actual buildings to define type, gets instantiated for actual building pos when placed.
var building_data: BuildingDataRes

## Building construction process
var build_progress: float = 0.0
var is_complete: bool = false

# Color modulation for unfinished vs finished buildings and highlighted-for-destroy 
var internal_modulate: Color = Color.WHITE
var external_modulate: Color = Color.WHITE

# Build job associated with this building
var build_job: Job = null

# Action Points
var action_points: Array[ActionPoint] = []

# For dev - only for logging
var dev_color: Color

########################################################################################################################
# DEV / EDITOR ONLY
########################################################################################################################
@export var _editor_building_type: Enum.BuildingType:
	set(value):
		if Engine.is_editor_hint():
			_editor_building_type = value
			setup_building_type(_editor_building_type)

########################################################################################################################
# Scene Nodes
########################################################################################################################
@onready var grid_pattern_visualization: GridPatternVisualization = $GridPatternVisualization
var visual_base: BuildingVisualRoot = null


########################################################################################################################
# SETUP
########################################################################################################################
func setup_building_type(building_type_: Enum.BuildingType) -> void:
	# Update visual base
	if visual_base != null:
		remove_child(visual_base)
		visual_base.free()
	
	visual_base = Util.instantiate_building_visual_base(building_type_)
	add_child(visual_base)

	# Update building data
	building_data = Util.get_building_data(building_type_)


# Called from Actions.place_building
func setup_at_pos(grid_pos_: Vector2i) -> void:
	super.setup(grid_pos_, Vector2.ZERO)

	# Instantiate building data (incl patterns) at position
	# TODO DEV remove instantiate at compeltely
	self.building_data = building_data.instantiate_building_data(grid_pos)

	# Initial Position
	global_position = Global.level.get_cell(grid_pos).global_position + Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR


func _ready() -> void:
	# Editor only:
	if Engine.is_editor_hint():
		setup_building_type(Enum.BuildingType.OUTPOST) # as  default for editor only
		setup_at_pos(Vector2.ZERO)

	# Only for Game
	if not Engine.is_editor_hint():
		# Add build job
		build_job = Job.new(Job.Type.BUILD, curr_cell)
		build_job.building = self
		Global.level.job_manager.add_job(build_job)
		
		# Signals
		EventBus.Signal_CellDestroyed.connect(_check_solid_ground)

	# For Editor and Game
	dev_color = Colors.get_rand_building_dev_color()

	self.z_index = Enum.ZIndex.BUILDINGS
	self.light_mask = Colors.building_light_mask_unfinished
	_set_modulate_internal(Colors.building_modulate_unfinished)


# Called internally when building is completed
func _setup_action_points() -> void:
	action_points.clear()

	for ap_res: ActionPointRes in building_data.action_points:
		var ap := ActionPoint.new()
		var pos: Vector2i = grid_pos + ap_res.local_grid_offset
		ap.setup_action_point(pos, ap_res.type)
		action_points.append(ap)


########################################################################################################################
# Public API
########################################################################################################################
func update_build_progress(building_speed_with_delta: float) -> void:
	if is_complete:
		return

	var building_with_duration := building_speed_with_delta / building_data.build_time
	build_progress = clamp(build_progress + building_with_duration, 0.0, 1.0)

	visual_base.update_building_progress(build_progress)

	if build_progress >= 1.0:
		_complete_construction()


# Called from Actions.remove_building which handles most logic (like calling building_manager.unregister_building() and removing from cells)
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
	var print_color := Colors.to_print_color(dev_color)
	return Util.color_string("%s @%s" % [building_data.name, grid_pos], print_color)
