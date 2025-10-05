class_name Path
extends Node2D


var points: PackedVector2Array = []
var color := Color.GREEN


func _init(points_: PackedVector2Array) -> void:
	self.points = points_


func _ready() -> void:
	self.z_index = 5
	self.visibility_layer = Util.LAYER_1
	self.light_mask = 0


func _draw() -> void:
	if points.size() < 2:
		return

	# Offset points to be centered on cell
	var offset_points := PackedVector2Array()
	for p in points:
		offset_points.append(p + Global.CELL_SIZE_VEC * 0.5)

	draw_polyline(offset_points, color, 25.0)


func _process(_delta: float) -> void:
	queue_redraw()
