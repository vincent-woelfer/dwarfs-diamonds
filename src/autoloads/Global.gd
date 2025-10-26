# No class_name here, the name of the singleton is set in the autoload
extends Node2D

# Grid dimensions
const CELL_SIZE: int = 128
const CELL_SIZE_VEC: Vector2 = Vector2(CELL_SIZE, CELL_SIZE)

const CELL_SIZE_VEC_HALF: Vector2 = CELL_SIZE_VEC * 0.5
# const CELL_SIZE_VEC_QUARTER: Vector2 = CELL_SIZE_VEC * 0.25
# const CELL_SIZE_VEC_FIFTH: Vector2 = CELL_SIZE_VEC * 0.20

# Size=128 at 3840x2160 (4K) gives 30x16.8 cells
const LEVEL_WIDTH: int = 30
const LEVEL_HEIGHT: int = 30
const LEVEL_SIZE_VEC: Vector2 = Vector2(LEVEL_WIDTH, LEVEL_HEIGHT)
# Aspect setting "keep-width" = width is constant (3840), height changes with aspect ratio
# Aspect setting "expand" = both width and height change with aspect ratio.
# Both will never be smaller than the base mouse_size (3840x2160), one will always be larger or exact base mouse_size.

const VERT_OFFSET_SMALL := Vector2(0, -CELL_SIZE * 0.5)

const VEC_LEFT := Vector2(-1, 0)
const VEC_RIGHT := Vector2(1, 0)
const VEC_UP := Vector2(0, -1)
const VEC_DOWN := Vector2(0, 1)


const SKY_HEIGHT: int = 3

# Relevant Game Objects
@onready var camera: Camera = get_tree().root.get_node("root/Camera")
@onready var level: Level = get_tree().root.get_node("root/Level")


func _ready() -> void:
	# Hook into window mouse_size changes
	if not Engine.is_editor_hint():
		get_viewport().size_changed.connect(_on_window_size_changed)

	if not Engine.is_editor_hint():
		pass
		# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func _process(delta: float) -> void:
	pass
		
	
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
		var post_process_canvas_layer: PostProcessCanvasLayer = get_tree().root.get_node("root/PostProcessCanvasLayer-1")
		if post_process_canvas_layer:
			post_process_canvas_layer.update_size(size)

		var stencil_viewport: StencilViewport = get_tree().root.get_node("root/StencilViewport")
		if stencil_viewport:
			stencil_viewport.update_size(size)
