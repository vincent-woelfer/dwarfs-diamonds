@icon("res://assets/class_icons/MousePointer.svg")
class_name MousePointer
extends Node2D


# Scene Components
@onready var visual_sprite: Node2D = $VisualSprite
@onready var mining_comp: MiningComponent = $MiningComponent
@onready var building_preview: BuildingPreview = $BuildingPreview


# Preloaded Building Data
var ladder_building_data: BuildingData = preload("res://scenes/buildings/LadderBuildingData.tres") as BuildingData
var base_building_data: BuildingData = preload("res://scenes/buildings/BaseBuildingData.tres") as BuildingData

# Variables
var selection_pattern: GridPattern

# Current & Previous selected cells
var curr_selected_cells: Array[Cell] = []
var prev_selected_cells: Array[Cell] = []

var curr_cell: Cell = null

# State machine
enum State {NEUTRAL, BUILDING_PLACEMENT}
var sm: StateMachine
func _physics_process(delta: float) -> void:
	sm.physics_process(delta)


func _ready() -> void:
	sm = StateMachine.new(self, State, State.NEUTRAL)

	self.z_index = Enum.ZIndex.MOUSE_POINTER

	# Default selection pattern is single cell
	selection_pattern = GridPattern.new([Vector2i.ZERO])

	# SIGNALS
	# ...


########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################

# Neutral State
func _enter_neutral() -> void:
	visual_sprite.visible = true

func _exit_neutral() -> void:
	visual_sprite.visible = false

	# Deselect all cells
	for cell in curr_selected_cells:
		cell.set_is_selected(false)

	prev_selected_cells.clear()
	curr_selected_cells.clear()

func _physics_process_neutral(delta: float) -> void:
	# Check for mode change first, if so return
	if _actions_mode_change():
		return

	_follow_mouse_pointer()

	_update_selected_cells()

	_actions_neutral()


# Not enter function since we need to call with new building data
func _transition_to_building_placement(building_data: BuildingData) -> void:
	building_preview.set_building_data(building_data)
	sm.transition_to(State.BUILDING_PLACEMENT)

func _exit_building_placement() -> void:
	building_preview.set_building_data(null)


func _physics_process_building_placement(delta: float) -> void:
	# Check for mode change first, if so return
	if _actions_mode_change():
		return
	
	_follow_mouse_pointer()

	_actions_building_placement()


########################################################################################################################
# ACTIONS
########################################################################################################################
func _follow_mouse_pointer() -> void:
	self.position = Global.camera.mouse_pos_world_space()
	curr_cell = Global.level.get_cell_at_world_pos(self.global_position)

func _actions_mode_change() -> bool:
	if Input.is_action_just_pressed("mouse_neutral"):
		sm.transition_to(State.NEUTRAL)
		return true

	elif Input.is_action_just_pressed("mouse_place_building_ladder"):
		_transition_to_building_placement(ladder_building_data)
		return true

	elif Input.is_action_just_pressed("mouse_place_building_base"):
		_transition_to_building_placement(base_building_data)
		return true

	return false


func _actions_building_placement() -> void:
	var ctrl_pressed: bool = Input.is_physical_key_pressed(KEY_CTRL)

	# Place Building - Normal - NO CTRL
	if Input.is_action_just_pressed("mouse_left") and not ctrl_pressed:
		building_preview.attempt_to_place_preview_building(false)

	# Mouse Placement with instant building (for testing) - CTRL
	if Input.is_action_just_pressed("mouse_left") and ctrl_pressed:
		building_preview.attempt_to_place_preview_building(true)


func _actions_neutral() -> void:
	# Mine Cells
	if Input.is_action_just_pressed("mouse_right"):
		for cell in curr_selected_cells:
			mining_comp.start_mining(cell)


	######## DEBUG ########
	if Input.is_action_just_pressed("dev_place_debug_path_start"):
		if curr_selected_cells.size() > 0:
			var cell := curr_selected_cells[0]
			EventBus.Signal_DebugPathSetStartCell.emit(cell.grid_pos)


## Update selected cells based on mouse position and selection pattern
func _update_selected_cells() -> void:
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


## Sample cells at mouse position. Guaranteed to not be null
## The Cell directly under the mouse MUST BE at index 0!
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

	return selected_cells
