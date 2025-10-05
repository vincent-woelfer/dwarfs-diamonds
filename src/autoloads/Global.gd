# @tool
# No class_name here, the name of the singleton is set in the autoload
extends Node2D

# Grid dimensions
const CELL_SIZE: int = 128
const CELL_SIZE_VEC: Vector2 = Vector2(CELL_SIZE, CELL_SIZE)

# Size=128 at 3840x2160 (4K) gives 30x16.8 cells
const LEVEL_WIDTH: int = 30
const LEVEL_HEIGHT: int = 24
const LEVEL_SIZE_VEC: Vector2 = Vector2(LEVEL_WIDTH, LEVEL_HEIGHT)
# Aspect setting "keep-width" = width is constant (3840), height changes with aspect ratio
# Aspect setting "expand" = both width and height change with aspect ratio. Both will never be smaller than the base mouse_size (3840x2160),
# one will always be larger or exact base mouse_size.

# Relevant Game Objects
@onready var camera: Camera = get_tree().root.get_node("root/Camera")
@onready var level: Level = get_tree().root.get_node("root/Level")

var path: Path

func _ready() -> void:
	# Hook into window mouse_size changes
	get_viewport().connect("size_changed", Callable(self, "_on_window_size_changed"))

	if not Engine.is_editor_hint():
		pass
		# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Input.mouse_mode = Input.MOUSE_MODE_CONFINED

	# Add mouse
	add_child(MousePointer.new())

	# Path
	path = Path.new([])
	add_child(path)


func _process(delta: float) -> void:
	if not level.pathfinding:
		return

	# FOR NOW TEST PATH FINDING EVERY FRAME
	var mouse_world_pos: Vector2 = camera.mouse_pos_world_space()
	var mouse_grid_pos: Vector2i = (mouse_world_pos / CELL_SIZE).floor()

	var from_id: int = level.pathfinding._hash(Vector2i(1, 3))
	var to_id: int = level.pathfinding._hash(mouse_grid_pos)

	# Check if both points are walkable
	var both_walkable := level.pathfinding.astar.has_point(from_id) and level.pathfinding.astar.has_point(to_id)

	if not both_walkable:
		path.points = []
		return

	var path_points := level.pathfinding.astar.get_point_path(from_id, to_id, false)

	if path_points.size() >= 2:
		path.points = path_points
	else:
		path.points = []
		
	
# React to keyboard inputs to directly trigger events
func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		# Quit game
		if event.is_action_pressed("quit"):
			HexLog.print_multiline_banner_with_text("Quitting Game")
			get_tree().quit()


# React to window mouse_size changes
func _on_window_size_changed() -> void:
	var size: Vector2i = get_viewport().get_visible_rect().size
	print("Updated viewport (game-world) size to: ", size)

	if not Engine.is_editor_hint():
		var post_process_canvas_layer: PostProcessCanvasLayer = get_tree().root.get_node("root/PostProcessCanvasLayer")
		if post_process_canvas_layer:
			post_process_canvas_layer.update_size(size)

		var stencil_viewport: StencilViewport = get_tree().root.get_node("root/StencilViewport")
		if stencil_viewport:
			stencil_viewport.update_size(size)
