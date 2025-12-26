class_name Path
extends Node2D

## Construct once and reuse only for following. Dont assign new points.

########################################################################################################################
# PATH DATA
########################################################################################################################

# Grid positions of cells in path. Size = n
var _grid_points: Array[Vector2i]
# Cell-Center positions in world_space of cells in path. Size = n
var _center_points: PackedVector2Array
# Points on cell floor / cell-wall for diagonal movement. Size = m >= n, depending on path shape
var _floor_points: PackedVector2Array

# Mapping from floor-point-index to grid-point-index. Size = m
# So _map[_next_floor_idx] gives the grid-point-index (size=n) of the cell containing that floor-point
var _floor_to_grid_point_map: Array[int]

# MoveMode from previous floor point to current floor point. Size = m
# [0] is an unused dummy point
var _floor_point_move_modes: Array[Enum.MoveMode]

# Current following indices
# Used mostly for debug drawing and for get_next_cell, capped at size-1
var _next_center_idx: int = 0
# Capped at size-1
var _next_floor_idx: int = 0

var _reached_end: bool = false

# Current position of following-node in world space
var _curr_pos: Vector2 = Vector2.INF

# Width of the follower (for path calculations, e.g. offset from walls when climbing)
var _follower_width: float = Global.CELL_SIZE * 0.3

# Normal case is > 2 points. 0 is an exception
func _init(grid_points_: Array[Vector2i]) -> void:
	self._grid_points = grid_points_

	self._center_points = Util.grid_to_world_cell_center_array(_grid_points)
	_calculate_floor_points()

########################################################################################################################
# PUBLIC
########################################################################################################################

## Call when starting to follow path to start from closest point
func start_following_from_pos(start_pos: Vector2, follower_width_: float = Global.CELL_SIZE * 0.3, debug_draw_: bool = true) -> void:
	_curr_pos = start_pos

	# Enable debug drawing
	debug_draw = debug_draw_

	self._follower_width = follower_width_

	if _floor_points.size() == 0:
		_update_next_indices(0)
		return

	# Start following from closest floor point
	for i in range(_floor_points.size() - 1):
		var a := _floor_points[i]
		var b := _floor_points[i + 1]

		# If close to segment, start from next point
		if Util.is_point_near_line_segment(start_pos, a, b):
			_update_next_indices(i + 1)
			return
	
	# If we reached here, we are past all segments -> start at beginning
	_update_next_indices(0)


## Returns new position in world space after following path for distance from current_pos.
## Updates internal state to continue from there.
## Should be called exactly once per physics frame.
## Allows to call get_curr_cell and get_next_cell after moving.
## current_pos in world space
func tick_follow_path(delta: float, movement_capa: MovementCapabilities) -> Vector2:
	assert(_curr_pos != Vector2.INF) # Make sure start_following_from_pos was called
	var final_pos: Vector2 = _curr_pos

	while not _reached_end:
		var next_waypoint: Vector2 = _floor_points[_next_floor_idx]
		var vec_to_next: Vector2 = next_waypoint - _curr_pos
		var dist_to_next: float = vec_to_next.length()
		var dir_to_next: Vector2 = vec_to_next.normalized()

		var move_mode := _floor_point_move_modes[_next_floor_idx]
		var speed: float = movement_capa.get_speed(move_mode)
		var distance: float = speed * delta

		# Distance covered and no new waypoint reached -> break
		if distance < dist_to_next:
			final_pos += dir_to_next * distance
			break

		# New waypoint reached, continue to next and reduce remaining delta
		final_pos = next_waypoint
		delta -= dist_to_next / speed
		_update_next_indices(_next_floor_idx + 1)

	_curr_pos = final_pos
	return final_pos


## Returns the current cell the following parent is in.
## This is limited to the grid_cells of the path (relevant for diagonal movement)
func get_curr_grid_pos() -> Vector2i:
	return _grid_points[_get_curr_grid_pos_index()]


## Returns the next _cell to be entered
func get_next_grid_pos() -> Vector2i:
	var curr_grid_pos_index := _get_curr_grid_pos_index()
	var next_grid_pos_index: int = min(curr_grid_pos_index + 1, _grid_points.size() - 1)
	return _grid_points[next_grid_pos_index]


func get_curr_move_mode() -> Enum.MoveMode:
	return _floor_point_move_modes[_next_floor_idx]


func reached_end() -> bool:
	return _reached_end


## For now just returns number of points
func get_num_cells() -> int:
	return _grid_points.size()


## Returns length of path in world space, accounting for diagonal movement
func get_total_length_world_space() -> float:
	return _get_total_length_grid_space() * Global.CELL_SIZE

## Returns length of path in world space, accounting for diagonal movement
func get_remaining_length_world_space() -> float:
	return _get_remaining_length_grid_space() * Global.CELL_SIZE


# Simply set is also fine, also calls queue_redraw
func set_debug_draw_enabled(enabled: bool) -> void:
	if debug_draw != enabled:
		debug_draw = enabled
		_debug_draw_proxy_relative.queue_redraw()

func set_debug_draw_color(color: Color) -> void:
	if debug_color != color:
		debug_color = color
		_debug_draw_proxy_relative.queue_redraw()

########################################################################################################################
# INTERNAL API
########################################################################################################################

## Returns the current cell the following parent is in (by index)
## This is limited to the grid_cells of the path (relevant for diagonal movement)
func _get_curr_grid_pos_index() -> int:
	assert(_curr_pos != Vector2.INF) # Make sure start_following_from_pos was called

	# Get prev and next cell grid_poses
	var prev_floor_idx: int = max(_next_floor_idx - 1, 0)
	var prev_cell_grid_pos: Vector2i = _grid_points[_floor_to_grid_point_map[prev_floor_idx]]
	var next_cell_grid_pos: Vector2i = _grid_points[_floor_to_grid_point_map[_next_floor_idx]]

	# If same
	if prev_cell_grid_pos == next_cell_grid_pos:
		return _floor_to_grid_point_map[_next_floor_idx]

	# if between cells -> check which is closer
	else:
		# Get cell centers
		var prev_cell_center := _center_points[_floor_to_grid_point_map[prev_floor_idx]]
		var next_cell_center := _center_points[_floor_to_grid_point_map[_next_floor_idx]]

		var dist_to_prev: float = _curr_pos.distance_squared_to(prev_cell_center)
		var dist_to_next: float = _curr_pos.distance_squared_to(next_cell_center)

		if dist_to_prev <= dist_to_next:
			return _floor_to_grid_point_map[prev_floor_idx]
		else:
			return _floor_to_grid_point_map[_next_floor_idx]


## Updates _next_center_idx to the cell containing the next floor point.
## This means this switches shortly before exiting the current cell.
func _update_next_indices(new_next_floor: int) -> void:
	var max_floor_index := _floor_points.size() - 1

	# Check if we reached the end (if index goes past max). Also works for empty floor_points
	_reached_end = new_next_floor > max_floor_index

	# Increment with cap
	_next_floor_idx = min(new_next_floor, max_floor_index)

	# Update center idx accordingly
	_next_center_idx = _floor_to_grid_point_map[_next_floor_idx]

	_debug_draw_proxy_relative.queue_redraw()

## Calculates floor-points based on _grid_points.
## Also fills _floor_to_grid_point_map.
func _calculate_floor_points() -> void:
	if _grid_points.size() == 0:
		_floor_points = PackedVector2Array()
		_floor_point_move_modes = []
		_floor_to_grid_point_map = []
		return

	# New _floor_points array
	var p: PackedVector2Array = []
	var map: Array[int] = []
	var move_modes: Array[Enum.MoveMode] = []

	# We go through pairs and connect from ground-center to ground-center.
	# We always assume from-center is already in follow_points, thats why we add it for the inital cell before the loop
	p.append(Global.level.get_cell(_grid_points[0]).get_floor_point())
	map.append(0)
	move_modes.append(Enum.MoveMode.WALK) # Dummy first point
	
	for i in range(_grid_points.size() - 1):
		var from_idx := i
		var to_idx := i + 1
		var from: Cell = Global.level.get_cell(_grid_points[from_idx])
		var to: Cell = Global.level.get_cell(_grid_points[to_idx])
		
		if Util.are_cardinal_neighbours(from.grid_pos, to.grid_pos):
			if from.grid_pos.x == to.grid_pos.x:
				# Vertical -> connect directly, only floor-center of to cell
				p.append(to.get_poly_point(Enum.PolyPoint.BOT))
				map.append(to_idx)

				var upwards: bool = from.grid_pos.y > to.grid_pos.y
				if upwards:
					move_modes.append(Enum.MoveMode.CLIMB_LADDER_UP)
				else:
					move_modes.append(Enum.MoveMode.CLIMB_LADDER_DOWN)

			else:
				# Horizontal -> connect directly, exit-floor-point of from + enter-floor-point + center of to
				if from.grid_pos.x < to.grid_pos.x:
					# to the right
					p.append(from.get_poly_point(Enum.PolyPoint.BOT_RIGHT))
					p.append(to.get_poly_point(Enum.PolyPoint.BOT_LEFT))
					p.append(to.get_poly_point(Enum.PolyPoint.BOT))
				else:
					# to the left
					p.append(from.get_poly_point(Enum.PolyPoint.BOT_LEFT))
					p.append(to.get_poly_point(Enum.PolyPoint.BOT_RIGHT))
					p.append(to.get_poly_point(Enum.PolyPoint.BOT))
				
				# Mapping is the same in both cases
				map.append(from_idx)
				map.append_array([to_idx, to_idx])
				move_modes.append_array([Enum.MoveMode.WALK, Enum.MoveMode.WALK, Enum.MoveMode.WALK])
					
		else:
			# Diagonal -> we offset the wall-points inward a bit to avoid clipping into walls
			var width: Vector2 = Vector2(_follower_width, 0.0)

			# Determine direction
			var to_the_right: bool = from.grid_pos.x < to.grid_pos.x
			var upwards: bool = from.grid_pos.y > to.grid_pos.y

			if upwards:
				if to_the_right:
					# in front of wall
					p.append(from.get_poly_point(Enum.PolyPoint.BOT_RIGHT) - width)
					p.append(from.get_poly_point(Enum.PolyPoint.RIGHT) - width)
					p.append(from.get_poly_point(Enum.PolyPoint.TOP_RIGHT) - width)
					# on top of to-cell
					p.append(to.get_poly_point(Enum.PolyPoint.BOT_LEFT))
					p.append(to.get_poly_point(Enum.PolyPoint.BOT))

				elif not to_the_right:
					# in front of wall
					p.append(from.get_poly_point(Enum.PolyPoint.BOT_LEFT) + width)
					p.append(from.get_poly_point(Enum.PolyPoint.LEFT) + width)
					p.append(from.get_poly_point(Enum.PolyPoint.TOP_LEFT) + width)
					# on top of to-cell
					p.append(to.get_poly_point(Enum.PolyPoint.BOT_RIGHT))
					p.append(to.get_poly_point(Enum.PolyPoint.BOT))
				
				# Mapping is the same in both cases
				map.append_array([from_idx, from_idx, from_idx])
				map.append_array([to_idx, to_idx])
				move_modes.append_array([Enum.MoveMode.WALK, Enum.MoveMode.CLIMB_WALL_UP, Enum.MoveMode.CLIMB_WALL_UP])
				move_modes.append_array([Enum.MoveMode.CLIMB_WALL_UP, Enum.MoveMode.WALK])

			elif not upwards:
				if to_the_right:
					# on top of from-cell
					p.append(from.get_poly_point(Enum.PolyPoint.BOT_RIGHT))
					# in front of wall
					p.append(to.get_poly_point(Enum.PolyPoint.TOP_LEFT) + width)
					p.append(to.get_poly_point(Enum.PolyPoint.LEFT) + width)
					# on top of to-cell
					p.append(to.get_poly_point(Enum.PolyPoint.BOT_LEFT) + width)
					p.append(to.get_poly_point(Enum.PolyPoint.BOT))

				elif not to_the_right:
					# on top of from-cell
					p.append(from.get_poly_point(Enum.PolyPoint.BOT_LEFT))
					# in front of wall
					p.append(to.get_poly_point(Enum.PolyPoint.TOP_RIGHT) - width)
					p.append(to.get_poly_point(Enum.PolyPoint.RIGHT) - width)
					# on top of to-cell
					p.append(to.get_poly_point(Enum.PolyPoint.BOT_RIGHT) - width)
					p.append(to.get_poly_point(Enum.PolyPoint.BOT))
				
				# Mapping is the same in both cases
				map.append(from_idx)
				map.append_array([to_idx, to_idx, to_idx, to_idx])
				move_modes.append_array([Enum.MoveMode.WALK, Enum.MoveMode.CLIMB_WALL_DOWN, Enum.MoveMode.CLIMB_WALL_DOWN])
				move_modes.append_array([Enum.MoveMode.CLIMB_WALL_DOWN, Enum.MoveMode.WALK])

	# Final assertions
	assert(p.size() == map.size())
	assert(p.size() == move_modes.size())

	self._floor_points = p
	self._floor_to_grid_point_map = map
	self._floor_point_move_modes = move_modes


## Returns length of path in grid space (cells), accounting for diagonal movement
func _get_total_length_grid_space() -> float:
	var length: float = 0.0
	for i in range(_grid_points.size() - 1):
		length += (_grid_points[i + 1] - _grid_points[i]).length()
	return length

## Returns length of path in grid space (cells), accounting for diagonal movement
func _get_remaining_length_grid_space() -> float:
	var length: float = 0.0
	for i in range(_get_curr_grid_pos_index(), _grid_points.size() - 1):
		length += (_grid_points[i + 1] - _grid_points[i]).length()
	return length
	
########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy_relative := DebugDrawProxy.new(self)

var debug_draw: bool = false:
	set(value):
		debug_draw = value
		_debug_draw_proxy_relative.queue_redraw()

# Visual params -> redraw on change
var debug_color := Color.ORANGE:
	set(value):
		debug_color = value
		_debug_draw_proxy_relative.queue_redraw()
var debug_width := 5.0:
	set(value):
		debug_width = value
		_debug_draw_proxy_relative.queue_redraw()

var debug_draw_follow_points := true:
	set(value):
		debug_draw_follow_points = value
		_debug_draw_proxy_relative.queue_redraw()

var debug_offset_follow_points := Vector2(0.0, -0.05) * Global.CELL_SIZE_VEC:
	set(value):
		debug_offset_follow_points = value
		_debug_draw_proxy_relative.queue_redraw()


func _debug_draw_in_ui_relative(ui_layer: CanvasItem) -> void:
	if not debug_draw:
		return

	var completed_color: Color = debug_color
	completed_color.a = 0.3

	var completed_points: PackedVector2Array
	var remaining_points: PackedVector2Array

	if debug_draw_follow_points:
		completed_points = _floor_points.slice(0, _next_floor_idx + 1)
		remaining_points = _floor_points.slice(_next_floor_idx)

		# Slightly offset to be above ground
		for i in range(completed_points.size()):
			completed_points[i] += debug_offset_follow_points
		for i in range(remaining_points.size()):
			remaining_points[i] += debug_offset_follow_points
		
	else:
		completed_points = _center_points.slice(0, _next_center_idx + 1)
		remaining_points = _center_points.slice(_next_center_idx)

	# Finally draw
	if completed_points.size() >= 2:
		ui_layer.draw_polyline(completed_points, completed_color, debug_width)
	if remaining_points.size() >= 2:
		ui_layer.draw_polyline(remaining_points, debug_color, debug_width)
