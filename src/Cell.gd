class_name Cell
extends Node2D

# Variables
var type: Global.CellType
var grid_pos: Vector2i


# BOOL STATUS FLAGS
var is_solid: bool
var has_ladder: bool

# DERIVED STATUS FLAGS
# Walkable = not solid and has solid cell below
var is_walkable: bool


# OTHER FLAGS
# Red stripes, used for destruction marked
var is_highlighted: bool = false
# Yellow overlay, used for selection
var is_selected: bool = false


var mining_process: float = 0.0

var visual: CellVisuals


# Methods
func _init(_grid_pos: Vector2i, _type: Global.CellType, _is_solid: bool) -> void:
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
	

func update() -> void:
	# Get Neighbours
	var n_bot := get_neighbour(Vector2i(0, 1))


	# Update walkability
	var new_walkable := (not is_solid) and n_bot and n_bot.is_solid
	update_walkability(new_walkable)



func update_walkability(new_is_walkable: bool) -> void:
	if is_walkable == new_is_walkable:
		return

	self.is_walkable = new_is_walkable

	if Global.level and Global.level.nav:
		Global.level.nav.update_cell(self)





func get_neighbour(dir: Vector2i) -> Cell:
	assert(dir.length() == 1 and (dir.x == 0 or dir.y == 0), "Direction must be a unit vector in cardinal direction")
	return Global.level.get_cell(grid_pos + dir)
