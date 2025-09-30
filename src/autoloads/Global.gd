@tool
# No class_name here, the name of the singleton is set in the autoload
extends Node2D

# Grid dimensions
const CELL_SIZE: int = 64
const CELL_SIZE_VEC: Vector2 = Vector2(CELL_SIZE, CELL_SIZE)
const LEVEL_WIDTH: int = 22
const LEVEL_HEIGHT: int = 20

func _ready() -> void:
	if not Engine.is_editor_hint():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Input.mouse_mode = Input.MOUSE_MODE_CONFINED

# React to keyboard inputs to directly trigger events
func _input(event: InputEvent) -> void:
	# Only execute in game, check necessary because EventBus is @tool
	if not Engine.is_editor_hint():
		###################################################################
		# NON-Signal Input Actions
		###################################################################
		# Quit game
		if event.is_action_pressed("quit"):
			HexLog.print_multiline_banner_with_text("Quitting Game")
			get_tree().quit()

		###################################################################
		# DEBUG Input Actions
		###################################################################
		# ...
