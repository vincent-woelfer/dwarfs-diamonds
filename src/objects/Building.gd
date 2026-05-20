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
var material_ap: ActionPoint = null
var material_storage: StorageComponent = null

# For dev - only for logging
var dev_color: Color

# Set depending on editor vs ingame and if finished instantly.
var starting_state: State = State.WAITING_FOR_MATERIAL

# State machine
enum State {WAITING_FOR_MATERIAL, IN_CONSTRUCTION, OPERATING, IN_TEARDOWN}
var sm: StateMachine

var sm_transition_table: Dictionary[int, Array] = {
	State.WAITING_FOR_MATERIAL: [State.IN_CONSTRUCTION, State.IN_TEARDOWN],
	State.IN_CONSTRUCTION: [State.OPERATING, State.IN_TEARDOWN],
	State.OPERATING: [State.IN_TEARDOWN],
	State.IN_TEARDOWN: [],
}

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

	sm = StateMachine.new(self , State, starting_state, sm_transition_table)
	sm.set_state_exitable(State.IN_TEARDOWN, false)

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
	assert(not building_data.required_materials.is_empty())
	print_rich("%s placed (waiting for materials: %s)" % [ self , building_data.required_materials])

	# Visuals
	self.light_mask = Colors.building_light_mask_unfinished
	_set_modulate_internal(Colors.building_modulate_unfinished)

	# Action points - Setup material AP
	if not _setup_material_action_point():
		push_error("Failed to setup material action point for building %s! Transitioning to IN_CONSTRUCTION anyway." % self )
		sm.transition_to(State.IN_CONSTRUCTION)
		return

	# TODO add job


func _exit_waiting_for_material() -> void:
	# Remove action points
	Global.level.building_manager.unregister_action_points(self , [material_ap])

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

	# Remove material storage
	if material_storage != null:
		material_storage.drop_all()
		material_storage.queue_free()
		material_storage = null

###################################
# Operating
###################################
func _enter_operating() -> void:
	print_rich("%s completed (operational)" % [ self ])

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

	_setup_action_points([ActionPoint.ApType.DROPOFF_RUBBLE, ActionPoint.ApType.DROPOFF_GEMSTONE])


####################################
# In teardown
####################################
func _enter_in_teardown() -> void:
	if build_job != null:
		Actions.archive_job(build_job, false)
		build_job = null

	# Remove material storage
	if material_storage != null:
		material_storage.drop_all()
		material_storage.queue_free()
		material_storage = null

	# Includes deleting action points
	Global.level.building_manager.teardown_building(self )

	# Flash & audio effect
	var effect_duration := 0.25 * 3
	_flash(Color(3, 0, 0), effect_duration)
	Audio.play_at_pos("building_on_destroy", global_position)

	# Wait for effect to finish before deleting building
	await Util.await_time(effect_duration)
	Global.level.building_manager.delete_building(self )


########################################################################################################################
# Public API
########################################################################################################################
func update_build_progress(building_speed_with_delta: float) -> void:
	if sm.state != State.IN_CONSTRUCTION:
		return

	var building_with_duration := building_speed_with_delta / building_data.build_time
	build_progress = clamp(build_progress + building_with_duration, 0.0, 1.0)

	# Update visual (incl. material storage emptying)
	visual_root.update_building_progress(build_progress)
	if material_storage != null:
		var total_count: int = building_data.required_materials.get_total_item_count()
		var should_be_left: int = clampi(roundi((1.0 - build_progress) * total_count), 0, total_count)
		while material_storage.get_carried_total_count() > should_be_left:
			material_storage.delete(material_storage.get_last_item())

	if build_progress >= 1.0:
		sm.transition_to(State.OPERATING)


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
func _setup_action_points(types: Array[ActionPoint.ApType]) -> void:
	for ap_res: ActionPointRes in building_data.action_points:
		if not ap_res.type in types:
			continue

		var pos: Vector2i = grid_pos + ap_res.grid_offset
		var ap: ActionPoint = ActionPoint.setup_bare_ap(pos, ap_res.type)

		if ap.type in [ActionPoint.ApType.DROPOFF_RUBBLE, ActionPoint.ApType.DROPOFF_GEMSTONE]:
			ap.setup_dropoff_ap()

		action_points.append(ap)
		Global.level.building_manager.register_action_points(self , [ap])


func _setup_material_action_point() -> bool:
	# Only call if building has required materials, otherwise it should be setup in _setup_action_points
	assert(not building_data.required_materials.is_empty())
	assert(material_ap == null)
	assert(material_storage == null)

	# Find first (there should only be one) material AP in building data
	var ap_res: ActionPointRes = null
	for ap_res_iter: ActionPointRes in building_data.action_points:
		if ap_res_iter.type == ActionPoint.ApType.CONSTR_MAT_STOCKPILE:
			ap_res = ap_res_iter
			break
	if ap_res == null:
		push_error("Building %s has required materials but no material AP defined in building data!" % self )
		return false

	var pos: Vector2i = grid_pos + ap_res.grid_offset
	var ap: ActionPoint = ActionPoint.setup_bare_ap(pos, ActionPoint.ApType.CONSTR_MAT_STOCKPILE)
	material_storage = StorageComponent.new()
	material_ap = ap
	add_child(material_storage)
	ap.setup_constr_mat_stockpile_ap(material_storage, building_data.required_materials)

	action_points.append(ap)
	Global.level.building_manager.register_action_points(self , [ap])

	# Listen for complete signal
	material_storage.Signal_OnAllItemTypesFull.connect(func() -> void:
		if sm.state == State.WAITING_FOR_MATERIAL and _has_all_construction_materials():
			sm.transition_to(State.IN_CONSTRUCTION)
	)

	return true

	
## Triggered by cell destruction signal
func _check_solid_ground(destroyed_cell: Cell) -> void:
	if sm.state == State.IN_TEARDOWN:
		return

	if not PlacementChecks.has_solid_ground_at(building_data, grid_pos):
		Actions.remove_building(self )


func _has_all_construction_materials() -> bool:
	assert(sm.state == State.WAITING_FOR_MATERIAL)
	assert(material_ap != null)

	# Gather combined materials from all action points
	var combined_materials: ItemTypeList = material_ap.storage_comp.get_curr_item_type_list()
	# for ap in action_points:
	# 	if ap.type == ActionPoint.ApType.CONSTR_MAT_STOCKPILE:
	# 		var items: ItemTypeList = ap.storage_comp.get_curr_item_type_list()
	# 		for item_type in items.get_all_item_types():
	# 			combined_materials.increment(item_type, items.get_item_count(item_type))

	return combined_materials.is_full(building_data.required_materials)


func _flash(color: Color, duration: float) -> void:
	var start_color: Color = internal_modulate
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _set_modulate_internal(color))
	tween.tween_interval(duration)
	tween.tween_callback(func() -> void: _set_modulate_internal(start_color))


func _to_string() -> String:
	var print_color := Colors.to_print_color(dev_color)
	return Util.color_string("%s @%s" % [building_data.ui_name, grid_pos], print_color)


func _set_modulate_internal(color: Color) -> void:
	internal_modulate = color
	self.modulate = internal_modulate * external_modulate

func set_modulate_external(color: Color) -> void:
	external_modulate = color
	self.modulate = internal_modulate * external_modulate
