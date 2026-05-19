@tool
class_name Building
extends GridObject2D

## Set in editor for actual buildings to define type
var building_data: BuildingDataRes

## Building construction process
var build_progress: float = 0.0

# Color modulation for unfinished vs finished buildings and highlighted-for-destroy 
var internal_modulate: Color = Color.WHITE
var external_modulate: Color = Color.WHITE

# Jobs associated with this building
var build_job: Job = null
# TOTO var material_job

# Action Points
var action_points: Array[ActionPoint] = []

# For dev - only for logging
var dev_color: Color

# Set depending on editor vs ingame and if finished instantly.
var starting_state: State = State.WAITING_FOR_MATERIAL

# State machine
# For buildings, only used in this order
enum State {WAITING_FOR_MATERIAL, IN_CONSTRUCTION, OPERATING, IN_TEARDOWN}
var sm: StateMachine

########################################################################################################################
# DEV / EDITOR ONLY
########################################################################################################################
@export var _editor_building_type: Enum.BuildingType = Enum.BuildingType.OUTPOST:
	set(value):
		_editor_building_type = value
		if Engine.is_editor_hint() and self.is_inside_tree():
			setup_building(_editor_building_type, Vector2i.ZERO)

########################################################################################################################
# Scene Nodes
########################################################################################################################
# Not on ready since spawned dynamically when building is placed
var visual_root: BuildingVisualRoot = null
var visual_root_path: String = "BuildingVisualRoot"

var grid_pattern_visualization_path: String = "GridPatternVisualization"


########################################################################################################################
# SETUP
########################################################################################################################
## Called from editor when changing building type and from game when placing building
## Setup should setup building itself, registering (e.g. with buildings manager, nav-cells) happens elsewhere.
func setup_building(building_type_: Enum.BuildingType, grid_pos_: Vector2i) -> void:
	# In Game, place building at correct position.
	if not Engine.is_editor_hint():
		setup_grid_object(grid_pos_)
		global_position = Global.level.get_cell(grid_pos).get_building_origin_point()

	# Update building data
	building_data = Util.get_building_data(building_type_)

	# Refresh grid pattern visualization
	var vis := get_node_or_null(grid_pattern_visualization_path) as GridPatternVisualization
	if vis != null:
		vis.refresh()

	# Update visual base. This involves a lot of checks for editor scenes.
	# Remove previous visual base if exists. Also check by name if it exists already.
	if visual_root != null:
		remove_child(visual_root)
		visual_root.queue_free()
	if get_node_or_null(visual_root_path) != null:
		visual_root = get_node_or_null(visual_root_path)
		remove_child(visual_root)
		visual_root.queue_free()
	
	# Update visual base
	visual_root = Util.instantiate_building_visual_base(building_type_)
	visual_root.name = visual_root_path
	add_child(visual_root)

	# In editor, set owner to edited scene root so it gets saved with the scene
	if Engine.is_editor_hint() and get_tree() != null and get_tree().edited_scene_root != null:
		visual_root.owner = get_tree().edited_scene_root


func _ready() -> void:
	# For Editor and Game
	dev_color = Colors.get_rand_building_dev_color()
	self.z_index = Enum.ZIndex.BUILDINGS

	# Editor setup - ingame setup happens when placing building
	if Engine.is_editor_hint():
		setup_building(_editor_building_type, Vector2i.ZERO)
		starting_state = State.OPERATING

	# State machine. Starting state is set depending on if in editor or game and if finished instantly or not (for testing purposes)
	# We override this here if its "waiting for material" but building doesnt have required materials.
	if starting_state == State.WAITING_FOR_MATERIAL and building_data.required_materials.is_empty():
		starting_state = State.IN_CONSTRUCTION
	sm = StateMachine.new(self , State, starting_state)

	# Only for Game
	if not Engine.is_editor_hint():
		# Signals
		EventBus.Signal_CellDestroyed.connect(_check_solid_ground)


########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################
func _physics_process(delta: float) -> void:
	sm.physics_process(delta)


###################################
# Waiting for material
###################################
func _enter_waiting_for_material() -> void:
	print_rich("%s placed (waiting for materials: %s)" % [ self , building_data.required_materials])

	# Visuals
	self.light_mask = Colors.building_light_mask_unfinished
	_set_modulate_internal(Colors.building_modulate_unfinished)

	# TODO add job

func _exit_waiting_for_material() -> void:
	pass
	# TODO remove job


###################################
# In construction
###################################
func _enter_in_construction() -> void:
	print_rich("%s starting construction" % [ self ])

	# Visuals
	self.light_mask = Colors.building_light_mask_unfinished
	_set_modulate_internal(Colors.building_modulate_unfinished)

	# Add build job
	build_job = Job.new(Job.Type.BUILD, curr_cell)
	build_job.building = self
	Global.level.job_manager.add_job(build_job)

func _exit_in_construction() -> void:
	# Complete build job and delete reference
	Actions.archive_job(build_job, true)
	build_job = null

###################################
# Operating
###################################
func _enter_operating() -> void:
	print_rich("%s completed" % [ self ])

	# Update visual
	self.light_mask = Colors.building_light_mask_finished
	_set_modulate_internal(Colors.building_modulate_finished)

	visual_root.update_building_progress(1.0)

	# Flash & audio effect
	_flash(Color(3, 3, 3), 0.25)
	Audio.play_at_pos("building_complete", global_position)

	# Update nav for all building cells
	var building_cells := building_data.pattern_building.get_positions(grid_pos)
	for pos in building_cells:
		var cell: Cell = Global.level.get_cell(pos)
		if cell != null:
			cell.on_building_completed(self )
			cell.queue_nav_update()

	# Action Points setup
	_setup_action_points()
	Global.level.building_manager.register_action_points(self )

func _exit_operating() -> void:
	pass

####################################
# In teardown
####################################
func _enter_in_teardown() -> void:
	if build_job != null:
		Actions.archive_job(build_job, false)


	# Flash & audio effect
	var effect_duration := 0.25 * 3
	_flash(Color(3, 0, 0), effect_duration)
	Audio.play_at_pos("building_on_destroy", global_position)

	await Util.await_time(effect_duration)
	Global.level.building_manager.remove_building(self )


########################################################################################################################
# Public API
########################################################################################################################
func update_build_progress(building_speed_with_delta: float) -> void:
	if sm.state != State.IN_CONSTRUCTION:
		return

	var building_with_duration := building_speed_with_delta / building_data.build_time
	build_progress = clamp(build_progress + building_with_duration, 0.0, 1.0)

	if build_progress >= 1.0:
		sm.transition_to(State.OPERATING)
	else:
		visual_root.update_building_progress(build_progress)


# Called from Actions.remove_building which handles most logic (like calling building_manager.unregister_building() and removing from cells)
func destroy() -> void:
	if sm.state != State.IN_TEARDOWN:
		sm.transition_to(State.IN_TEARDOWN)


func is_operating() -> bool:
	return sm.state == State.OPERATING

########################################################################################################################
# PRIVATE
########################################################################################################################
# Called internally when building is completed
func _setup_action_points() -> void:
	action_points.clear()

	for ap_res: ActionPointRes in building_data.action_points:
		var ap := ActionPoint.new()
		var pos: Vector2i = grid_pos + ap_res.local_grid_offset
		ap.setup_action_point(pos, ap_res.type)
		action_points.append(ap)

		# TODO DEV also remove or add from elsewhere
		add_child(ap)


## Triggered by cell destruction signal
func _check_solid_ground(destroyed_cell: Cell) -> void:
	if sm.state == State.IN_TEARDOWN:
		return

	if not PlacementChecks.has_solid_ground_at(building_data, grid_pos):
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


func _set_modulate_internal(color: Color) -> void:
	internal_modulate = color
	self.modulate = internal_modulate * external_modulate

func set_modulate_external(color: Color) -> void:
	external_modulate = color
	self.modulate = internal_modulate * external_modulate
