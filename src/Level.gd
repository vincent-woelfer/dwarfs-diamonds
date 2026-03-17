class_name Level
extends Node2D

var dwarf_scene := preload('res://scenes/Dwarf.tscn')
var rubble_scene := preload('res://scenes/objects/Rubble.tscn')
var gemstone_scene := preload('res://scenes/objects/Gemstone.tscn')

var cells: Array[Array] = []
var dwarfs: Array[Dwarf] = []
var rubbles: Array[Rubble] = []
var gemstones: Array[Gemstone] = []

# Managers
var nav_manager: NavManager
var job_manager: JobManager
var building_manager: BuildingManager
var level_stats_manager: LevelStatsManager

var sun_system: SunSystem


func _ready() -> void:
	# GRID
	_generate_grid()

	# Required but hacky :/
	# Wait a frame to ensure all cells are ready
	# Wait a second frame to ensure all cells have updated their walkability
	await get_tree().process_frame
	await get_tree().process_frame

	_compute_all_light_depths()

	## Managers
	nav_manager = NavManager.new()
	add_child(nav_manager)

	job_manager = JobManager.new()
	add_child(job_manager)

	building_manager = BuildingManager.new()
	add_child(building_manager)

	level_stats_manager = LevelStatsManager.new()
	add_child(level_stats_manager)

	# SUN / LIGHTING
	sun_system = SunSystem.new()
	add_child(sun_system)


	# Pre-place Torches
	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var grid_pos := Vector2i(x, y)
			var cell: Cell = get_cell(grid_pos)
			if cell == null:
				continue

			var percentage_with_preplaced_torch := 0.2
			var place_torch := Util.rand_from_coords(grid_pos, 1) < percentage_with_preplaced_torch
			if not cell.is_solid and place_torch and should_contain_torch(grid_pos):
				cell.add_deco_element(DecoTorch.instantiate())


	# DWARF
	spawn_dwarf(Vector2i(8, 5))
	# spawn_dwarf(Vector2i(10, 6))

	# other side
	# spawn_dwarf(Vector2i(23, 6))


func spawn_dwarf(grid_pos: Vector2i) -> void:
	var cell := get_cell(grid_pos)
	if cell == null or not cell.is_passable():
		return

	var dwarf: Dwarf = dwarf_scene.instantiate()
	dwarf.setup(grid_pos)
	add_child(dwarf)
	dwarfs.append(dwarf)


func spawn_rubble(grid_pos: Vector2i) -> void:
	var cell := get_cell(grid_pos)
	if cell == null or not cell.is_passable():
		return

	var new_rubble: Rubble = rubble_scene.instantiate()
	new_rubble.setup(grid_pos)
	add_child(new_rubble)
	rubbles.append(new_rubble)

func spawn_gemstone(grid_pos: Vector2i) -> void:
	var cell := get_cell(grid_pos)
	if cell == null or not cell.is_passable():
		return

	var new_gemstone: Gemstone = gemstone_scene.instantiate()
	new_gemstone.setup(grid_pos)
	add_child(new_gemstone)
	gemstones.append(new_gemstone)


## Deterministic torch placement
func should_contain_torch(grid_pos: Vector2i) -> bool:
	# Simple rule: place torch every 5 cells in x and y, avoid sky area
	if grid_pos.y <= Global.SKY_HEIGHT + 2:
		return false

	var percentage_with_torch := 0.95
	var random_disable := Util.rand_from_coords(grid_pos, 10) > percentage_with_torch
	if random_disable:
		return false

	var grid_spacing := Vector2i(3, 1)

	# Random offset, only horizontal and same for entire row. x must be 1 otherwise its on map border
	var rand_offset := Vector2i.ZERO
	if Util.rand_from_coords(grid_pos, 11) < 0.2:
		rand_offset.x = Util.randi_from_coords(Vector2i(1, grid_pos.y), 0, grid_spacing.x, 12)

	var alternating_offset := Vector2i(roundi(grid_pos.y / (grid_spacing.y as float)), 0)

	var sample_pos := grid_pos + rand_offset + alternating_offset
	if sample_pos.x % grid_spacing.x == 0 and sample_pos.y % grid_spacing.y == 0:
		return true

	return false


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
	# fast_noise_lite.seed = 57
	fast_noise_lite.seed = randi()
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
# Light Calculation
########################################################################################################################
func _compute_all_light_depths() -> void:
	var start_time := Time.get_ticks_msec()

	assert(cells.size() > 0 and cells[0].size() > 0)
	var queue: Array[Vector2i] = []

	# init
	for x in Global.LEVEL_WIDTH:
		for y in Global.LEVEL_HEIGHT:
			var cell: Cell = cells[x][y]
			if not cell.is_solid:
				cell.light_depth = 0
				queue.append(Vector2i(x, y))
			else:
				cell.light_depth = 999

	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		var depth: int = cells[p.x][p.y].light_depth

		for dir: Vector2i in Util.neighbours_cardinal:
			var n: Vector2i = p + dir
			if not Util.is_grid_pos_valid(n):
				continue

			var new_depth := depth + 1
			if new_depth < cells[n.x][n.y].light_depth:
				cells[n.x][n.y].light_depth = new_depth
				queue.append(n)

	var duration := Time.get_ticks_msec() - start_time
	HexLog.print("Level => Updated complete light depth map in: %d ms" % [duration], Colors.LIGHT_DEPTH_PRINT_COLOR)


## Change one cell to free and update neighbouring cells. Faster than full recomputation
func _change_cell_to_free(pos: Vector2i) -> void:
	var start_time := Time.get_ticks_msec()

	assert(cells[pos.x][pos.y].is_solid == false)
	cells[pos.x][pos.y].light_depth = 0
	var queue: Array[Vector2i] = [pos]
	var head := 0

	while head < queue.size():
		var p := queue[head]
		head += 1
		var depth: int = cells[p.x][p.y].light_depth
		for dir: Vector2i in Util.neighbours_cardinal:
			var n: Vector2i = p + dir
			if not Util.is_grid_pos_valid(n):
				continue

			var new_depth := depth + 1
			if new_depth < cells[n.x][n.y].light_depth:
				cells[n.x][n.y].light_depth = new_depth
				queue.append(n)

	var duration := Time.get_ticks_msec() - start_time
	HexLog.print("Level => Updated one cell light depth map in: %d ms" % [duration], Colors.LIGHT_DEPTH_PRINT_COLOR)


## Called AFTER changing cell.is_solid. Updates light_depth accordingly
func _update_cell_is_solid(pos: Vector2i) -> void:
	assert(Util.is_grid_pos_valid(pos))
	var cell: Cell = cells[pos.x][pos.y]

	if cell.is_solid:
		# free -> solid => update all
		_compute_all_light_depths()
	else:
		# solid -> free => incremental update possible
		_change_cell_to_free(pos)

########################################################################################################################
# Helper functions
########################################################################################################################
func get_cell(grid_pos: Vector2i) -> Cell:
	if not Util.is_grid_pos_valid(grid_pos):
		return null

	@warning_ignore("unsafe_cast")
	return cells[grid_pos.x][grid_pos.y] as Cell


# TODO improve accuracy for irregular polygon shapes.
# TODO maybe add -1 pixel (upwards) offset to avoid sampling wrong cell when exactly/close on floor line
func sample_cell_at_world_pos(world_pos: Vector2) -> Cell:
	var grid_pos := Vector2i(floori(world_pos.x / Global.CELL_SIZE), floori(world_pos.y / Global.CELL_SIZE))
	return get_cell(grid_pos)
