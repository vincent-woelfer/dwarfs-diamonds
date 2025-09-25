@tool
class_name Level
extends Node2D

var wandering_light_scene := preload('res://scenes/WanderingLight.tscn')


func _ready() -> void:
	_generate_grid()

	# Sunlight from straight above
	var sun := DirectionalLight2D.new()
	sun.energy = 1.5
	sun.shadow_enabled = true
	# add_child(sun)

	# Darkness
	var darkness := CanvasModulate.new()
	darkness.color = Color(0.5, 0.5, 0.5)
	add_child(darkness)

	# Wandering Lights
	for i in range(10):
		var light: WanderingLight = wandering_light_scene.instantiate()
		var light_pos := Vector2(randi_range(1, Global.LEVEL_WIDTH - 1), randi_range(1, Global.LEVEL_HEIGHT - 1))
		light_pos *= Global.CELL_SIZE
		light.global_position = light_pos
		add_child(light)

	# Add path
	var path: Path = Path.new()
	add_child(path)

func _generate_grid() -> void:
	for y in range(Global.LEVEL_HEIGHT):
		for x in range(Global.LEVEL_WIDTH):
			var type: Cell.CellType = Cell.CellType.values().pick_random()
			var c := Cell.new(Vector2i(x, y), type)
			add_child(c)
