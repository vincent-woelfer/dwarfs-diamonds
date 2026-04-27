@icon("res://assets/class_icons/MousePointer.svg")
class_name MousePointer
extends Node2D


# Scene Components - Visual
@onready var mouse_pointer_sprite: Sprite2D = $MousePointerSprite
@onready var building_preview: BuildingPreview = $BuildingPreview

# Scene Components - Functional compinents
@onready var mining_comp: MiningComponent = $MiningComponent

# Mouse Pointer
var mouse_pointer_size: Vector2 = Vector2(32, 32)

var mouse_pointer_texture_normal: Texture2D = preload("res://assets/vector_graphics/MousePointerNormal.svg") as Texture2D
var mouse_pointer_texture_building_destroy: Texture2D = preload("res://assets/vector_graphics/MousePointerBuildingDestroy.svg") as Texture2D

# Variables
var selection_pattern: GridPatternRes

# Current & Previous selected cells - for normal mode
var curr_selected_cells: Array[Cell] = []
var prev_selected_cells: Array[Cell] = []

# Current & Previous center cell under mouse - for other modes & basic functionality.
# Update in _follow_mouse_pointer()
var curr_center_cell: Cell = null
var prev_center_cell: Cell = null

# State machine
enum State {NEUTRAL, BUILDING_PLACEMENT, BUILDING_DESTROY}
var sm: StateMachine
func _physics_process(delta: float) -> void:
	sm.physics_process(delta)


func _ready() -> void:
	sm = StateMachine.new(self , State, State.NEUTRAL)

	self.z_index = Enum.ZIndex.UI_MOUSE_POINTER

	# Default selection pattern is single cell
	selection_pattern = GridPatternRes.new([Vector2i.ZERO])

	# SIGNALS
	# ...


########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################

###################################
# Neutral State
###################################
func _enter_neutral() -> void:
	_set_mouse_pointer_sprite(mouse_pointer_texture_normal)
	mouse_pointer_sprite.visible = true

func _exit_neutral() -> void:
	mouse_pointer_sprite.visible = false

	# Deselect all cells
	for cell in curr_selected_cells:
		cell.set_is_highlighted(false)

	prev_selected_cells.clear()
	curr_selected_cells.clear()

func _physics_process_neutral(delta: float) -> void:
	# Check for mode change first, if so return
	if _actions_mode_change():
		return

	# Actions
	_follow_mouse_pointer()
	_update_selected_cells()
	_actions_neutral()

###################################
# Building Placement State
###################################
func _enter_building_placement(building_data: BuildingDataRes) -> void:
	building_preview.set_building_data(building_data)

func _exit_building_placement() -> void:
	building_preview.set_building_data(null)

func _physics_process_building_placement(delta: float) -> void:
	# Check for mode change first, if so return
	if _actions_mode_change():
		return
	
	# Actions
	_follow_mouse_pointer()
	_actions_building_placement()


###################################
# Building Destroy State
###################################
func _enter_building_destroy() -> void:
	_set_mouse_pointer_sprite(mouse_pointer_texture_building_destroy)
	mouse_pointer_sprite.visible = true

func _exit_building_destroy() -> void:
	mouse_pointer_sprite.visible = false

	# Deselect all buildings highlighted for destruction
	_unhighlight_all_buildings()

func _physics_process_building_destroy(delta: float) -> void:
	# Check for mode change first, if so return
	if _actions_mode_change():
		return
	
	# Actions
	_follow_mouse_pointer()
	_highlight_buildings_under_mouse_for_destruction()
	_actions_building_destroy()


########################################################################################################################
# ACTIONS PER STATE
########################################################################################################################
func _follow_mouse_pointer() -> void:
	self.position = Global.camera.mouse_pos_world_space()

	prev_center_cell = curr_center_cell
	curr_center_cell = Global.level.sample_cell_at_world_pos(self.global_position)

# TODO implement dynamic list of buildings, e.g. wheel to select or something. For now just hotkeys
func _actions_mode_change() -> bool:
	if Input.is_action_just_pressed("mouse_neutral"):
		sm.transition_to(State.NEUTRAL)
		return true

	# PLACE BUILDINGS
	elif Input.is_action_just_pressed("mouse_place_building_ladder"):
		sm.transition_to(State.BUILDING_PLACEMENT, Util.get_building_data(Enum.BuildingType.LADDER))
		return true

	elif Input.is_action_just_pressed("mouse_place_building_outpost"):
		sm.transition_to(State.BUILDING_PLACEMENT, Util.get_building_data(Enum.BuildingType.OUTPOST))
		return true

	elif Input.is_action_just_pressed("mouse_place_platform"):
		if building_preview.building_data.type == Enum.BuildingType.PLATFORM_BRIDGE:
			sm.transition_to(State.BUILDING_PLACEMENT, Util.get_building_data(Enum.BuildingType.PLATFORM_BLOCKING))
		elif building_preview.building_data.type == Enum.BuildingType.PLATFORM_BLOCKING:
			sm.transition_to(State.BUILDING_PLACEMENT, Util.get_building_data(Enum.BuildingType.PLATFORM_BRIDGE))
		else:
			# Default
			sm.transition_to(State.BUILDING_PLACEMENT, Util.get_building_data(Enum.BuildingType.PLATFORM_BLOCKING))

		return true

	# DESTROY
	elif Input.is_action_just_pressed("mouse_building_destroy"):
		sm.transition_to(State.BUILDING_DESTROY)
		return true

	return false


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


func _actions_building_placement() -> void:
	var ctrl_pressed: bool = Input.is_physical_key_pressed(KEY_CTRL)

	# Place Building - Normal - NO CTRL
	if Input.is_action_just_pressed("mouse_left") and not ctrl_pressed:
		building_preview.attempt_to_place_preview_building(false)

	# Mouse Placement with instant building (for testing) - CTRL
	if Input.is_action_just_pressed("mouse_left") and ctrl_pressed:
		building_preview.attempt_to_place_preview_building(true)


func _actions_building_destroy() -> void:
	# Destroy Building
	if Input.is_action_just_pressed("mouse_left"):
		if curr_center_cell != null:
			for building in curr_center_cell.get_buildings():
				Actions.remove_building(building)


########################################################################################################################
# INTERNAL METHODS
########################################################################################################################

## Called continously in building destroy mode
func _highlight_buildings_under_mouse_for_destruction() -> void:
	# Hightlight current
	if curr_center_cell != null:
		for building in curr_center_cell.get_buildings():
			building.set_modulate_external(Colors.building_modulate_external_destroy)

	# Un-highlight previous ONLY IF different from current
	if prev_center_cell != null and prev_center_cell != curr_center_cell:
		for building in prev_center_cell.get_buildings():
			building.set_modulate_external(Color.WHITE)


## Called when exiting building destroy mode
func _unhighlight_all_buildings() -> void:
	# Un-highlight current & previous
	if curr_center_cell != null:
		for building in curr_center_cell.get_buildings():
			building.set_modulate_external(Color.WHITE)

	if prev_center_cell != null:
		for building in prev_center_cell.get_buildings():
			building.set_modulate_external(Color.WHITE)

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
			cell.set_is_highlighted(false)

	# Select current
	for cell in curr_selected_cells:
		cell.set_is_highlighted(true)

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
	var cell := Global.level.sample_cell_at_world_pos(world_pos)
	Util.array_append_unique_not_null(selected_cells, cell)

	# Apply pattern
	for offset: Vector2i in selection_pattern.get_positions():
		if offset == Vector2i.ZERO:
			continue

		cell = Global.level.sample_cell_at_world_pos(world_pos + (offset as Vector2) * Global.CELL_SIZE)
		Util.array_append_unique_not_null(selected_cells, cell)

	return selected_cells


func _set_mouse_pointer_sprite(texture: Texture2D) -> void:
	mouse_pointer_sprite.texture = texture
	mouse_pointer_sprite.scale = mouse_pointer_size / texture.get_size()
