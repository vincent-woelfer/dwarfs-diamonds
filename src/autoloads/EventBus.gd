# No class_name here, the name of the singleton is set in the autoload
extends Node

###################################
# GAMEPLAY SIGNALS
###################################
signal Signal_DebugPathSetStartCell(pos: Vector2i)

signal Signal_NavUpdated() # Emitted when the nav grid has been updated

# This is only for the one "central" cell
signal Signal_MouseHoveredCellChanged(hovered_cell: Cell)


## Emitted in Actions.destroy_cell after cell is destroyed
signal Signal_GlobalCellDestroyed(destroyed_cell: Cell)


###################################
# DEV TOOLS SIGNALS
# SIGNALS DIRECTLY FROM INPUT KEYS (default key as comment behind signal)
###################################
signal Signal_DevToogleLight(is_light_on: bool) # F3
var dev_light_on: bool = true

# No Signal required
signal Signal_DevToogleDrawBuildingPattern() # F4
var dev_draw_building_patterns: bool = false


func _ready() -> void:
	pass
	# Actual signal connection is done in the code catching the signal like this:
	# EventBus.Signal_XXX.connect(_on_Signal_XXX)

	# Signal emitting is done like this:
	# EventBus.Signal_XXX.emit(...)

	###################################
	# Connect signals here to enable logging functions below.
	###################################


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toogle_light"):
		dev_light_on = not dev_light_on
		Signal_DevToogleLight.emit(dev_light_on)

	if event.is_action_pressed("dev_toogle_building_draw"):
		dev_draw_building_patterns = not dev_draw_building_patterns
		Signal_DevToogleDrawBuildingPattern.emit()


###################################
# Event bus logging functions
###################################

# func _on_Signal_XXX() -> void:
# 	print(...)
