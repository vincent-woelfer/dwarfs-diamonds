class_name Dwarf
extends GridObject2D

# Scene Components
@onready var light: PointLight2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mining_comp: MiningComponent = $MiningComponent
@onready var building_comp: BuildingComponent = $BuildingComponent
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var carry_comp: CarryComponent = $CarryComponent

# Static ID generator
static var next_dwarf_id: int = 0
var dwarf_id: int
var dwarf_color: Color

var job_with_path: JobWithPath

var num_torches: int = 50
var look_dir: Vector2 = Vector2.RIGHT

# State machine
enum State {IDLE, MOVING, MINING, BUILDING, FALLING, DYING}
var sm: StateMachine
func _physics_process(delta: float) -> void:
	sm.physics_process(delta)

########################################################################################################################
# SETUP & OWN PROCESSING
########################################################################################################################
func _ready() -> void:
	sm = StateMachine.new(self, State, State.IDLE)
	sm.set_state_exitable(State.DYING, false)

	# Configure Components
	movement_comp._set_parent_width(Global.CELL_SIZE * 0.75) # = 96 px for dwarfs

	# ID + Color
	dwarf_id = next_dwarf_id
	next_dwarf_id += 1
	dwarf_color = Colors.get_rand_dwarf_color(dwarf_id)
	self.z_index = Enum.ZIndex.DWARFS

	# Apply Color
	animated_sprite.modulate = dwarf_color.lerp(Color.WHITE, 0.3)
	light.color = dwarf_color.lerp(light.color, 0.3)

	# Initial Position
	global_position = Global.level.get_cell(grid_pos).get_floor_point()

	# SIGNALS
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)
	EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)

	mining_comp.Signal_OnMiningCompleted.connect(_on_mining_completed)
	
	building_comp.Signal_OnBuildingCompleted.connect(_on_building_completed)

	movement_comp.Signal_MovementDirectionChanged.connect(_on_movement_direction_changed)
	movement_comp.Signal_OnFinishedPath.connect(_on_finished_path)
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)
	# movement_comp.Signal_StateChanged.connect(_on_movement_state_changed)

	# TODO carry_comp signals?

func _look_into_dir(dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite.flip_h = dir.x < 0
		look_dir = dir.normalized()

########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################
###################################
# IDLE
###################################
func _physics_process_idle(delta: float) -> void:
	_find_new_job()

###################################
# MINING
###################################
func _enter_mining(cell_to_mine: Cell) -> void:
	mining_comp.start_mining(cell_to_mine)

	# Look at mined cell
	_look_into_dir(cell_to_mine.grid_pos - grid_pos)

func _exit_mining() -> void:
	mining_comp.stop_mining_all_cells()


###################################
# BUILDING
###################################
func _enter_building(building: BuildingBase) -> void:
	if building == null:
		push_error("%s cannot enter building state with null building, aborting" % [self])
		sm.transition_to(State.IDLE)
		return

	var cell: Cell = Global.level.get_cell(building.grid_pos)
	var cell_from: Cell = self.curr_cell

	if cell == null or cell_from == null:
		push_error("%s cannot enter building state with null cells, aborting" % [self])
		sm.transition_to(State.IDLE)
		return

	# TODO check if success (implement) -> abort if not
	building_comp.start_building(cell, cell_from, building)

	# Look at cell where building is built
	_look_into_dir(job_with_path.job.center_cell.grid_pos - grid_pos)

func _exit_building() -> void:
	# Abort building
	building_comp.stop_building()


###################################
# DYING
###################################
func _enter_dying() -> void:
	print_rich("%s has died!" % [self])
	
	_stop_working_job_enter_idle()

	# Hide player sprite + light
	animated_sprite.visible = false
	light.enabled = false

	# Play death sound
	Audio.play_at_pos_with_pitch("dwarf_on_landing", global_position, 1.8)

	queue_free()


########################################################################################################################
# SIGNAL HANDLERS
########################################################################################################################
## Triggered by MovementComponent - used for debugging
# func _on_movement_state_changed(prev_state: int, next_state: int) -> void:
	# pass
	# print_rich("%s MovementComponent state changed from %s to %s" % [self,
		# Enum.to_str(MovementComponent.State, prev_state), Enum.to_str(MovementComponent.State, next_state)])


## Triggered by MovementComponent
func _on_finished_path() -> void:
	if job_with_path == null:
		_stop_working_job_enter_idle()
		return

	job_with_path.path = null

	if job_with_path.job == null:
		print_rich("%s finished path but has no job, transitioning to idle" % [self])
		sm.transition_to(State.IDLE)
		return

	_perform_job(job_with_path.job)
	

## Triggered by MovementComponent
func _on_landed(fall_height_cells: int) -> void:
	# Once cell is normal after mining below -> dont do anything special
	if fall_height_cells > 1:
		print_rich("%s landed after falling %d cells" % [self, fall_height_cells])
		Audio.play_at_pos_with_pitch("dwarf_on_landing", global_position, 1.4)

	if fall_height_cells > 5:
		sm.transition_to(State.DYING)
		return

	sm.transition_to(State.IDLE)

	# Simulate entering cell anew with idle (to place torches)
	_on_new_cell_entered(curr_cell)


## Triggered by MovementComponent
func _on_new_cell_entered(new_cell: Cell) -> void:
	_debug_draw_proxy_absolute.queue_redraw()
	
	if new_cell == null:
		return

	# Place Torch but only place if idle or walking
	if sm.state != State.IDLE and sm.state != State.MOVING:
		return

	# Check for torch placement
	if num_torches > 0 and new_cell.deco_elements.is_empty() and Global.level.should_contain_torch(grid_pos):
		print_rich("%s placing torch at %s" % [self, grid_pos])
		num_torches -= 1
		new_cell.add_deco_element(DecoBase.torch_scene.instantiate() as DecoBase)


## Triggered by MovementComponent
func _on_movement_direction_changed(new_dir: Vector2) -> void:
	_look_into_dir(new_dir)


## Triggered by MovementComponent
func _on_started_falling() -> void:
	_stop_working_job_enter_idle(false)
	sm.transition_to(State.FALLING)


## Triggered by MiningComponent
func _on_mining_completed(mined_cell: Cell) -> void:
	# Normal case: Mining was part of job which has already been finished (-> implicitly entered idle)
	if sm.state != State.MINING:
		return

	if job_with_path != null and job_with_path.job != null:
		print_rich("%s completed mining %s" % [self, job_with_path.job])

		# This will set job to null and enter idle -> simply return
		Actions.archive_job(job_with_path.job, true)
		return
		
	else:
		print_rich("%s completed mining cell %s but has no job" % [self, mined_cell])
		# Stay in mining state if still mining, -> idle otherwise
		if not mining_comp.is_currently_mining():
			if sm.state != State.FALLING:
				sm.transition_to(State.IDLE)

	
## Triggered by BuildingComponent
func _on_building_completed(building: BuildingBase) -> void:
	# Normal case: Building was part of job which has already been finished (-> implicitly entered idle)
	if sm.state != State.BUILDING:
		return

	if job_with_path != null and job_with_path.job != null:
		print_rich("%s completed %s and build %s" % [self, job_with_path.job, building])

		# This will set job to null and enter idle -> simply return
		Actions.archive_job(job_with_path.job, true)
		return

	else:
		print_rich("%s completed building %s but has no job" % [self, building])
		# Stay in building state if still building, -> idle otherwise
		if not building_comp.is_currently_building():
			if sm.state != State.FALLING:
				sm.transition_to(State.IDLE)
	

## Triggered by Job when job is not active anymore. This can be because the job was completed or aborted.
# May be called during different states, always enter idle or stay in falling.
func _on_job_archived() -> void:
	if job_with_path == null or job_with_path.job == null:
		return

	if not job_with_path.job.success:
		print_rich("%s's job %s was aborted (_on_job_archived with success = false)" % [self, job_with_path.job])

	_stop_working_job_enter_idle()


## Triggered by NavMesh updates (via EventBus)
func _on_nav_updated() -> void:
	# If nav updated while following a path -> recalculate path for job or abort if not valid
	if job_with_path != null:
		_validate_current_path()


########################################################################################################################
# OWN (UTILITY) FUNCTIONS
########################################################################################################################
func _stop_working_job_enter_idle(transition_to_idle: bool = true) -> void:
	if job_with_path == null:
		if sm.state != State.FALLING:
			sm.transition_to(State.IDLE)
		return

	# For printing later
	var temp_job: Job = job_with_path.job
	
	if job_with_path.path != null:
		if movement_comp.sm.state == MovementComponent.State.FOLLOWING_PATH:
			movement_comp.abort_path()

		# TODO abort building ???? 
		job_with_path.path = null
	if job_with_path.job != null:
		job_with_path.job.unassign_dwarf(self)
	job_with_path = null

	# Transition back to idle but dont override falling state
	if transition_to_idle and sm.state != State.FALLING:
		if temp_job.success:
			print_rich("%s finished %s and transitions to IDLE" % [self, temp_job])
		else:
			print_rich("%s stops working on %s and transitions to IDLE" % [self, temp_job])

		sm.transition_to(State.IDLE)
	else:
		if temp_job.success:
			print_rich("%s finished %s but stays in %s" % [self, temp_job, Enum.to_str(State, sm.state)])
		else:
			print_rich("%s stops working on %s but stays in %s" % [self, temp_job, Enum.to_str(State, sm.state)])


## Called by _on_finished_path when arrived at job location
func _perform_job(job: Job) -> void:
	if job == null:
		print_rich("%s cannot perform null job, transitioning to idle" % [self])
		_stop_working_job_enter_idle()
		return

	# Validate if we can work on the job
	if not (curr_cell.grid_pos in job.workable_from_poses):
		print_rich("%s reached %s but cannot work from here, abandoning job" % [self, job])
		_stop_working_job_enter_idle()
		return

	### MINE JOB ###
	if job.job_type == Job.Type.MINE:
		print_rich("%s reached %s and starts mining" % [self, job.center_cell])
		sm.transition_to(State.MINING, job.center_cell)
		return
	
	### RUBBLE JOB ###
	elif job.job_type == Job.Type.PICKUP:
		print_rich("%s reached %s and starts picking up %s" % [self, job.center_cell, job.carryable_item.parent])
		# No pickup-state, simply try to pick up item. Success -> goes into idle directly, failure -> abandon job.
		if not carry_comp.pickup_all_in_range([job.carryable_item]):
			print_rich("%s failed to pick up object %s, abandoning job" % [self, job.carryable_item])
			_stop_working_job_enter_idle()
		return

	### BUILD JOB ###
	elif job.job_type == Job.Type.BUILD:
		print_rich("%s reached %s and starts building %s" % [self, job.center_cell, job.building])
		# enter_building catches errors with building.
		sm.transition_to(State.BUILDING, job.building)
		return

	### INVALID JOB ###
	else:
		print_rich("%s reached %s but job type %s is unhandled, abandoning job" % [self, job.center_cell, Enum.to_str(Job.Type, job.job_type)])
		_stop_working_job_enter_idle()


func _find_new_job() -> void:
	# Try to get a new job	
	var new_job_with_path: JobWithPath = Global.level.job_manager.get_new_job_for_dwarf(self)

	if new_job_with_path == null:
		HexLog.print_throttled(self, "%s found no job, remains idle" % [self], NO_JOB_THROTTLED_PRINT_INTERVALL)
		return

	var success: bool = false
	if movement_comp.assign_path(new_job_with_path.path):
		if new_job_with_path.job.assign_dwarf(self):
			success = true
			job_with_path = new_job_with_path
			job_with_path.path.set_debug_draw_color(dwarf_color)
		
			sm.transition_to(State.MOVING)
			print_rich("%s started %s" % [self, job_with_path.job])

	if not success:
		# Cleanup on failure
		movement_comp.abort_path()
		print_rich("%s failed to assign job/path to %s, remaining idle" % [self, new_job_with_path.job])


func _validate_current_path() -> void:
	if not job_with_path or not job_with_path.path:
		return

	job_with_path.path = null
	
	# Force job to update workable cells first
	job_with_path.job.update_workable_from_cells()
	var new_path: Path = Global.level.nav_manager.find_path_to_one_of(grid_pos, job_with_path.job.workable_from_poses)

	if new_path != null:
		if movement_comp.assign_path(new_path):
			job_with_path.path = new_path
			job_with_path.path.set_debug_draw_color(dwarf_color)
		
	else:
		print_rich("%s lost path to job at %s" % [self, job_with_path.job.center_cell])
		_stop_working_job_enter_idle()


########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy_relative := DebugDrawProxy.new(self)
var _debug_draw_proxy_absolute := DebugDrawProxy.new(self, false)

const debug_state_colors := {
	State.IDLE: Color.WHITE, # White
	State.MOVING: Color(1.0, 1.0, 0.0), # Yellow
	State.MINING: Color(1.0, 0.0, 0.0), # Red
	State.BUILDING: Color(0.0, 1.0, 0.0), # GREEN
	State.FALLING: Color(1.0, 0.0, 1.0), # Magenta
	State.DYING: Color(0.0, 0.0, 0.0), # Black
}

const debug_label_width := 0.9 * Global.CELL_SIZE
const debug_label_offset := Vector2(0.0, -0.8) * Global.CELL_SIZE_VEC + Vector2(-debug_label_width / 2.0, 0.0)
const debug_occupied_cell_alpha := 0.1

var debug_font := ThemeDB.fallback_font
var debug_font_size := 22

# For throttled printing above
static var NO_JOB_THROTTLED_PRINT_INTERVALL := 3.0


func _debug_draw_in_ui_relative(ui_layer: CanvasItem) -> void:
	# Status Text
	var color_actual: Color = debug_state_colors.get(sm.state, Colors.FALLBACK_COLOR)
	var text: String = Enum.to_str(Dwarf.State, sm.state)

	ui_layer.draw_string(debug_font, debug_label_offset, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, debug_font_size, color_actual)

	# Add movement component state below, smaller
	text = movement_comp.get_state_string()
	var offset_second := debug_label_offset + Vector2(0.0, debug_font_size + 4.0)
	var size_second: int = roundi(debug_font_size * 0.7)
	ui_layer.draw_string(debug_font, offset_second, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, size_second, color_actual)


func _debug_draw_in_ui_absolute(ui_layer: CanvasItem) -> void:
	# Draw Occupied Cell
	var cell_to_draw: Cell = curr_cell

	if cell_to_draw != null:
		var offset: Vector2 = cell_to_draw.global_position
		var cell_poly_points := cell_to_draw.visual.poly_points.duplicate()
		for i in range(cell_poly_points.size()):
			cell_poly_points[i] += offset

		ui_layer.draw_colored_polygon(cell_poly_points, Colors.with_alpha(dwarf_color, debug_occupied_cell_alpha))


func _dev_toogle_light(is_light_on: bool) -> void:
	light.enabled = is_light_on


func _to_string() -> String:
	var print_color := Colors.to_print_color(dwarf_color)
	return Util.color_string("Dwarf-%d (%s @%s)" % [dwarf_id, Enum.to_str(State, sm.state), grid_pos], print_color)
