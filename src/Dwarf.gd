class_name Dwarf
extends GridObject2D

# Scene Components
@onready var light: PointLight2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mining_comp: MiningComponent = $MiningComponent
@onready var construction_comp: ConstructionComponent = $ConstructionComponent
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var carry_comp: CarryComponent = $CarryComponent
@onready var task_queue_comp: TaskQueueComponent = $TaskQueueComponent

# Static ID generator
static var next_dwarf_id: int = 0
var dwarf_id: int
var dwarf_color: Color

# var job_with_path: JobWithPath
var curr_job: Job = null
var curr_path: Path = null

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
	sm = StateMachine.new(self , State, State.IDLE)
	sm.set_state_exitable(State.DYING, false)

	# Configure Components
	movement_comp.set_parent_width(Global.CELL_SIZE * 0.75) # = 96 px for dwarfs

	# ID + Color
	dwarf_id = next_dwarf_id
	next_dwarf_id += 1
	dwarf_color = Colors.get_rand_dwarf_color(dwarf_id)
	self.z_index = Enum.ZIndex.DWARFS

	# Apply Color, 1 = no tint
	animated_sprite.modulate = dwarf_color.lerp(Color.WHITE, 0.6)
	light.color = dwarf_color.lerp(light.color, 0.6)

	# Initial Position
	global_position = Global.level.get_cell(grid_pos).get_floor_point()

	# SIGNALS
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)
	EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)
	EventBus.Signal_DevToogleDwarfDrawInfo.connect(_dev_toogle_dwarf_draw_info)

	mining_comp.Signal_OnMiningCompleted.connect(_on_mining_completed)
	
	construction_comp.Signal_OnConstructionCompleted.connect(_on_construction_completed)

	movement_comp.Signal_MovementDirectionChanged.connect(_on_movement_direction_changed)
	movement_comp.Signal_OnFinishedPath.connect(_on_finished_path)
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)
	# movement_comp.Signal_StateChanged.connect(_on_movement_state_changed)

	# TODO carry_comp signals?


########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################
# ENTER actually enters that state and triggers components
# EXIT stops components but task-finishing logic is handled where exit transition is called (mostly signal handlers).
# Transitions from within _exit functions are NOT ALLOWED
# Transitions from within _enter (as "enter checks") are allowed!

###################################
# IDLE
###################################
func _enter_idle() -> void:
	animated_sprite.play("idle")
	
func _physics_process_idle(delta: float) -> void:
	# Should have no active task because then it would not be idle. But check anyways
	if task_queue_comp.has_current_task():
		print_rich("%s is in IDLE state but has current task %s, not doing anything right now (might stall)." % [ self , task_queue_comp.curr_task])
		print_rich(task_queue_comp)
		return
	
	# Start new task if available
	if not task_queue_comp.is_empty():
		_start_next_task()
		return

	# Otherwise try to find new job
	_find_new_job()

###################################
# MOVING
###################################
func _enter_moving() -> void:
	animated_sprite.play("walk")
	
	# Walking audio is handled by MovementComponent

###################################
# MINING
###################################
func _enter_mining(cell_to_mine: Cell) -> void:
	if cell_to_mine == null:
		print_rich("%s cannot enter mining state with null cell, aborting" % [ self ])
		sm.transition_to(State.IDLE)
		return
	
	if not mining_comp.start_mining(cell_to_mine):
		print_rich("%s failed to start mining %s, aborting" % [ self , cell_to_mine])
		sm.transition_to(State.IDLE)
		return

	# Look at mined cell
	animated_sprite.play("swing_vertical")
	_look_into_dir(cell_to_mine.grid_pos - grid_pos)


func _exit_mining() -> void:
	# Abort mining
	mining_comp.stop_mining_all_cells()


###################################
# BUILDING
###################################
func _enter_building(building: BuildingBase) -> void:
	if building == null:
		print_rich("%s cannot enter building state with null building, aborting" % [ self ])
		sm.transition_to(State.IDLE)
		return

	var cell: Cell = Global.level.get_cell(building.grid_pos)
	var cell_from: Cell = self.curr_cell

	if cell == null or cell_from == null:
		print_rich("%s cannot enter building state with null cells, aborting" % [ self ])
		sm.transition_to(State.IDLE)
		return

	# Check if success -> abort if not
	if not construction_comp.start_building(cell, cell_from, building):
		print_rich("%s failed to start building %s, aborting" % [ self , building])
		sm.transition_to(State.IDLE)
		return

	# Look at cell where building is built
	animated_sprite.play("swing_horizontal")
	_look_into_dir(curr_job.center_cell.grid_pos - grid_pos)

func _exit_building() -> void:
	# Abort building
	construction_comp.stop_building()


###################################
# DYING
###################################
func _enter_dying() -> void:
	animated_sprite.play("die")

	print_rich("%s has died!" % [ self ])
	
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
	if not task_queue_comp.has_current_task():
		print_rich("%s finished path but has no current task, transitioning to IDLE!" % [ self ])
		sm.transition_to(State.IDLE)
		return

	if not task_queue_comp.curr_task.is_move_to_task():
		print_rich("%s finished path but current task is of type %s instead of any MOVE_TO task!" % [ self , Enum.to_str(Task.Type, task_queue_comp.curr_task.type)])
		# TODO handle
		return

	# -> We have a task and it is a move-to task. Verify that we are at the right location
	if not task_queue_comp.curr_task.reached_move_to_position(self ):
		print_rich("%s finished path but has not reached move-to position for task %s, replanning!" % [ self , task_queue_comp.curr_task])
		push_error("TODO REPLAN PATH HERE")
		# TODO
		return

	# Normally this should be the exact type, MOVE_TO has two subtypes
	_finish_task_and_start_next(task_queue_comp.curr_task.type)


## Triggered by MiningComponent for any finished cell (doesnt necessarily means dwarf is no longer mining)
func _on_mining_completed(mined_cell: Cell) -> void:
	# Normal case: Mining was part of job which has already been finished (-> implicitly entered idle)
	if sm.state != State.MINING:
		# Check if we need to finish mining task
		if task_queue_comp.has_current_task() and task_queue_comp.curr_task.type == Task.Type.MINE:
			if task_queue_comp.curr_task.target_grid_pos != mined_cell.grid_pos:
				print_rich("%s completed mining %s but current task %s is for different cell, not finishing task!" % [ self , mined_cell, task_queue_comp.curr_task])
				return

			_finish_task_and_start_next(Task.Type.MINE)
		return

	# Finished mining while in MINING state
	print_rich("%s completed mining %s" % [ self , mined_cell])
	_finish_task_and_start_next(Task.Type.MINE)

	# TODO previously had this, still necessary???
	#Actions.archive_job(job_with_path.job, true)

	
## Triggered by ConstructionComponent
func _on_construction_completed(building: BuildingBase) -> void:
	# Normal case: Building was part of job which has already been finished (-> implicitly entered idle)
	if sm.state != State.BUILDING:
		# Check if we need to finish building task
		if task_queue_comp.has_current_task() and task_queue_comp.curr_task.type == Task.Type.CONSTRUCT:
			if task_queue_comp.curr_task.building != building:
				print_rich("%s completed building %s but current task %s is for different building, not finishing task!" % [ self , building, task_queue_comp.curr_task])
				return

			_finish_task_and_start_next(Task.Type.CONSTRUCT)
		return

	# Finished building while in BUILDING state
	print_rich("%s completed building %s" % [ self , building])
	_finish_task_and_start_next(Task.Type.CONSTRUCT)


## Triggered by MovementComponent
func _on_landed(fall_height_cells: int) -> void:
	# Once cell is normal after mining below -> dont do anything special
	if fall_height_cells > 1:
		print_rich("%s landed after falling %d cells" % [ self , fall_height_cells])
		Audio.play_at_pos_with_pitch("dwarf_on_landing", global_position, 1.4)

	if fall_height_cells > 5:
		sm.transition_to(State.DYING)
		return

	sm.transition_to(State.IDLE)

	# Simulate entering cell anew with idle (to trigger placing torches)
	_on_new_cell_entered(curr_cell)


## Triggered by MovementComponent
func _on_new_cell_entered(new_cell: Cell) -> void:
	_debug_draw_proxy_absolute.queue_redraw()
	
	if new_cell == null:
		return

	# Most actions can only be done when idle or moving
	if sm.state == State.IDLE or sm.state == State.MOVING:
		# Check if should place torch
		if num_torches > 0 and new_cell.deco_elements.is_empty() and Global.level.should_contain_torch(grid_pos):
			print_rich("%s placing torch at %s" % [ self , grid_pos])
			num_torches -= 1
			new_cell.add_deco_element(DecoTorch.instantiate())
			Audio.play_at_pos("item_placing", new_cell.get_floor_point())

		# Check for rubble disposal
		if carry_comp.is_carrying_item_of_type(Enum.CarryableItemType.RUBBLE):
			var rubble_action_points: Array[ActionPoint] = new_cell.get_action_points_of_type(ActionPoint.ActionType.DISPOSE_RUBBLE)
			if not rubble_action_points.is_empty():
				print_rich("%s is disposing rubble at AP %s" % [ self , rubble_action_points[0]])
				carry_comp.drop_all()
				Audio.play_at_pos("dispose_trash", new_cell.get_floor_point())


## Triggered by MovementComponent
func _on_movement_direction_changed(new_dir: Vector2) -> void:
	_look_into_dir(new_dir)


## Triggered by MovementComponent
func _on_started_falling(est_fall_height_cells: int) -> void:
	# Not for normal mining downwards
	if est_fall_height_cells > 1:
		var audio_name: String = "ohoh_%d" % randi_range(1, 3)
		Audio.play_at_pos(audio_name, global_position)

	# Transition to falling state BEFORE stop_working_job_enter_idle
	sm.transition_to(State.FALLING)

	# Basically flush task queue
	_stop_working_job_enter_idle(false)
	

## Triggered by Job when job is not active anymore. This can be because the job was completed or aborted.
# May be called during different states, always enter idle or stay in falling.
func _on_job_archived() -> void:
	if curr_job == null:
		return

	if not curr_job.success:
		print_rich("%s's job %s was aborted (_on_job_archived with success = false)" % [ self , curr_job])

	_stop_working_job_enter_idle()


## Triggered by NavMesh updates (via EventBus)
func _on_nav_updated() -> void:
	# If nav updated while following a path -> recalculate path for job or abort if not valid
	if curr_path != null:
		_validate_current_path()


########################################################################################################################
# OWN (UTILITY) FUNCTIONS
########################################################################################################################
func _stop_working_job_enter_idle(transition_to_idle: bool = true) -> void:
	print_rich("%s _stop_working_job_enter_idle. Flushing task queue and curr_job/path" % [ self ])

	# Flush task queue
	task_queue_comp.flush_all_tasks()

	if curr_path != null:
		if movement_comp.sm.state == MovementComponent.State.FOLLOWING_PATH:
			movement_comp.abort_path()

	if construction_comp.is_currently_building():
		construction_comp.stop_building()
		
	if curr_job != null:
		curr_job.unassign_dwarf(self )

	# Clear curr job + path
	curr_job = null
	curr_path = null

	# Transition back to idle but dont override falling state
	if sm.state != State.FALLING:
		sm.transition_to(State.IDLE)
		# TODO add printing from below?


	# # For printing later
	# var last_job: Job = job_with_path.job
	# # Transition back to idle but dont override falling state
	# if transition_to_idle and sm.state != State.FALLING:
	# 	if last_job.success:
	# 		print_rich("%s finished %s and transitions to IDLE" % [self, last_job])
	# 	else:
	# 		print_rich("%s stops working on %s and transitions to IDLE" % [self, last_job])

	# 	sm.transition_to(State.IDLE)
	# else:
	# 	if last_job.success:
	# 		print_rich("%s finished %s but stays in %s" % [self, last_job, Enum.to_str(State, sm.state)])
	# 	else:
	# 		print_rich("%s stops working on %s but stays in %s" % [self, last_job, Enum.to_str(State, sm.state)])


func _find_new_job() -> void:
	# Try to get a new job	
	var new_job_with_path: JobWithPath = Global.level.job_manager.get_new_job_for_dwarf(self )

	if new_job_with_path == null:
		HexLog.print_throttled(self , "%s found no job, remains idle" % [ self ], NO_JOB_THROTTLED_PRINT_INTERVALL)
		return

	# Try to assign path + job
	curr_job = new_job_with_path.job
	# curr_path = new_job_with_path.path

	curr_job.assign_dwarf(self )

	# Add to task queue
	task_queue_comp.add_job(curr_job)

	_start_next_task()


func _look_into_dir(dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite.flip_h = dir.x < 0
		look_dir = dir.normalized()


func _validate_current_path() -> void:
	print_rich("%s validating current path to job %s NOT IMPLEMENTED DOING NOTHING FOR NOW" % [ self , curr_job])
	# if not job_with_path or not job_with_path.path:
	# 	return

	# job_with_path.path = null
	
	# # Force job to update workable cells first
	# job_with_path.job.update_workable_from_cells()
	# var new_path: Path = Global.level.nav_manager.find_path_to_one_of(grid_pos, job_with_path.job.workable_from_poses)

	# if new_path != null:
	# 	if movement_comp.assign_path(new_path):
	# 		job_with_path.path = new_path
	# 		job_with_path.path.set_debug_draw_color(dwarf_color)
		
	# else:
	# 	print_rich("%s lost path to job at %s" % [self, job_with_path.job.center_cell])
	# 	_stop_working_job_enter_idle()


########################################################################################################################
# TASK QUEUE LOGIC
########################################################################################################################

func _finish_task_and_start_next(expected_curr_task_type: Task.Type) -> void:
	# Finish current task
	task_queue_comp.finish_current_task(expected_curr_task_type)

	# jobs are finished by the job-creator (e.g. building, rubble) directly when appropriate.
	# We dont need to do that here but we may need to add checks for it.

	# If no more tasks -> stop working job and enter idle. IDLE will search for new job.
	if task_queue_comp.is_empty():
		print_rich("%s finished last task and has non remaining, returning to IDLE" % [ self ])
		sm.transition_to(State.IDLE)
		return

	_start_next_task()


# TODO maybe refactor and merge with above?
func _start_next_task() -> void:
	# If no more tasks -> stop working job and enter idle. IDLE will search for new job.
	if task_queue_comp.is_empty():
		print_rich("%s called _start_next_task but has no more tasks to start, returning to IDLE" % [ self ])
		sm.transition_to(State.IDLE)
		return

	# This only sets curr_task to new one.
	if not task_queue_comp.start_next_task():
		print_rich("%s failed to start next task, remaining idle" % [ self ])
		sm.transition_to(State.IDLE)
		return

	# Actually start working on it
	if task_queue_comp.curr_task.is_move_to_task():
		_perform_move_to_task(task_queue_comp.curr_task)
	elif task_queue_comp.curr_task.is_stationary_task():
		_perform_stationary_task(task_queue_comp.curr_task)


# TODO for now we recalculate path every time, later optimize by caching path in task?
func _perform_move_to_task(task: Task) -> void:
	assert(task != null)
	assert(task.is_move_to_task())

	# Find valid target positions
	var target_positions: Array[Vector2i] = []

	if task.type == Task.Type.MOVE_TO_JOB:
		assert(task.job != null)
		task.job.update_workable_from_cells()
		target_positions = task.job.workable_from_poses
	elif task.type == Task.Type.MOVE_TO_CELL:
		target_positions.append(task.target_grid_pos)
	else:
		push_error("%s tried to perform move-to task of invalid type %s" % [ self , Enum.to_str(Task.Type, task.type)])
		return

	# Actual path query
	var path: Path = Global.level.nav_manager.find_path_to_one_of(grid_pos, target_positions)

	if path == null:
		print_rich("%s failed to find path to target positions %s for task %s, abandoning job" % [ self , target_positions, task])
		# TODO
		_stop_working_job_enter_idle()
		return

	# Assign path to movement component
	if not movement_comp.assign_path(path):
		print_rich("%s failed to assign path %s for task %s, abandoning job" % [ self , path, task])
		# TODO
		_stop_working_job_enter_idle()
		return

	# Success
	print_rich("%s started moving to target position %s for task %s" % [ self , path._grid_points.back(), task])
	curr_path = path
	curr_path.set_debug_draw_color(dwarf_color)
	sm.transition_to(State.MOVING)


func _perform_stationary_task(task: Task) -> void:
	assert(task != null)
	assert(task.is_stationary_task())

	# Find valid workable-from-positions
	# TODO For now just use job, later maybe refactor the "update workable from" logic into Task?
	task.created_by_job.update_workable_from_cells()
	var workable_from_poses: Array[Vector2i] = task.created_by_job.workable_from_poses

	# Validate if we can work on the job
	if not (grid_pos in workable_from_poses):
		print_rich("%s tried to work on %s but cannot work from here, aborting task" % [ self , task])
		# TODO
		_stop_working_job_enter_idle()
		return

	# Work depending on task type 

	### MINE TASK ###
	if task.type == Task.Type.MINE:
		var cell: Cell = Global.level.get_cell(task.target_grid_pos)
		print_rich("%s reached %s and starts mining" % [ self , cell])
		sm.transition_to(State.MINING, cell)
		return
	
	### PICKUP TASK ###
	elif task.type == Task.Type.PICKUP:
		print_rich("%s reached %s and starts picking up %s" % [ self , task.target_grid_pos, task.carryable_item.parent])

		# No pickup-state, simply try to pick up item. Success -> goes into idle directly, failure -> abandon job.
		if not carry_comp.pickup_all_in_range([task.carryable_item]):
			print_rich("%s failed to pick up object %s, abandoning task" % [ self , task.carryable_item])
			# TODO
			_stop_working_job_enter_idle()
			return

		print_rich("%s successfully picked up %s, finishing task" % [ self , task.carryable_item.parent])
		_finish_task_and_start_next(Task.Type.PICKUP)
		return

	### CONSTRUCT JOB ###
	elif task.type == Task.Type.CONSTRUCT:
		print_rich("%s reached %s and starts building %s" % [ self , task.target_grid_pos, task.building])
		# enter_building catches errors with building.
		sm.transition_to(State.BUILDING, task.building)
		return

	### ACTION POINT TASK ###
	# elif task.type == Task.Type.ACTION_POINT:
	# 	print_rich("%s reached %s and starts performing action point %s" % [self, task.target_grid_pos, task.action_point])
	# 	# TODO implement action point logic
	# 	push_error("%s tried to perform ACTION_POINT task which is not yet implemented, abandoning task" % [self])
	# 	# TODO
	# 	_stop_working_job_enter_idle()
	# 	return

	### TORCH PLACEMENT TASK ###
	# TODO 

	### UNKNOWN STATIONARY TASK ###
	else:
		push_error("%s tried to perform stationary task of unknown type %s" % [ self , Enum.to_str(Task.Type, task.type)])
		# TODO
		_stop_working_job_enter_idle()
		return

########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy_relative := DebugDrawProxy.new(self )
var _debug_draw_proxy_absolute := DebugDrawProxy.new(self , false)

const debug_state_colors := {
	State.IDLE: Color.WHITE, # White
	State.MOVING: Color(1.0, 1.0, 0.0), # Yellow
	State.MINING: Color(1.0, 0.0, 0.0), # Red
	State.BUILDING: Color(0.0, 1.0, 0.0), # GREEN
	State.FALLING: Color(1.0, 0.0, 1.0), # Magenta
	State.DYING: Color(0.0, 0.0, 0.0), # Black
}

const debug_label_width := 1.0 * Global.CELL_SIZE
const debug_label_offset := Vector2(0.0, -0.8) * Global.CELL_SIZE_VEC + Vector2(-debug_label_width / 2.0, 0.0)
const debug_occupied_cell_alpha := 0.1

var debug_font := ThemeDB.fallback_font
var debug_font_size := 20

# For throttled printing above
static var NO_JOB_THROTTLED_PRINT_INTERVALL := 3.0


func _debug_draw_in_ui_relative(ui_layer: CanvasItem) -> void:
	if not EventBus.dev_draw_dwarf_info:
		return

	# Status Text
	var color_actual: Color = debug_state_colors.get(sm.state, Colors.FALLBACK_COLOR)
	var text: String = Enum.to_str(Dwarf.State, sm.state)

	ui_layer.draw_string(debug_font, debug_label_offset, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, debug_font_size, color_actual)

	# Add movement component state below, smaller
	text = movement_comp.get_state_string()
	var offset_second := debug_label_offset + Vector2(0.0, debug_font_size + 4.0)
	var size_second: int = roundi(debug_font_size * 0.65)
	ui_layer.draw_string(debug_font, offset_second, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, size_second, color_actual)


func _debug_draw_in_ui_absolute(ui_layer: CanvasItem) -> void:
	if not EventBus.dev_draw_dwarf_info:
		return

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


func _dev_toogle_dwarf_draw_info(draw_info: bool) -> void:
	_debug_draw_proxy_absolute.queue_redraw()
	_debug_draw_proxy_relative.queue_redraw()


func _to_string() -> String:
	var print_color := Colors.to_print_color(dwarf_color)
	return Util.color_string("Dwarf-%d (%s @%s)" % [dwarf_id, Enum.to_str(State, sm.state), grid_pos], print_color)
