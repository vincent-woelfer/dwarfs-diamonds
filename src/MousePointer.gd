class_name MousePointer
extends Node2D

var sprite: Polygon2D
var size: float = 20.0
var color := Color(1, 0, 0, 0.5)

var curr_selected_cells: Array[Cell] = []
var prev_selected_cells: Array[Cell] = []

var mining_comp: MiningComponent

func _ready() -> void:
	sprite = Polygon2D.new()
	sprite.polygon = PackedVector2Array([Vector2(0, 0), Vector2(size, 0), Vector2(size, size), Vector2(0, size)])
	sprite.offset = Vector2.ONE * -size * 0.5
	sprite.color = color
	sprite.position = self.position
	sprite.z_index = 10
	add_child(sprite)

	mining_comp = MiningComponent.new()
	add_child(mining_comp)


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
			Global.level.job_manager.add_job(Job.new(Enum.JobType.BUILD, Enum.JobStatus.BLOCKED, cell))

	# Continuous press
	elif Input.is_action_pressed("mouse_left"):
		for cell in curr_selected_cells:
			if cell not in prev_selected_cells:
				cell.is_highlighted = not cell.is_highlighted
			
	# Mine Cells
	if Input.is_action_just_pressed("mouse_right_mine"):
		for cell in curr_selected_cells:
			mining_comp.start_mining(cell)
			

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

	######## DEBUG ########
	if Input.is_action_just_pressed("dev_place_debug_path_start"):
		if curr_selected_cells.size() > 0:
			var cell := curr_selected_cells[0]
			EventBus.Signal_DebugPathSetStartCell.emit(cell.grid_pos)


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
