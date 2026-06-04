# No class_name here, the name of the singleton is set in the autoload
@tool
extends Node

########################################################################################################################
# GAMEPLAY SIGNALS
########################################################################################################################
## Emitted by NavManager when the nav grid has been updated
## Includes is_solid changes + ladders
signal Signal_NavUpdated()

## Emitted by Level when the light caluclation was updated (as result of is_solid changes)
signal Signal_LightDepthUpdated()

## Emitted in Actions.destroy_cell after cell is destroyed
signal Signal_CellDestroyed(destroyed_cell: Cell)

# This is only for the one "central" cell
signal Signal_MouseHoveredCellChanged(hovered_cell: Cell)

## Send when placement-check data is updated and ALL cells should refresh their visuals
signal Signal_TriggerVisualUpdateAllCells()


########################################################################################################################
# DEV TOOLS SIGNALS
# SIGNALS DIRECTLY FROM INPUT KEYS (default key as comment behind signal)
########################################################################################################################
# F1
signal Signal_DevToggleNavDraw()
var dev_draw_nav: bool = false

# F2
signal Signal_DevToggleJobsDraw()
var dev_draw_jobs: bool = false

# F3
signal Signal_DevToggleLight()
var dev_light_on: bool = false

# F4
signal Signal_DevToggleDrawBuildingPattern()
var dev_draw_building_patterns: bool = false

# F5
signal Signal_DevToggleDrawActionPoints()
var dev_draw_action_points: bool = false

# F6
signal Signal_DevToggleDwarfDrawInfo()
var dev_draw_dwarf_info: bool = false

# F12
signal Signal_DevToggleSunFastForward()
var dev_sun_fast_forward: bool = false

signal Signal_DebugPathSetStartCell(pos: Vector2i)


########################################################################################################################
# Handle DEV-Input here
########################################################################################################################
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	# F1
	if event.is_action_pressed("dev_toggle_nav_draw"):
		dev_draw_nav = not dev_draw_nav
		Signal_DevToggleNavDraw.emit()

	# F2
	if event.is_action_pressed("dev_toggle_jobs_draw"):
		dev_draw_jobs = not dev_draw_jobs
		Signal_DevToggleJobsDraw.emit()

	# F3
	if event.is_action_pressed("dev_toggle_light"):
		dev_light_on = not dev_light_on
		Signal_DevToggleLight.emit()

	# F4
	if event.is_action_pressed("dev_toggle_building_draw"):
		dev_draw_building_patterns = not dev_draw_building_patterns
		Signal_DevToggleDrawBuildingPattern.emit()

	# F5
	if event.is_action_pressed("dev_toggle_action_point_draw"):
		dev_draw_action_points = not dev_draw_action_points
		Signal_DevToggleDrawActionPoints.emit()

	# F6
	if event.is_action_pressed("dev_toggle_dwarf_draw_info"):
		dev_draw_dwarf_info = not dev_draw_dwarf_info
		Signal_DevToggleDwarfDrawInfo.emit()
	
	# F11
	if event.is_action_pressed("dev_dwarf_drop_all_items"):
		for dwarf: Dwarf in Global.level.dwarfs:
			dwarf.storage_comp.drop_all()

	# F12
	if event.is_action_pressed("dev_toggle_sun_fast_forward"):
		dev_sun_fast_forward = not dev_sun_fast_forward
		Signal_DevToggleSunFastForward.emit()


########################################################################################################################
# READY
########################################################################################################################

########################################################################################################################
# READY
########################################################################################################################
func _ready() -> void:
	self.process_priority = Enum.ProcessPriority.EVENT_BUS
	
	
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
