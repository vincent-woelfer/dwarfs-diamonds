class_name MovementComponent
extends Node2D

################ Signals ################
# if mining cell below (and the one below that is solid) => fall_height = 1
signal Signal_OnStartedFalling(est_fall_height_cells: int)

# fall_height_cells can be 0 (e.g. after spawning in mid-air in same cell)
signal Signal_OnLanded(fall_height_cells: int)

signal Signal_OnFinishedPath()

# For flipping sprite based on movement direction
signal Signal_MovementDirectionChanged(new_dir: Vector2)

################ Definitions ################
enum State {NOT_MOVING, FOLLOWING_PATH, FALLING, CARRIED}
var sm: StateMachine

################ Configuration ################
var movement_stats: MovementStats = MovementStats.new()

# Width of the parent GridObject2D for path following (e.g. climbing walls)
var parent_width: float = Global.CELL_SIZE * 0.3

# Ground Checks with downward "ray casts". One must be on ground to consider standing. 
var ground_check_sample_points: Array[float] = []

@onready var parent: GridObject2D = get_parent()

################ Current Internal State ################
var path: Path

var curr_falling_speed: float = 0.0

# For tracking fall distance in cells
var fall_start_y: int

# Reference to the used audio player
var _audio_player: AudioStreamPlayer2D = null

########################################################################################################################
# PUBLIC
########################################################################################################################
func is_falling() -> bool:
	return sm.state == State.FALLING

func is_being_carried() -> bool:
	return sm.state == State.CARRIED

func get_state_string() -> String:
	return Enum.to_str(MovementComponent.State, sm.state)

func assign_path(new_path: Path) -> bool:
	if new_path == null or sm.state == State.FALLING or sm.state == State.CARRIED:
		return false

	# Hide old path
	if path: path.delete()
	
	sm.transition_to(State.FOLLOWING_PATH, new_path)
	return true

func abort_path() -> void:
	# Hide old path
	if path: path.delete()
	path = null

	if sm.state == State.FOLLOWING_PATH:
		sm.transition_to(State.NOT_MOVING)


# used by CarryableItemComponent when picked up / dropped
func picked_up() -> void:
	sm.transition_to(State.CARRIED)
func dropped() -> void:
	sm.transition_to(State.NOT_MOVING)


func set_parent_width(new_parent_width: float) -> void:
	parent_width = new_parent_width

	ground_check_sample_points = [
		- parent_width / 2.0,
		0.0,
		 parent_width / 2.0,
	]


########################################################################################################################
# PRIVATE
########################################################################################################################
func _ready() -> void:
	sm = StateMachine.new(self , State, State.NOT_MOVING)

	assert(parent != null)
	assert(parent is GridObject2D)

	# Initialize ground check sample points
	set_parent_width(parent_width)
	

func _physics_process(delta: float) -> void:
	sm.physics_process(delta)

	# For debugging:
	# print_rich("MovementComponent of %s in state %s at pos %s" % [parent, Enum.to_str(State, sm.state), parent.grid_pos])

########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################
###################################
# Falling
###################################
func _enter_falling() -> void:
	curr_falling_speed = movement_stats.falling_starting_speed
	fall_start_y = parent.grid_pos.y

	# Estimate fall height in cells
	var curr_y := fall_start_y
	while true:
		curr_y += 1
		var cell_below: Cell = Global.level.get_cell(Vector2i(parent.grid_pos.x, curr_y))
		if cell_below == null:
			break

		# Check if can stand here
		if cell_below.is_standable(_get_can_use_ladders()):
			break
			

	var est_fall_height_cells: int = abs(curr_y - fall_start_y)
	Signal_OnStartedFalling.emit(est_fall_height_cells)


func _exit_falling() -> void:
	# TODO this also triggers when beeing grabbed while falling, maybe differentiate?
	var fall_height_cells: int = abs(fall_start_y - parent.grid_pos.y)
	Signal_OnLanded.emit(fall_height_cells)


func _physics_process_falling(delta: float) -> void:
	curr_falling_speed = min(curr_falling_speed + movement_stats.falling_acceleration * delta, movement_stats.falling_max_speed)
	parent.global_position.y += curr_falling_speed * delta

	# Sample grid pos
	parent.update_grid_pos(parent.sample_grid_pos())

	_update_on_ground_check()

###################################
# Following Path
###################################
func _enter_following_path(new_path: Path) -> void:
	if new_path == null:
		sm.transition_to(State.NOT_MOVING)
		return

	path = new_path
	path.start_following_from_pos(parent.global_position, parent_width, true)

	# Start audio
	if _audio_player == null:
		_audio_player = Audio.play_at_pos("dwarf_walk_1_looped", parent.global_position)

func _exit_following_path() -> void:
	if path: path.delete()
	path = null

	# Stop audio
	if _audio_player != null:
		Audio.stop_player(_audio_player)
		_audio_player = null
	
	
func _physics_process_following_path(delta: float) -> void:
	if _update_on_ground_check():
		return

	# Check if we have a path
	if path == null:
		# This should never happen! Maybe emit signal as error handling, otherwise we get stuck here
		assert(false)
		print_rich("MovementComponent from %s: FOLLOWING_PATH but path=null!" % [parent])
		Signal_OnFinishedPath.emit()
		sm.transition_to(State.NOT_MOVING)
		return

	# Follow path and update position
	parent.global_position = path.tick_follow_path(delta, movement_stats)
	parent.update_grid_pos(path.get_curr_grid_pos())

	# Direction for flipping sprite
	var movement_dir: Vector2 = path.get_next_grid_pos() - parent.grid_pos
	Signal_MovementDirectionChanged.emit(movement_dir)

	# Update audio player position
	Audio.update_player_position(_audio_player, parent.global_position)

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

## Check if we should start/stop falling. Returns true if state changed.
## Called in physics process of states: FALLING, NOT_MOVING, FOLLOWING_PATH
func _update_on_ground_check() -> bool:
	# Check if the current cell allows standing here (e.g. has a floor or ladder)
	var can_stand_in_current_cell := parent.curr_cell.is_standable(_get_can_use_ladders())

	# Check if climbing (ladders or climbing walls, determined by movement mode)
	var is_climbing := _is_climbing()
	var is_on_floor := _is_on_floor_downward_ray_cast_check()

	# Floor y
	var y_cell_floor := parent.curr_cell.get_floor_point_at_world_x(parent.global_position.x).y

	# Currently standing on solid ground or ladder or climbing wall
	if not is_falling():
		if (can_stand_in_current_cell and is_on_floor) or is_climbing:
			# Nothing to do            
			return false
		else:
			sm.transition_to(State.FALLING)
			return true

	# Currently falling -> require cell to land on but also position inside of current cell to be on floor
	else:
		if can_stand_in_current_cell and is_on_floor:
			# Snap position to floor
			parent.global_position.y = y_cell_floor
			sm.transition_to(State.NOT_MOVING)
			return true
		else:
			# Still falling
			return false


## Downward "ray cast" for every point in check ground_check_sample_points to see if on floor
## Returns true if at least one point is on floor
func _is_on_floor_downward_ray_cast_check() -> bool:
	if ground_check_sample_points.is_empty():
		push_warning("MovementComponent of %s: ground_check_sample_points is empty, cannot check for floor!" % [parent])
		return false

	# small offset upwards to avoid sampling wrong cell when exactly/close  on floor line
	var vertical_sample_offset: Vector2 = Global.VERT_SAMPLE_OFFSET_SMALL

	for sample_x_offset in ground_check_sample_points:
		# World position to sample and corresponding cell (might be in another cell)
		var sample_pos: Vector2 = parent.global_position + Vector2(sample_x_offset, 0.0) + vertical_sample_offset
		var sample_cell: Cell = Global.level.sample_cell_at_world_pos(sample_pos)

		if sample_cell == null:
			continue
		
		# y of floor at this x
		var y_cell_floor_with_epsilon: float = sample_cell.get_floor_point_at_world_x(sample_pos.x).y - Util.EPSILON_PIXEL_DIST
		var is_on_floor := parent.global_position.y >= y_cell_floor_with_epsilon

		if is_on_floor:
			return true

	return false


func _get_curr_move_mode() -> Enum.MoveMode:
	if path:
		return path.get_curr_move_mode()
	else:
		return Enum.MoveMode.WALK

func _get_can_use_ladders() -> bool:
	if is_falling():
		return movement_stats.can_use_ladders_when_falling
	else:
		return movement_stats.can_use_ladders

func _is_climbing() -> bool:
	var move_mode := _get_curr_move_mode()
	var climbing_modes := [Enum.MoveMode.CLIMB_LADDER_UP, Enum.MoveMode.CLIMB_LADDER_DOWN, Enum.MoveMode.CLIMB_WALL_UP, Enum.MoveMode.CLIMB_WALL_DOWN]
	return climbing_modes.has(move_mode)
