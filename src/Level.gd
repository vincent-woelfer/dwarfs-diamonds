class_name Level
extends Node2D

# SCENES
var dwarf_scene := preload('res://scenes/Dwarf.tscn')
var rubble_scene := preload('res://scenes/objects/Rubble.tscn')
var gemstone_scene := preload('res://scenes/objects/Gemstone.tscn')

# DATA
var cells: Array[Array] = []

# max_elevation = highest solid cell at this x. NOT updated after level generation
var max_elevatation_at_x: Array[int] = []
var dwarfs: Array[Dwarf] = []
var rubbles: Array[Rubble] = []
var gemstones: Array[Gemstone] = []

# Managers
var nav_manager: NavManager
var job_manager: JobManager
var building_manager: BuildingManager
var level_stats_manager: LevelStatsManager

var sun_system: SunSystem

########################################################################################################################
# READY
########################################################################################################################
func _ready() -> void:
	# GRID
	_generate_grid()

	# Required but hacky :/
	# Wait a frame to ensure all cells are ready
	# Wait a second frame to ensure all cells have updated their walkability
	await get_tree().process_frame
	await get_tree().process_frame

	_full_light_depths_update()
	EventBus.Signal_LightDepthUpdated.emit()

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
	spawn_dwarf(8)


func spawn_dwarf(x: int) -> void:
	# Max elevation might not be up to date, is only for sky background
	for y in range(Global.LEVEL_HEIGHT):
		var grid_pos := Vector2i(x, y)
		var cell := get_cell(grid_pos)
		if cell == null or not cell.is_passable() or not cell.has_solid_ground():
			continue

		# Found a valid spawn position for the dwarf
		var dwarf: Dwarf = dwarf_scene.instantiate()
		dwarf.setup(grid_pos)
		add_child(dwarf)
		dwarfs.append(dwarf)
		return

	assert(false)


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
	if grid_pos.y <= Global.MAX_ELEVATION_BASELINE + 2:
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

########################################################################################################################
# Max Elevation / Sky
########################################################################################################################
func _get_max_elevation_at_x(x: int) -> int:
	if x < 0 or x >= Global.LEVEL_WIDTH:
		assert(false)
		return 1 # 1 So at least one line of sky
	return max_elevatation_at_x[x]

func is_sky(grid_pos: Vector2i) -> bool:
	return grid_pos.y < _get_max_elevation_at_x(grid_pos.x)

########################################################################################################################
# Level Generation
########################################################################################################################
func _generate_grid() -> void:
	HexLog.print_banner_with_text("Generating Grid")
	cells.clear()

	# Pre-generate 2D array of nulls
	for x in range(Global.LEVEL_WIDTH):
		var row: Array = []
		for y in range(Global.LEVEL_HEIGHT):
			row.append(null)
		cells.append(row)
		max_elevatation_at_x.append(0)

	var noise_scale := 15.0

	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = ceil(Global.LEVEL_WIDTH * noise_scale)
	texture.height = ceil(Global.LEVEL_HEIGHT * noise_scale)
	
	var fast_noise_lite := FastNoiseLite.new()	
	fast_noise_lite.seed = Global.FIXED_MAP_SEED
	texture.noise = fast_noise_lite
	await texture.changed
	var image := texture.get_image()

	_generate_max_elevation_profile(image, noise_scale)

	var threshold_above_is_solid := 0.25
	
	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var type: Enum.CellType = [Enum.CellType.A, Enum.CellType.B, Enum.CellType.C].pick_random()

			# Is Solid						
			var is_solid: bool = image.get_pixel(roundi(x * noise_scale), roundi(y * noise_scale)).r > threshold_above_is_solid

			# No holes above baseline
			if _get_max_elevation_at_x(x) == y or y <= Global.MAX_ELEVATION_BASELINE:
				is_solid = true

			if is_sky(Vector2i(x, y)):
				is_solid = false
				type = Enum.CellType.SKY

			var has_mineral: bool = (randf() < 0.2) if y >= Global.MAX_ELEVATION_BASELINE else false
			var cell := Cell.new(Vector2i(x, y), type, is_solid, has_mineral)
			add_child(cell)
			cells[x][y] = cell


func _generate_max_elevation_profile(image: Image, noise_scale: float) -> void:
	max_elevatation_at_x.clear()
	max_elevatation_at_x.resize(Global.LEVEL_WIDTH)

	var threshold_above_is_solid_above_baseline := 0.7

	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var grid_pos := Vector2i(x, y)
			var is_solid: bool = image.get_pixel(roundi(x * noise_scale), roundi(y * noise_scale)).r > threshold_above_is_solid_above_baseline
			var is_last_above_baseline := y == Global.MAX_ELEVATION_BASELINE
			var is_sky_allowed := y >= Global.MIN_SKY_HEIGHT

			if is_sky_allowed and (is_solid or is_last_above_baseline):
				max_elevatation_at_x[x] = y
				break

	# Smoothing
	var new_max_elevatation_at_x: Array[int] = max_elevatation_at_x.duplicate()
	for x in range(1, Global.LEVEL_WIDTH - 1):
		new_max_elevatation_at_x[x] = roundi((max_elevatation_at_x[x - 1] + max_elevatation_at_x[x] + max_elevatation_at_x[x + 1]) / 3.0)
	max_elevatation_at_x = new_max_elevatation_at_x


########################################################################################################################
# Light Calculation
########################################################################################################################
# Queue of cells that need light depth update. Used to batch updates and avoid redundant calculations
var _light_depth_update_queue: Array[Vector2i] = []

func queue_update_cell_light_depth(grid_pos: Vector2i) -> void:
	if not Util.is_grid_pos_valid(grid_pos):
		return

	# Dont check for duplicates, just add.
	# This is faster and duplicates are not a problem since updates are idempotent
	_light_depth_update_queue.append(grid_pos)


func _update_all_light_depths() -> void:
	var start_time := Time.get_ticks_msec()

	# Check if we need a full update (at least one cell is now is_solid==true) or incremental updates are enough (all now !is_solid).
	# free -> solid => update all
	# solid -> free => incremental update possible
	var needs_full_update := false
	for cell_pos in _light_depth_update_queue:
		var cell := get_cell(cell_pos)
		if cell != null and cell.is_solid:
			needs_full_update = true
			break

	if needs_full_update:
		_full_light_depths_update()
	else:
		for cell_pos in _light_depth_update_queue:
			_incremental_light_depth_update_cell_to_free(cell_pos)
	_light_depth_update_queue.clear()
	
	var duration := Time.get_ticks_msec() - start_time
	if duration > 1:
		HexLog.print("Level => Updated light depth map in: %d ms" % [duration], Colors.LIGHT_DEPTH_PRINT_COLOR)

	EventBus.Signal_LightDepthUpdated.emit()


func _full_light_depths_update() -> void:
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

## Change one cell to free and update neighbouring cells. Faster than full recomputation
func _incremental_light_depth_update_cell_to_free(pos: Vector2i) -> void:
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

########################################################################################################################
# PROCESS
########################################################################################################################
func _process(delta: float) -> void:
	if not _light_depth_update_queue.is_empty():
		_update_all_light_depths()

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


func get_dwarfs_in_cell(grid_pos: Vector2i) -> Array[Dwarf]:
	var dwarfs_in_cell: Array[Dwarf] = []
	for dwarf in dwarfs:
		if dwarf.grid_pos == grid_pos:
			dwarfs_in_cell.append(dwarf)
	return dwarfs_in_cell
