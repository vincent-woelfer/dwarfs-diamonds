@tool
class_name Level
extends Node2D

var wandering_light_scene := preload('res://scenes/WanderingLight.tscn')


func _ready():
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
		light.global_position = Vector2(randi_range(1, Util.LEVEL_WIDTH-1), randi_range(1, Util.LEVEL_HEIGHT-1)) * Util.CELL_SIZE
		add_child(light)

	# Add path
	var path : Path = Path.new()
	add_child(path)

func _generate_grid():
	for y in range(Util.LEVEL_HEIGHT):
		for x in range(Util.LEVEL_WIDTH):
			var type: Cell.CellType = Cell.CellType.values().pick_random()
			var c := Cell.new(Vector2i(x, y), type)
			add_child(c)

	

