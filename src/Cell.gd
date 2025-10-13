class_name Cell
extends Node2D

# Variables
var type: Enum.CellType
var grid_pos: Vector2i


# GROUND TRUTH BOOL STATUS FLAGS
var is_solid: bool
var has_ladder: bool

# DERIVED STATUS FLAGS
#...


# OTHER FLAGS
# Red stripes, used for destruction marked
var is_highlighted: bool = false
# Yellow overlay, used for selection
var is_selected: bool = false

var mining_process: float = 0.0

var visual: CellVisuals


########################################################################
# PUBLIC METHODS
########################################################################
func queue_nav_update() -> void:
	# Update all neighbours. Self not needed as its implicitly updated when neighbour updates
	for n: Vector2i in Util.neighbours_all:
		var n_grid_pos: Vector2i = grid_pos + n
		Global.level.nav.update_cell(n_grid_pos)


func destroy() -> void:
	if not is_solid:
		return

	is_solid = false
	has_ladder = false
	mining_process = 0.0
	if grid_pos.y <= Global.SKY_HEIGHT:
		type = Enum.CellType.SKY

	queue_nav_update()


func build_platform() -> void:
	if is_solid:
		return

	is_solid = true
	has_ladder = false
	type = Enum.CellType.BUILDING
	mining_process = 0.0
	
	queue_nav_update()


func build_ladder() -> void:
	if is_solid:
		return

	has_ladder = true
	queue_nav_update()


func destroy_ladder() -> void:
	has_ladder = false
	queue_nav_update()

########################################################################
# Derived Status Flags
########################################################################
# Passable = not solid and not other obstacle. Does not require ladder or similar.
# Basically means "free air"
func is_passable() -> bool:
	return not is_solid


# Standable = solid ground or ladder. Can stand on it. Also requires passable
func is_standable() -> bool:
	if not is_passable():
		return false

	var n_bot := get_neighbour(Vector2i(0, 1))

	return (has_ladder) or (n_bot and n_bot.is_solid)


########################################################################
# PRIVATE METHODS
########################################################################
func _init(_grid_pos: Vector2i, _type: Enum.CellType, _is_solid: bool) -> void:
	self.process_priority = Enum.ProcessPriority.CELL

	self.grid_pos = _grid_pos
	self.type = _type
	self.is_solid = _is_solid

	self.is_highlighted = false
	self.is_selected = false
	self.mining_process = 0.0
	
	# dev - random ladder
	has_ladder = randf() < 0.1 if (!is_solid and type != Enum.CellType.SKY) else false

	
func _ready() -> void:
	# Required for chilren to be able to use these layers
	self.visibility_layer = Util.LAYER_1 | Util.LAYER_2

	visual = CellVisuals.new(self)
	add_child(visual)


########################################################################
# Utility
########################################################################
func get_neighbour(grid_offset: Vector2i) -> Cell:
	assert(Util.are_neighbours(Vector2i(0, 0), grid_offset))
	return Global.level.get_cell(grid_pos + grid_offset)


func get_nav_id() -> int:
	return Util.hash(grid_pos)
