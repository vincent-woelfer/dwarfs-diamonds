class_name MousePointer
extends Node2D

var sprite: Polygon2D
var size: float = 20.0
var color := Color(1, 0, 0, 0.5)

var curr_selected_cells: Array[Cell] = []
var prev_selected_cells: Array[Cell] = []

var mining_comp: MiningComponent

var selection_pattern: GridPattern

func _ready() -> void:
	sprite = Polygon2D.new()
	sprite.polygon = PackedVector2Array([Vector2(0, 0), Vector2(size, 0), Vector2(size, size), Vector2(0, size)])
	sprite.offset = Vector2.ONE * -size * 0.5
	sprite.color = color
	sprite.position = self.position
	sprite.z_index = 10
	add_child(sprite)

	mining_comp = MiningComponent.new()
	mining_comp.max_simultaneous_mining_cells = 100
	add_child(mining_comp)

	selection_pattern = GridPattern.new([Vector2i.ZERO])


func _process(delta: float) -> void:
	_update_selected_cells()
	_actions()


func _update_selected_cells() -> void:
	self.position = Global.camera.mouse_pos_world_space()

	# Selected Cell
	curr_selected_cells = _sample_cells_at_mouse_pos(self.position)

	# Emit signal if central cell (index 0) changed. Can also be null or changed from null
	var prev_central_cell := prev_selected_cells[0] if !prev_selected_cells.is_empty() else null
	var curr_central_cell := curr_selected_cells[0] if !curr_selected_cells.is_empty() else null
	if prev_central_cell != curr_central_cell:
		EventBus.Signal_MouseHoveredCellChanged.emit(curr_central_cell)

	# Deselect previous
	for cell in prev_selected_cells:
		if cell not in curr_selected_cells:
			cell.set_is_selected(false)

	# Select current
	for cell in curr_selected_cells:
		cell.set_is_selected(true)

	# Mark cells for mining
	# Single click
	if Input.is_action_just_pressed("mouse_left"):
		for cell in curr_selected_cells:
			Actions.mark_cell_for_mining(cell, not cell.is_marked_for_mining)
			
	# Continuous press
	elif Input.is_action_pressed("mouse_left"):
		for cell in curr_selected_cells:
			if cell not in prev_selected_cells:
				Actions.mark_cell_for_mining(cell, not cell.is_marked_for_mining)

	# Update prev -> curr
	prev_selected_cells = curr_selected_cells.duplicate()


func _actions() -> void:
	# Mine Cells
	if Input.is_action_just_pressed("mouse_right_mine"):
		for cell in curr_selected_cells:
			mining_comp.start_mining(cell)


	# Build Cells
	if Input.is_action_just_pressed("mouse_right_build_platform"):
		for cell in curr_selected_cells:
			cell.build_platform()

	# Build Laders
	if Input.is_action_just_pressed("mouse_right_build_ladder"):
		for cell in curr_selected_cells:
			if not cell.has_ladder():
				var ladder_building_data: BuildingData = load("res://scenes/buildings/LadderBuildingData.tres") as BuildingData
				var ladder := Actions.place_building(cell, ladder_building_data)
				# await Util.await_time(1.0)
				ladder._complete() # Complete instantly for mouse pointer
			else:
				pass
				#TODO
				# cell.destroy_ladder()

	######## DEBUG ########
	if Input.is_action_just_pressed("dev_place_debug_path_start"):
		if curr_selected_cells.size() > 0:
			var cell := curr_selected_cells[0]
			EventBus.Signal_DebugPathSetStartCell.emit(cell.grid_pos)


## Sample cells at mouse position. Guaranteed to not be null
# The Cell directly under the mouse MUST BE at index 0!
func _sample_cells_at_mouse_pos(world_pos: Vector2) -> Array[Cell]:
	var selected_cells: Array[Cell] = []

	# Central cell
	var cell := Global.level.get_cell_at_world_pos(world_pos)
	Util.array_append_unique_not_null(selected_cells, cell)

	# Apply pattern
	for offset: Vector2i in selection_pattern.get_local_positions():
		if offset == Vector2i.ZERO:
			continue

		cell = Global.level.get_cell_at_world_pos(world_pos + (offset as Vector2) * Global.CELL_SIZE)
		Util.array_append_unique_not_null(selected_cells, cell)


	# for x in range(2):
		# var cell := level.get_cell_at_world_pos(world_pos + Vector2(x, 0) * Global.CELL_SIZE)
		# Util.array_add_unique_not_null(cells, cell)

	return selected_cells
