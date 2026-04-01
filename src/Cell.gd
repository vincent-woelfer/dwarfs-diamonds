class_name Cell
extends Node2D

# Variables
var type: Enum.CellType
var grid_pos: Vector2i
var visual: CellVisuals

var deco_elements: Array[DecoBase] = []
var buildings: Array[BuildingBase] = []
var action_points: Array[ActionPoint] = []

var has_mineral: bool = false

# 0  = air / not solid
# 1  = adjacent to air
# 2+ = deeper underground, higher means darker
var light_depth: int = 999

########################################################################################################################
# GROUND TRUTH BOOL STATUS FLAGS
########################################################################################################################
var is_solid: bool

########################################################################################################################
# Derived State Flags
########################################################################################################################
# Passable = not solid and not other obstacle. Does not require ladder or similar.
# Basically means "free air"
func is_passable() -> bool:
	return not is_solid and not is_blocked


# Standable = solid ground or ladder. Can stand on it. Also requires passable
func is_standable(can_use_ladders: bool = true) -> bool:
	if not is_passable():
		return false

	var n_bot := get_neighbour(Global.VEC_DOWN)

	if can_use_ladders:
		return (has_ladder()) or (n_bot and n_bot.is_solid)
	else:
		return n_bot and n_bot.is_solid

# Solid Ground = solid cell below. Required e.g. for construction
func has_solid_ground() -> bool:
	var n_bot := get_neighbour(Global.VEC_DOWN)
	return n_bot != null and n_bot.is_solid


func has_ladder() -> bool:
	for building in buildings:
		if building.building_data.type == BuildingDataRes.Type.LADDER and building.is_complete:
			return true
	return false


# Blocked = has a non-complete platform blocking building
func is_blocked() -> bool:
	for building in buildings:
		if building.building_data.type == BuildingDataRes.Type.PLATFORM_BLOCKING and not building.is_complete:
			return true
	return false

########################################################################################################################
# OTHER FLAGS
########################################################################################################################
# Red stripes, used for marked for mining
var is_marked_for_mining: bool = false

# Yellow overlay, used for selection
var is_highlighted: bool = false

# Always between 0.0 and 1.0
var mining_process: float = 0.0

# multiplier for mining speed. Higher means harder to mine. For default miner (speed=1), equals seconds to mine.
var mining_hardness: float = 1.0


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func queue_nav_update() -> void:
	# Update all neighbours. Self not needed as its implicitly updated when neighbour updates
	for n: Vector2i in Util.neighbours_all:
		var n_grid_pos: Vector2i = grid_pos + n
		Global.level.nav_manager.queue_update_cell(n_grid_pos)


func set_is_highlighted(highlighted: bool) -> void:
	is_highlighted = highlighted
	visual.set_dirty()


func increase_mining_process(mining_speed_with_delta: float) -> void:
	var mining_with_hardness := mining_speed_with_delta / mining_hardness
	mining_process = clamp(mining_process + mining_with_hardness, 0.0, 1.0)
	visual.set_dirty()

	if mining_process >= 1.0:
		# This in turn emits Signal_GlobalCellMiningCompleted which this and all other MiningComponents listen to
		Actions.destroy_cell(self ) # calls destroy_cell()

## Destroy cell itself (terrain)
func destroy_cell() -> void:
	if not is_solid:
		return

	is_solid = false
	mining_process = 0.0
	if grid_pos.y <= Global.SKY_HEIGHT:
		type = Enum.CellType.SKY

	queue_nav_update()
	Audio.play_at_pos("cell_on_destroy", global_position)
	visual.set_dirty()

	# Spawn Rubble
	Global.level.spawn_rubble(grid_pos)

	if has_mineral:
		Global.level.spawn_gemstone(grid_pos)


###################################
# Building Management - Called by Global Actions add/remove building
###################################
func add_building(building: BuildingBase) -> void:
	if building in buildings:
		return

	buildings.append(building)
	visual.set_dirty()
	queue_nav_update()

func remove_building(building: BuildingBase) -> void:
	if building not in buildings:
		return

	buildings.erase(building)
	visual.set_dirty()
	queue_nav_update()


###################################
# Action Point Management (added/removed ONLY by BuildingManager)
###################################
func add_action_point(action_point: ActionPoint) -> void:
	if action_point in action_points:
		return
	action_points.append(action_point)

func remove_action_point(action_point: ActionPoint) -> void:
	action_points.erase(action_point)

func get_action_points_of_type(ap_type: ActionPoint.ActionType) -> Array[ActionPoint]:
	var result: Array[ActionPoint] = []
	for ap in action_points:
		if ap.type == ap_type and ap.is_active:
			result.append(ap)
	return result

###################################
## Returns true when state changed
func set_marked_for_mining(should_mine: bool) -> bool:
	# Dont do anything if no change
	if is_marked_for_mining == should_mine:
		return false

	# Cant set non-solid cells for mining
	if not is_solid and should_mine:
		return false

	is_marked_for_mining = should_mine
	visual.set_dirty()
	return true


## For now always torch
func add_deco_element(new_deco: DecoBase) -> void:
	if not deco_elements.is_empty():
		return

	new_deco.place_in_cell(self )
	deco_elements.append(new_deco)
	add_child(new_deco)
	visual.set_dirty()


## Returns a single poly point in world-space absolute
func get_poly_point(point: Enum.PolyPoint) -> Vector2:
	return visual.get_poly_point(point) + global_position

## Returns the center floor point in world-space absolute
func get_floor_point() -> Vector2:
	return get_poly_point(Enum.PolyPoint.BOT)


## Returns floor point at given world-space x, interpolated over BOT_LEFT -> BOT -> BOT_RIGHT
func get_floor_point_at_world_x(world_x: float) -> Vector2:
	var left: Vector2 = get_poly_point(Enum.PolyPoint.BOT_LEFT)
	var mid: Vector2 = get_poly_point(Enum.PolyPoint.BOT)
	var right: Vector2 = get_poly_point(Enum.PolyPoint.BOT_RIGHT)

	# Even if outside cell, code below correctly clamps to edges of cell floor
	if world_x <= mid.x:
		var t: float = inverse_lerp(left.x, mid.x, world_x)
		t = clampf(t, 0.0, 1.0)
		return lerp(left, mid, t)
	else:
		var t: float = inverse_lerp(mid.x, right.x, world_x)
		t = clampf(t, 0.0, 1.0)
		return lerp(mid, right, t)


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _init(_grid_pos: Vector2i, _type: Enum.CellType, _is_solid: bool) -> void:
	self.process_priority = Enum.ProcessPriority.CELL

	self.grid_pos = _grid_pos
	self.type = _type
	self.is_solid = _is_solid

	self.is_marked_for_mining = false
	self.is_highlighted = false
	self.mining_process = 0.0

	#TODO DEV
	self.has_mineral = (randf() < 0.2) if type != Enum.CellType.SKY else false
	
	# mining hardness
	mining_hardness = Global.CellMiningHardness.get(type, mining_hardness)


func _ready() -> void:
	# Required for chilren to be able to use these layers
	self.visibility_layer = Util.LAYER_1 | Util.LAYER_2

	visual = CellVisuals.new(self )
	add_child(visual)


func _to_string() -> String:
	var print_color := Colors.to_print_color(Color.BROWN)
	return Util.color_string("Cell(pos=%s, type=%s)" % [grid_pos, Enum.to_str(Enum.CellType, type)], print_color)
	

########################################################################################################################
# Utility
########################################################################################################################
func get_neighbour(grid_offset: Vector2i) -> Cell:
	assert(Util.are_neighbours(Vector2i(0, 0), grid_offset))
	return Global.level.get_cell(grid_pos + grid_offset)

func get_cell_relative(grid_offset: Vector2i) -> Cell:
	return Global.level.get_cell(grid_pos + grid_offset)

func get_nav_id() -> int:
	return Util.hash(grid_pos)
