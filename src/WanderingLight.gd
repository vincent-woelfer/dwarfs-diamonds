class_name WanderingLight
extends Node2D

@onready var light: PointLight2D = $PointLight2D
@onready var sprite: Sprite2D = $Sprite2D

var dir: Vector2
var curve : float
var speed := 60

func _ready() -> void:
	dir = Vector2.from_angle(randf_range(0, 2 * PI)).normalized()
	curve = randf_range(-1, 1)


func _physics_process(delta: float) -> void:
	dir = dir.rotated(curve * delta)
	global_translate(speed * delta * dir)

	if Util.is_map_border(global_position):
		dir *= -1
