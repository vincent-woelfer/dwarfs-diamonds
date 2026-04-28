class_name Dwarf
extends GridObject2D

# Scene Components
@onready var light: PointLight2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mining_comp: MiningComponent = $MiningComponent
@onready var construction_comp: ConstructionComponent = $ConstructionComponent
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var carry_comp: CarryComponent = $CarryComponent
@onready var task_queue: TaskQueueComponent = $TaskQueueComponent
@onready var action_point_comp: ActionPointComponent = $ActionPointComponent

# Static ID generator
static var next_dwarf_id: int = 0
var dwarf_id: int
var dwarf_color: Color

# var job_with_path: JobWithPath
var curr_job: Job = null
var curr_path: Path = null
var applied_for_job: bool = false

var num_torches: int = 50
var look_dir: Vector2 = Vector2.RIGHT

var est_fall_height_cells: int = 0
var est_landing_cell: Cell = null

# State machine
enum State {IDLE, MOVING, MINING, BUILDING, FALLING, DYING, ACTION}
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
	global_position = Global.level.get_cell(grid_pos).get_center_floor_point()

	# Dev Signals
	EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)
	EventBus.Signal_DevToogleDwarfDrawInfo.connect(_dev_toogle_dwarf_draw_info)
	_dev_toogle_light()
	_dev_toogle_dwarf_draw_info()

	# SIGNALS
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)

	mining_comp.Signal_OnMiningCompleted.connect(_on_mining_completed)
	
	construction_comp.Signal_OnConstructionCompleted.connect(_on_construction_completed)

	movement_comp.Signal_MovementDirectionChanged.connect(_on_movement_direction_changed)
	movement_comp.Signal_OnFinishedPath.connect(_on_finished_path)
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)
	# movement_comp.Signal_StateChanged.connect(_on_movement_state_changed)

	action_point_comp.Signal_OnActionCompleted.connect(_on_action_completed)


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
	if task_queue.has_current_task():
		push_warning()
		print_rich("%s is in IDLE state but has current task %s, not doing anything right now (might stall)." % [ self , task_queue.curr_task])
		print_rich(task_queue)
		return
	
	# Start new task if available
	if not task_queue.is_empty():
		_start_next_task()
		return
	
	# Otherwise try to find new job
	_apply_for_job()
		

###################################
# MOVING
###################################
func _enter_moving() -> void:
	animated_sprite.play("walk")

func _exit_moving() -> void:
	# Stop movement
	if movement_comp.sm.state == MovementComponent.State.FOLLOWING_PATH:
		movement_comp.abort_path()

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
func _enter_building(building: Building) -> void:
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
	_look_into_dir(building.grid_pos - grid_pos)

func _exit_building() -> void:
	# Abort building
	construction_comp.stop_building()


###################################
# ACTION
###################################
func _enter_action(action_point: ActionPoint) -> void:
	if action_point == null:
		print_rich("%s cannot enter interacting state with null action point, aborting" % [ self ])
		sm.transition_to(State.IDLE)
		return

	if not action_point_comp.start_action(action_point):
		print_rich("%s failed to start action for action point %s, aborting" % [ self , action_point])
		sm.transition_to(State.IDLE)
		return

	# Look at action point
	animated_sprite.play("interact")
	_look_into_dir(action_point.grid_pos - grid_pos)


func _exit_action() -> void:
	action_point_comp.stop_interacting()

###################################
# FALLING
###################################
func _enter_falling() -> void:
	animated_sprite.play("fall")

	# Log
	print_rich("%s started falling for %d cells" % [ self , est_fall_height_cells])

	# Audio only for actually falling multiple cells
	if est_fall_height_cells > 1:
		var audio_name: String = "ohoh_%d" % randi_range(1, 3)
		Audio.play_at_pos(audio_name, global_position)

	_abort_tasks_enter_idle()
	

###################################
# DYING
###################################
func _enter_dying() -> void:
	animated_sprite.play("die")

	print_rich("%s has died!" % [ self ])

	carry_comp.drop_all()
	
	_abort_tasks_enter_idle()

	# Play death sound
	Audio.play_at_pos_with_pitch("dwarf_on_landing", global_position, 1.8)

	Global.level.remove_dwarf(self )

	# Hide player sprite + light
	# animated_sprite.visible = false
	# light.enabled = false

	# Wait for animation to finish and then delete self
	await animated_sprite.animation_finished
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
	# General catch-all print
	if !task_queue.has_current_task() or !task_queue.curr_task.is_move_to_task():
		print_rich("%s finished path but doesnt match current task %s, ignoring!" % [ self , task_queue.curr_task])
		return

	# If still not at move-to position -> replan
	if not task_queue.curr_task.reached_move_to_position(self ):
		print_rich("%s finished path from task %s but has not reached move-to position, replanning!" % [ self , task_queue.curr_task])
		_perform_move_to_task(task_queue.curr_task)
		return

	# Normally this should be the exact type, MOVE_TO has two subtypes
	assert(task_queue.curr_task.type in [Task.Type.MOVE_TO_JOB, Task.Type.MOVE_TO_CELL])
	_finish_task_and_start_next(task_queue.curr_task.type)


## Triggered by MiningComponent for any finished cell (doesnt necessarily means dwarf is no longer mining)
func _on_mining_completed(mined_cell: Cell) -> void:
	# General catch-all print
	if !task_queue.has_current_task() or task_queue.curr_task.type != Task.Type.MINE or task_queue.curr_task.target_grid_pos != mined_cell.grid_pos:
		print_rich("%s completed mining %s but doesnt match current task %s, ignoring!" % [ self , mined_cell, task_queue.curr_task])
		return

	print_rich("%s completed mining %s" % [ self , mined_cell])
	if task_queue.curr_task.finishes_job:
		Actions.archive_job(task_queue.curr_task.created_by_job, true)
	_finish_task_and_start_next(Task.Type.MINE)

	
## Triggered by ConstructionComponent
func _on_construction_completed(building: Building) -> void:
	# For buildings this is the normal case since this callback is triggered AFTER the building has completed itself and finished the task.
	if !task_queue.has_current_task() or task_queue.curr_task.type != Task.Type.CONSTRUCT or task_queue.curr_task.building != building:
		print_rich("%s completed construction of %s but doesnt match current task %s, ignoring!" % [ self , building, task_queue.curr_task])
		return

	# Finished building while in BUILDING state
	print_rich("%s completed construction of %s" % [ self , building])
	# Job is archived by building itself
	_finish_task_and_start_next(Task.Type.CONSTRUCT)


## Triggered by ActionPointComponent
func _on_action_completed(action_point: ActionPoint) -> void:
	# For action points this is the normal case since this callback is triggered AFTER the action point has completed itself and finished the task.
	if !task_queue.has_current_task() or task_queue.curr_task.type != Task.Type.ACTION_POINT or task_queue.curr_task.action_point != action_point:
		print_rich("%s completed action for %s but doesnt match current task %s, ignoring!" % [ self , action_point, task_queue.curr_task])
		return

	print_rich("%s completed action for %s" % [ self , action_point])
	_finish_task_and_start_next(Task.Type.ACTION_POINT)


## Triggered by MovementComponent
func _on_new_cell_entered(new_cell: Cell) -> void:
	_debug_draw_proxy_absolute.queue_redraw()
	
	if new_cell == null:
		return

	# Most actions can only be done when idle or moving
	if sm.state == State.IDLE or sm.state == State.MOVING:
		# Check if should place torch
		if num_torches > 0 and new_cell.deco_elements.is_empty() and Global.level.should_contain_torch(grid_pos):
			_place_torch(new_cell)


## Triggered by MovementComponent
func _on_movement_direction_changed(new_dir: Vector2) -> void:
	_look_into_dir(new_dir)


## Triggered by MovementComponent
func _on_started_falling(est_fall_height_cells_: int) -> void:
	self.est_fall_height_cells = est_fall_height_cells_
	self.est_landing_cell = Global.level.get_cell(grid_pos + Vector2i(0, est_fall_height_cells_))

	# Transition to falling state BEFORE _abort_tasks_enter_idle (for cleaner log order)
	sm.transition_to(State.FALLING)


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

	# Instantly apply for new job
	_apply_for_job()
	

## Triggered by Job when job is not active anymore. This can be because the job was completed or aborted.
# May be called during different states, always enter idle or stay in falling.
func _on_job_archived() -> void:
	if curr_job == null:
		return

	if not curr_job.success:
		print_rich("%s's job %s was aborted (_on_job_archived with success = false)" % [ self , curr_job])

	_abort_tasks_enter_idle()


func _on_job_assigned(new_job: Job) -> void:
	if not applied_for_job:
		print_rich("%s was assigned a job %s without applying for it, ignoring!" % [ self , new_job])
		return
	applied_for_job = false

	# If still falling -> simply ignore
	if sm.state == State.FALLING:
		return

	if new_job == null:
		# HexLog.throttled(self , "%s found no job, remains idle / creating own tasks!" % [ self ], HexLog.NO_JOB_INTERVALL)
		# Check for tasks coming from own "needs"
		_create_own_tasks()
		return

	# Assign job
	curr_job = new_job
	curr_job.assign_dwarf(self )

	# Add to task queue and start right away
	task_queue.add_job(curr_job)
	_start_next_task()


## Triggered by NavMesh updates (via EventBus)
func _on_nav_updated() -> void:
	# If nav updated while following a path -> recalculate path for job or abort if not valid
	if curr_path != null:
		_validate_current_path()


########################################################################################################################
# OWN (UTILITY) FUNCTIONS
########################################################################################################################
func _apply_for_job() -> void:
	if applied_for_job:
		return

	applied_for_job = Global.level.job_manager.apply_for_new_job(self )

	if not applied_for_job and sm.state == State.IDLE:
		# Failed to apply, own tasks as fallback
		_create_own_tasks()


func _abort_tasks_enter_idle() -> void:
	# Store for printing
	var last_job := curr_job
	var last_task := task_queue.curr_task

	# Flush task queue
	task_queue.flush_all_tasks()
		
	# If assigned to job -> unassign
	if curr_job != null:
		curr_job.unassign_dwarf(self )

	# Clear curr job + path
	curr_job = null
	if curr_path: curr_path.delete()
	curr_path = null

	# Determine if we can transition to idle
	var transition_to_idle := sm.state != State.FALLING and sm.state != State.DYING
	var transition_string: String = "transitions to IDLE" if transition_to_idle else "remains in current state %s" % Enum.to_str(State, sm.state)
	
	# Print
	if last_job != null:
		if last_job.success:
			print_rich("%s finished working on %s / %s and %s" % [ self , last_job, last_task, transition_string])
		else:
			print_rich("%s aborted working on %s / %s and %s" % [ self , last_job, last_task, transition_string])
	elif last_task != null:
		print_rich("%s aborted current task %s and %s" % [ self , last_task, transition_string])
	else:
		print_rich("%s has no job or task to abort, %s" % [ self , transition_string])

	# Transition back to idle but dont override falling/dying state
	if transition_to_idle:
		sm.transition_to(State.IDLE)


func _create_own_tasks() -> void:
	var tasks: Array[Task] = []

	# Dispose Gemstone
	if carry_comp.is_carrying_item_of_type(Enum.ItemType.GEMSTONE):
		_create_action_point_tasks_for_type(ActionPoint.ActionType.DROPOFF_GEMSTONE)

	# Dispose Rubble
	elif carry_comp.is_carrying_item_of_type(Enum.ItemType.RUBBLE):
		_create_action_point_tasks_for_type(ActionPoint.ActionType.DROPOFF_RUBBLE)


func _create_action_point_tasks_for_type(ap_type: ActionPoint.ActionType) -> void:
	var aps: Array[ActionPoint] = Global.level.building_manager.get_all_action_points(ap_type)

	if aps.is_empty():
		# HexLog.throttled(self , "%s found no AP of type %s, not creating action point task" % [ self , Enum.to_str(ActionPoint.ActionType, ap_type)], HexLog.AP_MISSING_INTERVALL)
		return

	var target_positions: Array[Vector2i] = []
	for ap in aps:
		target_positions.append(ap.grid_pos)

	var path: Path = Global.level.nav_manager.find_path_to_one_of(curr_cell.grid_pos, target_positions, movement_comp.movement_stats)
	if not path:
		HexLog.throttled(self , "%s failed to find path to target positions %s for AP type %s" % [ self , target_positions, Enum.to_str(ActionPoint.ActionType, ap_type)], HexLog.NO_PATH_AP_INTERVALL)
		return

	# Back-reference path to AP
	var target_ap: ActionPoint = null
	for ap in aps:
		if ap.grid_pos == path._grid_points.back():
			target_ap = ap
			break

	# Actually create tasks
	var tasks: Array[Task] = []
	tasks.append(Task.create_move_to_cell_task(target_ap.grid_pos))
	tasks.append(Task.create_action_point_task(target_ap.grid_pos, target_ap))
	task_queue.add_tasks(tasks)

	
func _look_into_dir(dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite.flip_h = dir.x < 0
		look_dir = dir.normalized()


## Called when nav is updated while dwarf is following a path
func _validate_current_path() -> void:
	if curr_path != null and task_queue.has_current_task() and task_queue.curr_task.is_move_to_task():
		# print_rich("%s validating/updating current path to task %s" % [ self , task_queue.curr_task])

		# Just start movement task again for now
		_perform_move_to_task(task_queue.curr_task)


func _place_torch(cell: Cell) -> bool:
	assert(cell != null)

	if num_torches <= 0 or not cell.deco_elements.is_empty():
		return false

	# print_rich("%s placing torch at %s" % [ self , grid_pos])
	num_torches -= 1
	cell.add_deco_element(DecoTorch.instantiate())
	Audio.play_at_pos("item_placing", cell.get_center_floor_point())
	return true


########################################################################################################################
# TASK QUEUE LOGIC
########################################################################################################################
func _finish_task_and_start_next(expected_curr_task_type: Task.Type) -> void:
	# Finish current task
	task_queue.finish_current_task(expected_curr_task_type)

	# jobs are finished by the job-creator (e.g. building, rubble) directly when appropriate.
	# We dont need to do that here but we may need to add checks for it.
	# For now still do this here as "backup"
	if task_queue.has_current_task() and task_queue.curr_task.finishes_job:
		print_rich("%s finished job %s by finishing task %s" % [ self , task_queue.curr_task.created_by_job, task_queue.curr_task])
		Actions.archive_job(task_queue.curr_task.created_by_job, true)

	# If no more tasks -> stop working job and enter idle. IDLE will search for new job.
	if task_queue.is_empty():
		print_rich("%s finished last task and has non remaining, returning to IDLE" % [ self ])
		sm.transition_to(State.IDLE)
	else:
		_start_next_task()


func _start_next_task() -> void:
	# If no more tasks -> stop working job and enter idle. IDLE will search for new job.
	if task_queue.is_empty():
		print_rich("%s called _start_next_task but has no more tasks to start, returning to IDLE" % [ self ])
		sm.transition_to(State.IDLE)
		return

	# This only sets curr_task to new one.
	if not task_queue.start_next_task():
		print_rich("%s failed to start next task, remaining idle" % [ self ])
		sm.transition_to(State.IDLE)
		return

	# Actually start working on it
	if task_queue.curr_task.is_move_to_task():
		_perform_move_to_task(task_queue.curr_task)
	elif task_queue.curr_task.is_stationary_task():
		_perform_stationary_task(task_queue.curr_task)


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
	var new_path: Path = Global.level.nav_manager.find_path_to_one_of(grid_pos, target_positions, movement_comp.movement_stats)
	if new_path == null:
		print_rich("%s failed to find path to target positions %s for task %s, abandoning job" % [ self , target_positions, task])
		_abort_tasks_enter_idle()
		return

	# Assign path to movement component
	if not movement_comp.assign_path(new_path):
		print_rich("%s failed to assign path %s for task %s, abandoning job" % [ self , new_path, task])
		_abort_tasks_enter_idle()
		return

	# Success
	print_rich("%s started moving to target position %s for task %s" % [ self , new_path._grid_points.back(), task])
	if curr_path:
		curr_path.delete()
	curr_path = new_path
	curr_path.set_debug_draw_color(dwarf_color)

	sm.transition_to(State.MOVING)


func _perform_stationary_task(task: Task) -> void:
	assert(task != null)
	assert(task.is_stationary_task())

	# Find valid workable-from-positions - depends on if job is present or not
	var workable_from_poses: Array[Vector2i]

	if task.created_by_job:
		task.created_by_job.update_workable_from_cells()
		workable_from_poses = task.created_by_job.workable_from_poses
	else:
		workable_from_poses = [task.target_grid_pos]

	# Validate if we can work on the job
	if not (grid_pos in workable_from_poses):
		print_rich("%s tried to work on %s but cannot work from here, aborting task" % [ self , task])
		_abort_tasks_enter_idle()
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
		print_rich("%s reached %s and starts picking up %s" % [ self , task.target_grid_pos, task.carryable_item])

		# No pickup-state, simply try to pick up item. Success -> goes into idle directly, failure -> abandon job.
		if not carry_comp.pickup_all_in_range([task.carryable_item]):
			print_rich("%s failed to pick up object %s, abandoning task" % [ self , task.carryable_item])
			_abort_tasks_enter_idle()
			return

		print_rich("%s successfully picked up %s, finishing task" % [ self , task.carryable_item])
		_finish_task_and_start_next(Task.Type.PICKUP)
		return

	### CONSTRUCT JOB ###
	elif task.type == Task.Type.CONSTRUCT:
		print_rich("%s reached %s and starts building %s" % [ self , task.target_grid_pos, task.building])
		# enter_building catches errors with building.
		sm.transition_to(State.BUILDING, task.building)
		return

	### TORCH PLACEMENT TASK ###
	elif task.type == Task.Type.PLACE_TORCH:
		var cell: Cell = Global.level.get_cell(task.target_grid_pos)

		if _place_torch(cell):
			_finish_task_and_start_next(Task.Type.PLACE_TORCH)
			return
		else:
			print_rich("%s failed to place torch at %s, abandoning task" % [ self , cell])
			_abort_tasks_enter_idle()
			return

	### ACTION POINT TASK ###
	elif task.type == Task.Type.ACTION_POINT:
		print_rich("%s reached %s and starts performing action for point %s" % [ self , task.target_grid_pos, task.action_point])
		# enter_interacting catches errors with action point.
		sm.transition_to(State.ACTION, task.action_point)
		return


	### UNKNOWN STATIONARY TASK ###
	else:
		push_error("%s tried to perform stationary task of unknown type %s" % [ self , Enum.to_str(Task.Type, task.type)])
		_abort_tasks_enter_idle()
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
	State.ACTION: Color(0.2, 0.2, 1.0), # Blue
}

const debug_label_width := 1.0 * Global.CELL_SIZE
const debug_label_offset := Vector2(0.0, -0.8) * Global.CELL_SIZE_VEC + Vector2(-debug_label_width / 2.0, 0.0)
const debug_occupied_cell_alpha := 0.1

var debug_font := ThemeDB.fallback_font
var debug_font_size := 20


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


func _dev_toogle_light() -> void:
	light.enabled = EventBus.dev_light_on


func _dev_toogle_dwarf_draw_info() -> void:
	_debug_draw_proxy_absolute.queue_redraw()
	_debug_draw_proxy_relative.queue_redraw()

	if curr_path != null:
		curr_path.set_debug_draw_enabled(EventBus.dev_draw_dwarf_info)


func _to_string() -> String:
	var print_color := Colors.to_print_color(dwarf_color)
	return Util.color_string("Dwarf-%d (%s @%s)" % [dwarf_id, Enum.to_str(State, sm.state), grid_pos], print_color)
