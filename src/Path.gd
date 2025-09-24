class_name Path
extends Node2D


var points: PackedVector2Array = [Vector2(50, 50), Vector2(200, 100), Vector2(600, 200)]
var color := Color.BLUE_VIOLET

func _ready() -> void:
	self.light_mask = 0

func _draw() -> void:
	draw_polyline(points, color, 5.0)

func _process(_delta: float) -> void:
	queue_redraw()
