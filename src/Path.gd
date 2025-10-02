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
	draw_polyline(points, color, 25.0)


func _process(_delta: float) -> void:
	queue_redraw()
