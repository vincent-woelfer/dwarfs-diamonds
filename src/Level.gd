class_name Level
extends Node2D

var wandering_light_scene := preload('res://scenes/WanderingLight.tscn')
var dwarf_scene := preload('res://scenes/Dwarf.tscn')

var cells: Array[Array] = []

var nav: Nav
var job_manager: JobManager

func _ready() -> void:
	# GRID
	_generate_grid()

	# Required but hacky :/
	# Wait a frame to ensure all cells are ready
	# Wait a second frame to ensure all cells have updated their walkability
	await get_tree().process_frame
	await get_tree().process_frame

	nav = Nav.new()
	add_child(nav)

	job_manager = JobManager.new()
	add_child(job_manager)

	# Sunlight from straight above
	# var sun := DirectionalLight2D.new()
	# sun.rotation_degrees = -5.0
	# sun.color = Color(1.0, 0.93, 0.88)
	# sun.energy = 3.0
	# sun.shadow_enabled = true
	# add_child(sun)

	# Darkness
	# var darkness := CanvasModulate.new()
	# # var d := 0.8
	# var d := 1.0
	# darkness.color = Color(d, d, d, 1.0)
	# add_child(darkness)

	# Wandering Lights
	# for i in range(16):
	# 	var light: WanderingLight = wandering_light_scene.instantiate()
	# 	var light_pos := Vector2(randi_range(1, Global.LEVEL_WIDTH - 1), randi_range(1, Global.LEVEL_HEIGHT - 1))
	# 	light_pos *= Global.CELL_SIZE
	# 	light.global_position = light_pos
	# 	add_child(light)


	# DWARF
	var dwarf_grid_pos := Vector2i(3, 3)
	var dwarf: Dwarf = dwarf_scene.instantiate()
	dwarf.grid_pos = dwarf_grid_pos
	add_child(dwarf)


func _generate_grid() -> void:
	HexLog.print_banner_with_text("Generating Grid")
	cells.clear()

	# Pre-generate 2D array of nulls
	for x in range(Global.LEVEL_WIDTH):
		var row: Array = []
		for y in range(Global.LEVEL_HEIGHT):
			row.append(null)
		cells.append(row)

	var noise_scale := 15.0

	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = ceil(Global.LEVEL_WIDTH * noise_scale)
	texture.height = ceil(Global.LEVEL_HEIGHT * noise_scale)
	
	var fast_noise_lite := FastNoiseLite.new()
	fast_noise_lite.seed = 57
	texture.noise = fast_noise_lite
	await texture.changed
	var image := texture.get_image()

	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var type: Enum.CellType = [Enum.CellType.A, Enum.CellType.B, Enum.CellType.C].pick_random()

			# Is Solid			
			var threshold_above_is_solid := 0.35
			var is_solid: bool = image.get_pixel(roundi(x * noise_scale), roundi(y * noise_scale)).r > threshold_above_is_solid
			if y <= Global.SKY_HEIGHT:
				is_solid = false
				type = Enum.CellType.SKY

			var cell := Cell.new(Vector2i(x, y), type, is_solid)
			cell.position = Vector2(x, y) * Global.CELL_SIZE
			add_child(cell)
			cells[x][y] = cell


########################################################################################################################
# Helper functions
########################################################################################################################
func get_cell(grid_pos: Vector2i) -> Cell:
	if not Util.is_grid_pos_valid(grid_pos):
		return null

	@warning_ignore("unsafe_cast")
	return cells[grid_pos.x][grid_pos.y] as Cell


# TODO improve accuracy for irregular polygon shapes
func get_cell_at_world_pos(world_pos: Vector2) -> Cell:
	var grid_pos := Vector2i(floori(world_pos.x / Global.CELL_SIZE), floori(world_pos.y / Global.CELL_SIZE))
	return get_cell(grid_pos)
