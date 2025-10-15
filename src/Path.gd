class_name Path
extends Node2D

## Construct once and reuse. Dont assign new points.
## Only drawn if added to scene tree, but normal usage is to not do so.

var _points_grid_space: Array[Vector2i]
var _points_world_space: PackedVector2Array


# Normal case is > 2 points. 0 is an exception
func _init(points_grid_space_: Array[Vector2i] = []) -> void:
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


########################################################################
# DEBUG DRAWING
########################################################################
# Only drawn if added to scene tree
var color := Color.ORANGE
var width := 5.0

func _draw() -> void:
	if _points_grid_space.size() < 2:
		return

	draw_polyline(_points_world_space, color, width)
