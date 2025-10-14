class_name Path
extends Node2D


var points_grid_space: PackedVector2Array = []

# Debug Visualization
var color := Color.GREEN
var width := 6.0


func _init(points_grid_space_: PackedVector2Array = []) -> void:
	self.points_grid_space = points_grid_space_


func _ready() -> void:
	self.z_index = 5
	self.visibility_layer = Util.LAYER_1
	self.light_mask = 0


func _draw() -> void:
	if points_grid_space.size() < 2:
		return

	# Convert points_grid_space from grid_space to world_space and offset to be centered on cell
	var points_world_space := Util.grid_space_to_world_space_cell_center_array(points_grid_space)
	draw_polyline(points_world_space, color, width)


func _process(_delta: float) -> void:
	queue_redraw()
