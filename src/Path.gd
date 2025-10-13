class_name Path
extends Node2D


var points: PackedVector2Array = []
var color := Color.GREEN
var width := 8.0


func _init(points_: PackedVector2Array = []) -> void:
	self.points = points_


func _ready() -> void:
	self.z_index = 5
	self.visibility_layer = Util.LAYER_1
	self.light_mask = 0


func _draw() -> void:
	if points.size() < 2:
		return

	# Convert points from grid_space to world_space and offset to be centered on cell
	var offset_points := Util.grid_space_to_world_space_cell_center_array(points)
	draw_polyline(offset_points, color, width)


func _process(_delta: float) -> void:
	queue_redraw()
