@tool
class_name Cell
extends Node2D

# Variables
var type: Global.CellType
var grid_pos: Vector2i

var is_solid: bool
# Red stripes, used for destruction marked
var is_highlighted: bool = false
# Yellow overlay, used for selection
var is_selected: bool = false

var mining_process: float = 0.0

var is_walkable: bool
var has_ladder: bool = false


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

	visual = CellVisuals.new(self)
	add_child(visual)
	

func _ready() -> void:
	# Required for chilren to be able to use these layers
	self.visibility_layer = Util.LAYER_1 | Util.LAYER_2

	
	# TODO most likely remove this, only required for editor preview
	# Move whats needed for initial construction elsewqhere.
	# process should be able to assume everything is ready (including neighbours)
	_process(0.0)


func _process(delta: float) -> void:
	# TODO add dirty flag here? -> Benchmark
	# For now just update every time every frame
	update()
	

func update_walkability(new_is_walkable: bool) -> void:
	if is_walkable == new_is_walkable:
		return

	is_walkable = new_is_walkable

	# TODO this if is a bit hacky, only reuqired at level construction. Find better way
	if Global.level and Global.level.nav:
		Global.level.nav._update_cell_walkability(self)


func update() -> void:
	# GAMEPLAY
	# TODO for now this doesnt work in editor because get_neighbour relies on Global.level (which is not correctly set in editor)
	if not Engine.is_editor_hint():
		var neighbour_below := get_neighbour(Vector2i(0, 1))
		update_walkability((not is_solid) and neighbour_below and neighbour_below.is_solid)


	visual.update()


func get_neighbour(dir: Vector2i) -> Cell:
	assert(dir.length() == 1 and (dir.x == 0 or dir.y == 0), "Direction must be a unit vector in cardinal direction")
	return Global.level.get_cell(grid_pos + dir)

	