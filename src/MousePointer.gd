class_name MousePointer
extends Node2D

var sprite: Polygon2D
var size: float = 20.0
var color := Color(1, 0, 0, 0.5)

var curr_selected_cells: Array[Cell] = []
var prev_selected_cells: Array[Cell] = []

@onready var camera: Camera = get_tree().root.get_node("root/Camera")
@onready var level: Level = get_tree().root.get_node("root/Level")


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
	self.position = camera.mouse_pos_world_space()

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
			
	# # Destroy Cells
	# if Input.is_action_just_pressed("mouse_right"):
	# 	if curr_selected_cell and not curr_selected_cell.is_solid:
	# 		curr_selected_cell.is_solid = true
	# 		curr_selected_cell.mining_process = 0
	# 		curr_selected_cell.is_highlighted = false
	# 		curr_selected_cell.is_selected = false

	# Update prev -> curr
	prev_selected_cells = curr_selected_cells.duplicate()


# Sample cells at mouse position
# Can be expanded to a radius or area
func _sample_cells_at_mouse_pos(world_pos: Vector2) -> Array[Cell]:
	var cells: Array[Cell] = []

	var cell := level.get_cell_at_world_pos(world_pos)
	Util.array_add_unique_not_null(cells, cell)

	# for x in range(2):
		# var cell := level.get_cell_at_world_pos(world_pos + Vector2(x, 0) * Global.CELL_SIZE)
		# Util.array_add_unique_not_null(cells, cell)

	return cells
