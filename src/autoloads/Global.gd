# No class_name here, the name of the singleton is set in the autoload
@tool
extends Node2D

# Grid dimensions
const CELL_SIZE: int = 128
const CELL_SIZE_VEC: Vector2 = Vector2(CELL_SIZE, CELL_SIZE)

const CELL_SIZE_VEC_HALF: Vector2 = CELL_SIZE_VEC * 0.5

## From top-left corner of cell to center of floor (0,0 in editor)
const CELL_OFFSET_CORNER_TO_CENTER_FLOOR: Vector2 = Vector2(0.5, 1.0) * CELL_SIZE_VEC

# Size=128 at 3840x2160 (4K) gives 30x16.8 cells
const LEVEL_WIDTH: int = 40
const LEVEL_HEIGHT: int = 30
const LEVEL_SIZE_VEC: Vector2 = Vector2(LEVEL_WIDTH, LEVEL_HEIGHT)
# Aspect setting "keep-width" = width is constant (3840), height changes with aspect ratio
# Aspect setting "expand" = both width and height change with aspect ratio.
# Both will never be smaller than the base mouse_size (3840x2160), one will always be larger or exact base mouse_size.

const VEC_LEFT := Vector2(-1, 0)
const VEC_RIGHT := Vector2(1, 0)
const VEC_UP := Vector2(0, -1)
const VEC_DOWN := Vector2(0, 1)

const SKY_HEIGHT: int = 6

const CellMiningHardness := {
	Enum.CellType.A: 1.0,
	Enum.CellType.B: 2.0,
	Enum.CellType.C: 3.0,
	Enum.CellType.BUILDING: 3.0,
}

# Group Names
const GROUP_CARRYABLE_ITEMS: String = "carryable_items"


# Relevant Game Objects
@onready var camera: Camera
@onready var level: Level
@onready var mouse_pointer: MousePointer

# Relevant UI Objects
@onready var stencil_viewport: StencilViewport
@onready var post_process_canvas_layer: PostProcessCanvasLayer
@onready var ui_canvas_layer_world_space: CanvasLayer
@onready var ui_canvas_layer_screen_space: CanvasLayer


func _load_global_references() -> void:
	if Engine.is_editor_hint():
		HexLog.print_banner_with_text("Global autoload: skipping reference loading in editor.")
		return

	# Relevant Game Objects
	camera = _get_from_root("Camera")
	level = _get_from_root("Level")
	mouse_pointer = _get_from_root("UICanvasLayer-WorldSpace-2/MousePointer")

	# Relevant UI Objects
	stencil_viewport = _get_from_root("StencilViewport")
	post_process_canvas_layer = _get_from_root("PostProcessCanvasLayer-1")
	ui_canvas_layer_world_space = _get_from_root("UICanvasLayer-WorldSpace-2")
	ui_canvas_layer_screen_space = _get_from_root("UICanvasLayer-ScreenSpace-3")

	HexLog.print_banner_with_text("Loaded Global references. Level: %s" % level)


func _ready() -> void:
	# Hook into window mouse_size changes
	if not Engine.is_editor_hint():
		get_viewport().size_changed.connect(_on_window_size_changed)

	if not Engine.is_editor_hint():
		pass
		# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Input.mouse_mode = Input.MOUSE_MODE_CONFINED

	_load_global_references()
	
		
# React to keyboard inputs to directly trigger events
func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		# Quit game
		if event.is_action_pressed("quit"):
			HexLog.print_multiline_banner_with_text("Quitting Game")
			get_tree().quit()


# React to window mouse_size changes
func _on_window_size_changed() -> void:
	if not Engine.is_editor_hint():
		var size: Vector2i = get_viewport().get_visible_rect().size
		print("Updated viewport (game-world) size to: ", size)

		if post_process_canvas_layer:
			post_process_canvas_layer.update_size(size)
		
		if stencil_viewport:
			stencil_viewport.update_size(size)

		# Add ui_canvas_layer_screen_space ???


func _get_from_root(path: String) -> Variant:
	# This does not work in editor rn because this is an autoload
	# The second "root/" is the name of the main scene node, NOT the scene tree root
	const main_scene_name := "root"
	return get_tree().root.get_node("%s/%s" % [main_scene_name, path])


func get_group(group_name: String) -> Array:
	return get_tree().get_nodes_in_group(group_name)
