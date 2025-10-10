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


# Methods
func _init(_grid_pos: Vector2i, _type: Enum.CellType, _is_solid: bool) -> void:
	self.process_priority = Enum.ProcessPriority.CELL

	self.grid_pos = _grid_pos
	self.type = _type
	self.is_solid = _is_solid

	self.is_highlighted = false
	self.is_selected = false
	self.mining_process = 0.0
	
	has_ladder = randf() < 0.1 if is_solid else false

	
func _ready() -> void:
	# Required for chilren to be able to use these layers
	self.visibility_layer = Util.LAYER_1 | Util.LAYER_2

	visual = CellVisuals.new(self)
	add_child(visual)


func _process(delta: float) -> void:
	# TODO add dirty flag here? -> Benchmark
	# For now just update every time every frame
	update()
	

## Called for every cell every frame.
## Called before Nav updates connections
func update() -> void:
	pass
	# Used to have update of flags here but they are derived directly now


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
# Utility
########################################################################
func get_neighbour(grid_offset: Vector2i) -> Cell:
	assert(Util.are_neighbours(Vector2i(0, 0), grid_offset))
	return Global.level.get_cell(grid_pos + grid_offset)

func get_nav_id() -> int:
	return Util.hash(grid_pos)
