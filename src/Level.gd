@tool
class_name Level
extends Node2D

var wandering_light_scene := preload('res://scenes/WanderingLight.tscn')


func _ready() -> void:
	# GRID
	_generate_grid()

	# Sunlight from straight above
	var sun := DirectionalLight2D.new()
	sun.color = Color(1.0, 0.93, 0.88)
	sun.energy = 1.85
	sun.shadow_enabled = true
	add_child(sun)

	# Darkness
	var darkness := CanvasModulate.new()
	darkness.color = Color(0.5, 0.5, 0.5)
	add_child(darkness)

	# Wandering Lights
	for i in range(16):
		var light: WanderingLight = wandering_light_scene.instantiate()
		var light_pos := Vector2(randi_range(1, Global.LEVEL_WIDTH - 1), randi_range(1, Global.LEVEL_HEIGHT - 1))
		light_pos *= Global.CELL_SIZE
		light.global_position = light_pos
		add_child(light)

	# Add path
	# var path: Path = Path.new()
	# add_child(path)

# 	_randomize_selection()
	
# func _randomize_selection() -> void:
# 	for cell in get_children():
# 		if cell is Cell:
# 			var c := cell as Cell
# 			c.is_selected = randf() < 0.2

# 	await Util.await_time(1.0)
# 	_randomize_selection()
	

func _generate_grid() -> void:
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.noise = FastNoiseLite.new()
	await texture.changed
	var image := texture.get_image()

	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var type: Cell.CellType = Cell.CellType.values().pick_random()

			# Is Solid
			var fac := 15.0
			var is_solid: bool = image.get_pixel(roundi(x * fac), roundi(y * fac)).r > 0.3
			if y <= 3:
				is_solid = false

			var c := Cell.new(Vector2i(x, y), type, is_solid)
			add_child(c)
