class_name Path
extends Node2D

## Construct once and reuse. Dont assign new points.
## Only drawn if added to scene tree, but normal usage is to not do so.

var _points_grid_space: Array[Vector2i]
var _points_world_space: PackedVector2Array

# Only works for one follower at a time
var following_next_index: int = 0


# Normal case is > 2 points. 0 is an exception
func _init(points_grid_space_: Array[Vector2i]) -> void:
	self.top_level = true
	self.z_index = 5
	self.visibility_layer = Util.LAYER_1
	self.light_mask = 0

	self._points_grid_space = points_grid_space_
	self._points_world_space = Util.grid_space_to_world_space_cell_center_array(_points_grid_space)

## For no just returns number of points
func get_length() -> float:
	return _points_grid_space.size()


func get_start() -> Vector2i:
	return _points_grid_space[0]


func get_end() -> Vector2i:
	return _points_grid_space[_points_grid_space.size() - 1]


## Call when starting to follow path to start from closest point
func update_following_index_to_closest(current_pos: Vector2) -> void:
	# Start following from closest point to here
	for i in range(_points_world_space.size() - 1):
		var a := _points_world_space[i]
		var b := _points_world_space[i + 1]
		if Util.is_point_near_line_segment(current_pos, a, b):
			following_next_index = i + 1
			break

	queue_redraw()

## current_pos in world space
## Path-points are in cell-center world space
## Returns new position in world space after following path for distance
## Updates internal state to continue from there
func follow_path(current_pos: Vector2, distance: float) -> Vector2:
	var final_pos: Vector2 = current_pos

	while following_next_index < _points_world_space.size():
		var next_waypoint: Vector2 = _points_world_space[following_next_index]
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
		following_next_index += 1

		queue_redraw()

	return final_pos


func reached_end() -> bool:
	return following_next_index >= _points_world_space.size()


########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
# Only drawn if added to scene tree
var color := Color.ORANGE
var width := 5.0

func _draw() -> void:
	var completed_points: PackedVector2Array = _points_world_space.slice(0, following_next_index + 1)
	var remaining_points: PackedVector2Array = _points_world_space.slice(following_next_index)
	var completed_color: Color = color
	completed_color.a = 0.3

	if completed_points.size() >= 2:
		draw_polyline(completed_points, completed_color, width)
	if remaining_points.size() >= 2:
		draw_polyline(remaining_points, color, width)
