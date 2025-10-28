class_name Path
extends Node2D

## Construct once and reuse only for following. Dont assign new points.
## Only drawn if added to scene tree, but normal usage is to not do so.

var _points_grid_space: Array[Vector2i]
var _center_points_world_space: PackedVector2Array
var _floor_points_world_space: PackedVector2Array

# Only works for one follower at a time
var _follow_next_index_floor: int = 0 # Capped at size (so after last point) == reached end
var _follow_next_index_center: int = 0 # only used for debug drawing

var debug_draw: bool = false

# Normal case is > 2 points. 0 is an exception
func _init(points_grid_space_: Array[Vector2i]) -> void:
	self._points_grid_space = points_grid_space_
	self._center_points_world_space = Util.grid_to_world_cell_center_array(_points_grid_space)
	self._floor_points_world_space = _calculate_follow_points()


## For now just returns number of points
func get_num_cells() -> float:
	return _points_grid_space.size()


## Call when starting to follow path to start from closest point
func update_following_index_to_closest(current_world_pos: Vector2) -> void:
	if _floor_points_world_space.size() == 0:
		_follow_next_index_center = 0
		_follow_next_index_floor = 0
		return

	# Start following from closest point to here
	for i in range(_floor_points_world_space.size() - 1):
		var a := _floor_points_world_space[i]
		var b := _floor_points_world_space[i + 1]
		if Util.is_point_near_line_segment(current_world_pos, a, b):
			_increment_follow_index()
			break

	_debug_draw_proxy.queue_redraw()

func _increment_follow_index() -> void:
	# Increment with cap
	_follow_next_index_floor = min(_follow_next_index_floor + 1, _floor_points_world_space.size())

	var valid_floor_points_index: int = min(_follow_next_index_floor, _floor_points_world_space.size() - 1)
	var floor_point_world_space: Vector2 = _floor_points_world_space[valid_floor_points_index]
	var grid_pos: Vector2i = Global.level.get_cell_at_world_pos(floor_point_world_space + Global.VERT_OFFSET_SMALL).grid_pos

	# Find grid_space index, cell-center index is the same
	_follow_next_index_center = _points_grid_space.find(grid_pos)


## Returns new position in world space after following path for distance
## Updates internal state to continue from there
## current_pos in world space
func follow_path(current_pos: Vector2, distance: float) -> Vector2:
	var final_pos: Vector2 = current_pos

	while _follow_next_index_floor < _floor_points_world_space.size():
		var next_waypoint: Vector2 = _floor_points_world_space[_follow_next_index_floor]
		var vec_to_next: Vector2 = next_waypoint - current_pos
		var dist_to_next: float = vec_to_next.length()
		var dir_to_next: Vector2 = vec_to_next.normalized()

		# Distance covered -> break
		if distance < dist_to_next:
			final_pos += dir_to_next * distance
			break

		# Waypoint reached, continue to next
		final_pos = next_waypoint
		distance -= dist_to_next
		_increment_follow_index()
		_debug_draw_proxy.queue_redraw()

	return final_pos


func reached_end() -> bool:
	assert(_follow_next_index_floor <= _floor_points_world_space.size())
	return _follow_next_index_floor == _floor_points_world_space.size()


## Calculates follow points connecting floor-points of cells
func _calculate_follow_points() -> PackedVector2Array:
	if _points_grid_space.size() == 0:
		return PackedVector2Array()

	var follow_points: PackedVector2Array = PackedVector2Array()

	# We go through pairs and connect from ground-center to ground-center.
	# We always assume from-center is already in follow_points, thats why we add it for the inital cell before the loop
	follow_points.append(Global.level.get_cell(_points_grid_space[0]).get_floor_point())
	
	for i in range(_points_grid_space.size() - 1):
		var from: Cell = Global.level.get_cell(_points_grid_space[i])
		var to: Cell = Global.level.get_cell(_points_grid_space[i + 1])
		# var from_floor_points: PackedVector2Array = from.get_floor_points()
		# var to_floor_points: PackedVector2Array = to.get_floor_points()
		
		if Util.are_cardinal_neighbours(from.grid_pos, to.grid_pos):
			if from.grid_pos.x == to.grid_pos.x:
				# Vertical -> connect directly, only floor-center of to cell
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT))
			else:
				# Horizontal -> connect directly, exit-floor-point of from + enter-floor-point + center of to
				if from.grid_pos.x < to.grid_pos.x:
					# to the right
					follow_points.append(from.poly_point(Enum.PolyPoint.BOT_RIGHT))
					follow_points.append(to.poly_point(Enum.PolyPoint.BOT_LEFT))
					follow_points.append(to.poly_point(Enum.PolyPoint.BOT))
				else:
					# to the left
					follow_points.append(from.poly_point(Enum.PolyPoint.BOT_LEFT))
					follow_points.append(to.poly_point(Enum.PolyPoint.BOT_RIGHT))
					follow_points.append(to.poly_point(Enum.PolyPoint.BOT))
		else:
			# Diagonal -> we offset the wall-points inward a bit to avoid clipping into walls
			const dwarf_width: Vector2 = Vector2(Global.CELL_SIZE * 0.3, 0.0)

			# Determine direction
			var to_the_right: bool = from.grid_pos.x < to.grid_pos.x
			var upwards: bool = from.grid_pos.y > to.grid_pos.y

			if to_the_right and upwards:
				# in front of wall
				follow_points.append(from.poly_point(Enum.PolyPoint.BOT_RIGHT) - dwarf_width)
				follow_points.append(from.poly_point(Enum.PolyPoint.RIGHT) - dwarf_width)
				follow_points.append(from.poly_point(Enum.PolyPoint.TOP_RIGHT) - dwarf_width)
				# on top of to-cell
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT_LEFT))
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT))

			if to_the_right and not upwards:
				# on top of from-cell
				follow_points.append(from.poly_point(Enum.PolyPoint.BOT_RIGHT))
				# in front of wall
				follow_points.append(to.poly_point(Enum.PolyPoint.TOP_LEFT) + dwarf_width)
				follow_points.append(to.poly_point(Enum.PolyPoint.LEFT) + dwarf_width)
				# on top of to-cell
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT_LEFT) + dwarf_width)
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT))

			if not to_the_right and upwards:
				# in front of wall
				follow_points.append(from.poly_point(Enum.PolyPoint.BOT_LEFT) + dwarf_width)
				follow_points.append(from.poly_point(Enum.PolyPoint.LEFT) + dwarf_width)
				follow_points.append(from.poly_point(Enum.PolyPoint.TOP_LEFT) + dwarf_width)
				# on top of to-cell
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT_RIGHT))
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT))

			if not to_the_right and not upwards:
				# on top of from-cell
				follow_points.append(from.poly_point(Enum.PolyPoint.BOT_LEFT))
				# in front of wall
				follow_points.append(to.poly_point(Enum.PolyPoint.TOP_RIGHT) - dwarf_width)
				follow_points.append(to.poly_point(Enum.PolyPoint.RIGHT) - dwarf_width)
				# on top of to-cell
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT_RIGHT) - dwarf_width)
				follow_points.append(to.poly_point(Enum.PolyPoint.BOT))


	return follow_points

	
########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy := DebugDrawProxy.new(self)

# Only drawn if added to scene tree
var debug_color := Color.ORANGE
var debug_width := 5.0
var debug_draw_follow_points := true
var debug_offset_follow_points := Vector2(0.0, -0.05) * Global.CELL_SIZE_VEC


func _debug_draw_in_ui(ui_layer: CanvasItem) -> void:
	if not debug_draw:
		return

	var completed_color: Color = debug_color
	completed_color.a = 0.3

	var completed_points: PackedVector2Array
	var remaining_points: PackedVector2Array

	if debug_draw_follow_points:
		completed_points = _floor_points_world_space.slice(0, _follow_next_index_floor + 1)
		remaining_points = _floor_points_world_space.slice(_follow_next_index_floor)

		# Slightly offset to be above ground
		for i in range(completed_points.size()):
			completed_points[i] += debug_offset_follow_points
		for i in range(remaining_points.size()):
			remaining_points[i] += debug_offset_follow_points
		
	else:
		completed_points = _center_points_world_space.slice(0, _follow_next_index_center + 1)
		remaining_points = _center_points_world_space.slice(_follow_next_index_center)

	# Finally draw
	if completed_points.size() >= 2:
		ui_layer.draw_polyline(completed_points, completed_color, debug_width)
	if remaining_points.size() >= 2:
		ui_layer.draw_polyline(remaining_points, debug_color, debug_width)
