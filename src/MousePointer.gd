class_name MousePointer
extends Node2D

var sprite: Polygon2D
var size: float = 20.0
var color := Color(1, 0, 0, 0.5)

var curr_selected_cells: Array[Cell] = []
var prev_selected_cells: Array[Cell] = []

# Miner interface -> TODO Move to Component ???
var mine_speed := 0.5 # per second
var currently_mining_cells: Array[Cell] = []


func _ready() -> void:
	sprite = Polygon2D.new()
	sprite.polygon = PackedVector2Array([Vector2(0, 0), Vector2(size, 0), Vector2(size, size), Vector2(0, size)])
	sprite.offset = Vector2.ONE * -size * 0.5
	sprite.color = color
	sprite.position = self.position
	sprite.z_index = 10
	add_child(sprite)


func _process(delta: float) -> void:
	# Move Mouse Sprite
	self.position = Global.camera.mouse_pos_world_space()

	# Selected Cell
	curr_selected_cells = _sample_cells_at_mouse_pos(self.position)

	# Deselect previous
	for cell in prev_selected_cells:
		if cell not in curr_selected_cells:
			cell.is_selected = false

	# Select current
	for cell in curr_selected_cells:
		cell.is_selected = true

	# Click on cells
	if Input.is_action_just_pressed("mouse_left"):
		for cell in curr_selected_cells:
			# Toggle highlight
			cell.is_highlighted = not cell.is_highlighted

	# Continuous press
	elif Input.is_action_pressed("mouse_left"):
		for cell in curr_selected_cells:
			if cell not in prev_selected_cells:
				cell.is_highlighted = not cell.is_highlighted
			
	# Mine Cells
	if Input.is_action_just_pressed("mouse_right_mine"):
		for cell in curr_selected_cells:
			_start_mining(cell)

	# Build Cells
	if Input.is_action_just_pressed("mouse_right_build"):
		for cell in curr_selected_cells:
			cell.build_platform()

	# Build Laders
	if Input.is_action_just_pressed("mouse_right_build_ladder"):
		for cell in curr_selected_cells:
			if not cell.has_ladder:
				cell.build_ladder()
			else:
				cell.destroy_ladder()

	# Update prev -> curr
	prev_selected_cells = curr_selected_cells.duplicate()

	########### Mining process ########
	for mining_cell in currently_mining_cells:
		if mining_cell == null or not mining_cell.is_solid:
			currently_mining_cells.erase(mining_cell)
			continue

		mining_cell.mining_process += mine_speed * delta
		if mining_cell.mining_process >= 1.0:
			currently_mining_cells.erase(mining_cell)
			mining_cell.destroy()


	######## DEBUG ########
	if Input.is_action_just_pressed("dev_place_debug_path_start"):
		if curr_selected_cells.size() > 0:
			var cell := curr_selected_cells[0]
			EventBus.emit_signal("Signal_DebugPathSetStartCell", cell.grid_pos)


func _start_mining(cell: Cell) -> void:
	if cell in currently_mining_cells or cell == null or not cell.is_solid:
		return

	currently_mining_cells.append(cell)


## Sample cells at mouse position. Guaranteed to not be null
# TODO Can later be expanded to a radius or area or pattern
func _sample_cells_at_mouse_pos(world_pos: Vector2) -> Array[Cell]:
	var cells: Array[Cell] = []

	var cell := Global.level.get_cell_at_world_pos(world_pos)
	Util.array_append_unique_not_null(cells, cell)

	# for x in range(2):
		# var cell := level.get_cell_at_world_pos(world_pos + Vector2(x, 0) * Global.CELL_SIZE)
		# Util.array_add_unique_not_null(cells, cell)

	return cells
