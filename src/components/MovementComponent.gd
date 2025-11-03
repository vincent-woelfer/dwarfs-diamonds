class_name MovementComponent
extends Node2D

################ Signals ################
signal Signal_OnStartedFalling()
signal Signal_OnLanded(fall_height_cells: int)

signal Signal_OnFinishedPath()

signal Signal_MovementDirectionChanged(new_dir: Vector2)

################ Definitions ################
enum State {NOT_MOVING, FOLLOWING_PATH, FALLING}
var sm: StateMachine

################ Configuration ################
var movement_capabilities: MovementCapabilities = MovementCapabilities.new()

const falling_acceleration: float = 600.0 # pixels per second squared
const max_falling_speed: float = 2000.0 # pixels per second
const starting_speed: float = 200.0 # pixels per second

const movement_speed = 250.0 # pixels per second

################ Current Internal State ################
var path: Path

var curr_speed: float = 0.0
var curr_falling_speed: float = 0.0

# For tracking fall distance in cells
var fall_start_y: int

@onready var parent: GridObject2D = get_parent()

########################################################################################################################
# PUBLIC
########################################################################################################################
func is_falling() -> bool:
	return sm.state == State.FALLING

func assign_path(new_path: Path) -> bool:
	if new_path == null or sm.state == State.FALLING:
		return false

	# Hide path, even if reference still stored elsewhere
	if path:
		path.debug_draw = false

	path = new_path
	path.start_following_from_pos(parent.global_position, true)
	sm.transition_to(State.FOLLOWING_PATH)
	return true

func abort_path() -> void:
	# Hide path, even if reference still stored elsewhere
	if path:
		path.debug_draw = false
		
	path = null

	if sm.state == State.FOLLOWING_PATH:
		sm.transition_to(State.NOT_MOVING)

########################################################################################################################
# PRIVATE
########################################################################################################################

func _ready() -> void:
	sm = StateMachine.new(self, State, State.NOT_MOVING)


func _physics_process(delta: float) -> void:
	# Do this in all states
	_update_on_ground_check()

	sm.physics_process(delta)


func _physics_process_falling(delta: float) -> void:
	curr_falling_speed = min(curr_falling_speed + falling_acceleration * delta, max_falling_speed)
	parent.global_position.y += curr_falling_speed * delta

	# Sample grid pos
	parent.update_grid_pos(parent.sample_grid_pos())


func _physics_process_following_path(delta: float) -> void:
	# Check if we have a path
	if path == null:
		sm.transition_to(State.NOT_MOVING)
		return

	# Check which speed to use
	curr_speed = movement_speed

	# Follow path
	parent.global_position = path.follow_path(curr_speed * delta)
	parent.update_grid_pos(path.get_curr_grid_pos())

	# Direction for flipping sprite
	var movement_dir: Vector2 = path.get_next_grid_pos() - parent.grid_pos
	Signal_MovementDirectionChanged.emit(movement_dir)

	# Check if we reached the end of the path
	if path.reached_end():
		Signal_OnFinishedPath.emit()
		sm.transition_to(State.NOT_MOVING)
		

# Check if we should start/stop falling
func _update_on_ground_check() -> void:
	var can_stand_in_current_cell := parent.curr_cell.is_standable(_get_can_use_ladders())

	# TODO this is dirty. To avoid stating to fall when "climbing" a diagonal connection wall we just check
	# if we are horizontally centered in the cell.
	var horizontally_centered: bool = abs(parent.global_position.x - parent.curr_cell.get_floor_point().x) <= Global.CELL_SIZE * 0.1

	# Currently standing on solid ground or ladder
	if not is_falling():
		if can_stand_in_current_cell or not horizontally_centered: # TODO hacky
			# Nothing to do            
			return
		else:
			sm.transition_to(State.FALLING)
			return

	# Currently falling -> require cell to land on but also position inside of current cell to be on floor
	else:
		var y_cell_floor := parent.curr_cell.get_floor_point().y
		if can_stand_in_current_cell and global_position.y >= y_cell_floor:
			# Snap position to floor
			parent.global_position.y = y_cell_floor
			sm.transition_to(State.NOT_MOVING)
			return
		else:
			# Still falling
			return


func _enter_falling() -> void:
	curr_falling_speed = starting_speed
	fall_start_y = parent.grid_pos.y
	Signal_OnStartedFalling.emit()


func _exit_falling() -> void:
	var fall_height_cells: int = abs(fall_start_y - parent.grid_pos.y)
	Signal_OnLanded.emit(fall_height_cells)


func _enter_not_moving() -> void:
	# Stopped moving
	if path:
		path.debug_draw = false
	path = null


func _get_can_use_ladders() -> bool:
	if is_falling():
		return movement_capabilities.can_use_ladders_when_falling
	else:
		return movement_capabilities.can_use_ladders
