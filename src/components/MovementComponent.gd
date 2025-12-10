class_name MovementComponent
extends Node2D

################ Signals ################
signal Signal_OnStartedFalling()

# fall_height_cells can be 0 (e.g. after spawning in mid-air in same cell)
signal Signal_OnLanded(fall_height_cells: int)

signal Signal_OnFinishedPath()

signal Signal_MovementDirectionChanged(new_dir: Vector2)

################ Definitions ################
enum State {NOT_MOVING, FOLLOWING_PATH, FALLING, CARRIED}
var sm: StateMachine

################ Configuration ################
var movement_capabilities: MovementCapabilities = MovementCapabilities.new()

################ Current Internal State ################
var path: Path

var curr_falling_speed: float = 0.0

# For tracking fall distance in cells
var fall_start_y: int

@onready var parent: GridObject2D = get_parent()

########################################################################################################################
# PUBLIC
########################################################################################################################
func is_falling() -> bool:
	return sm.state == State.FALLING

func is_being_carried() -> bool:
	return sm.state == State.CARRIED

func assign_path(new_path: Path) -> bool:
	if new_path == null or sm.state == State.FALLING or sm.state == State.CARRIED:
		return false

	# Hide OLD path, even if reference still stored elsewhere
	if path:
		path.debug_draw = false
	
	sm.transition_to(State.FOLLOWING_PATH, new_path)
	return true

func abort_path() -> void:
	# Hide path, even if reference still stored elsewhere
	if path:
		path.debug_draw = false
		
	path = null

	if sm.state == State.FOLLOWING_PATH:
		sm.transition_to(State.NOT_MOVING)


# used by CarryableItemComponent when picked up / dropped
func picked_up() -> void:
	sm.transition_to(State.CARRIED)
func dropped() -> void:
	sm.transition_to(State.NOT_MOVING)

########################################################################################################################
# PRIVATE
########################################################################################################################
func _ready() -> void:
	sm = StateMachine.new(self, State, State.NOT_MOVING)

	assert(parent != null)
	assert(parent is GridObject2D)

func _physics_process(delta: float) -> void:
	sm.physics_process(delta)

########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################
###################################
# Falling
###################################
func _enter_falling() -> void:
	curr_falling_speed = movement_capabilities.falling_starting_speed
	fall_start_y = parent.grid_pos.y
	Signal_OnStartedFalling.emit()

func _exit_falling() -> void:
	# TODO this triggers when beeing grabbed while falling
	var fall_height_cells: int = abs(fall_start_y - parent.grid_pos.y)
	Signal_OnLanded.emit(fall_height_cells)

func _physics_process_falling(delta: float) -> void:
	curr_falling_speed = min(curr_falling_speed + movement_capabilities.falling_acceleration * delta, movement_capabilities.falling_max_speed)
	parent.global_position.y += curr_falling_speed * delta

	# Sample grid pos
	parent.update_grid_pos(parent.sample_grid_pos())

	_update_on_ground_check()

###################################
# Following Path
###################################
func _enter_following_path(new_path: Path) -> void:
	if new_path == null:
		print_rich("MovementComponent from %s: FOLLOWING_PATH but new_path=null!" % [parent])
		sm.transition_to(State.NOT_MOVING)
		return

	path = new_path
	path.debug_draw = true
	path.start_following_from_pos(parent.global_position, true)

func _exit_following_path() -> void:
	if path:
		path.debug_draw = false
	path = null
	
func _physics_process_following_path(delta: float) -> void:
	if _update_on_ground_check():
		return

	# Check if we have a path
	if path == null:
		# This should never happen! Maybe emit signal as error handling, otherwise we get stuck here
		# Signal_OnFinishedPath.emit()
		assert(false)
		print_rich("MovementComponent from %s: FOLLOWING_PATH but path=null!" % [parent])
		sm.transition_to(State.NOT_MOVING)
		return

	# Follow path
	parent.global_position = path.tick_follow_path(delta, movement_capabilities)
	parent.update_grid_pos(path.get_curr_grid_pos())

	# Direction for flipping sprite
	var movement_dir: Vector2 = path.get_next_grid_pos() - parent.grid_pos
	Signal_MovementDirectionChanged.emit(movement_dir)

	# Check if we reached the end of the path
	if path.reached_end():
		Signal_OnFinishedPath.emit()
		sm.transition_to(State.NOT_MOVING)
		
###################################
# Being Carried
###################################
# Nothing, this state basically disables the movement component and hands over movement to the carrier

###################################
# Not Moving
###################################
func _physics_process_not_moving(delta: float) -> void:
	_update_on_ground_check()

########################################################################################################################
# INTERNAL HELPERS
########################################################################################################################
# Check if we should start/stop falling. Returns true if state changed
func _update_on_ground_check() -> bool:
	var can_stand_in_current_cell := parent.curr_cell.is_standable(_get_can_use_ladders())
	var move_mode := _get_curr_move_mode()

	# Currently standing on solid ground or ladder or climbing wall
	if not is_falling():
		if can_stand_in_current_cell or (move_mode != Enum.MoveMode.WALK):
			# Nothing to do            
			return false
		else:
			sm.transition_to(State.FALLING)
			return true

	# Currently falling -> require cell to land on but also position inside of current cell to be on floor
	else:
		var y_cell_floor := parent.curr_cell.get_floor_point().y
		if can_stand_in_current_cell and global_position.y >= y_cell_floor:
			# Snap position to floor
			parent.global_position.y = y_cell_floor
			sm.transition_to(State.NOT_MOVING)
			return true
		else:
			# Still falling
			return false


func _get_curr_move_mode() -> Enum.MoveMode:
	if path:
		return path.get_curr_move_mode()
	else:
		return Enum.MoveMode.WALK

func _get_can_use_ladders() -> bool:
	if is_falling():
		return movement_capabilities.can_use_ladders_when_falling
	else:
		return movement_capabilities.can_use_ladders
