# No class_name here, the name of the singleton is set in the autoload
extends Node

########################################################################################################################
# GAMEPLAY SIGNALS
########################################################################################################################
signal Signal_DebugPathSetStartCell(pos: Vector2i)

signal Signal_NavUpdated() # Emitted when the nav grid has been updated

# This is only for the one "central" cell
signal Signal_MouseHoveredCellChanged(hovered_cell: Cell)

## Emitted in Actions.destroy_cell after cell is destroyed
signal Signal_GlobalCellDestroyed(destroyed_cell: Cell)


########################################################################################################################
# DEV TOOLS SIGNALS
# SIGNALS DIRECTLY FROM INPUT KEYS (default key as comment behind signal)
########################################################################################################################
# F1
signal Signal_DevToogleNavDraw()
var dev_draw_nav: bool = false

# F2
signal Signal_DevToogleJobsDraw()
var dev_draw_jobs: bool = true

# F3
signal Signal_DevToogleLight()
var dev_light_on: bool = true

# F4
signal Signal_DevToogleDrawBuildingPattern()
var dev_draw_building_patterns: bool = false

# F5
signal Signal_DevToogleDrawActionPoints()
var dev_draw_action_points: bool = true

# F6
signal Signal_DevToogleDwarfDrawInfo()
var dev_draw_dwarf_info: bool = true

# F12
signal Signal_DevToogleSunFastForward()
var dev_sun_fast_forward: bool = false


########################################################################################################################
# Handle DEV-Input here
########################################################################################################################
func _input(event: InputEvent) -> void:
	# F1
	if event.is_action_pressed("dev_toogle_nav_draw"):
		dev_draw_nav = not dev_draw_nav
		Signal_DevToogleNavDraw.emit()

	# F2
	if event.is_action_pressed("dev_toogle_jobs_draw"):
		dev_draw_jobs = not dev_draw_jobs
		Signal_DevToogleJobsDraw.emit()

	# F3
	if event.is_action_pressed("dev_toogle_light"):
		dev_light_on = not dev_light_on
		Signal_DevToogleLight.emit()

	# F4
	if event.is_action_pressed("dev_toogle_building_draw"):
		dev_draw_building_patterns = not dev_draw_building_patterns
		Signal_DevToogleDrawBuildingPattern.emit()

	# F5
	if event.is_action_pressed("dev_toogle_action_point_draw"):
		dev_draw_action_points = not dev_draw_action_points
		Signal_DevToogleDrawActionPoints.emit()

	# F6
	if event.is_action_pressed("dev_toogle_dwarf_draw_info"):
		dev_draw_dwarf_info = not dev_draw_dwarf_info
		Signal_DevToogleDwarfDrawInfo.emit()
	
	# F12
	if event.is_action_pressed("dev_toogle_sun_fast_forward"):
		dev_sun_fast_forward = not dev_sun_fast_forward
		Signal_DevToogleSunFastForward.emit()

########################################################################################################################
# READY
########################################################################################################################
func _ready() -> void:
	pass
	# Actual signal connection is done in the code catching the signal like this:
	# EventBus.Signal_XXX.connect(_on_Signal_XXX)

	# Signal emitting is done like this:
	# EventBus.Signal_XXX.emit(...)

	###################################
	# Connect signals here to enable logging functions below.
	###################################
	
########################################################################################################################
# Event bus logging functions
########################################################################################################################

# func _on_Signal_XXX() -> void:
# 	print(...)
