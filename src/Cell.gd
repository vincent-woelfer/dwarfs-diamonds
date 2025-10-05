@tool
class_name Cell
extends Node2D

# Variables
enum CellType {
	A,
	B,
	C,
	BUILDING,
	SKY
}

var type: CellType
var grid_pos: Vector2i

var is_solid: bool
# Red stripes, used for destruction marked
var is_highlighted: bool = false
# Yellow overlay, used for selection
var is_selected: bool = false

var mining_process: float = 0.0

var is_walkable: bool

# Visuals
var background_poly: Polygon2D
var stencil_poly: Polygon2D

# Light / Shadows
var occluder: LightOccluder2D
var occluder_poly: OccluderPolygon2D


# Material
var unshaded_material: CanvasItemMaterial = preload("res://assets/materials/unshaded_material.tres")

# Methods
func _init(_grid_pos: Vector2i, _type: CellType, _is_solid: bool) -> void:
	self.grid_pos = _grid_pos
	self.type = _type
	self.is_solid = _is_solid

	self.is_highlighted = false
	self.is_selected = false
	self.mining_process = 0.0

func _ready() -> void:
	# Required for chilren to be able to use these layers
	self.visibility_layer = Util.LAYER_1 | Util.LAYER_2

	var poly := _get_cell_polygon()

	# Background
	background_poly = Polygon2D.new()
	background_poly.polygon = poly
	background_poly.color = Colors.get_cell_color(type, is_solid)
	background_poly.visibility_layer = Util.LAYER_1
	if type == CellType.SKY:
		background_poly.material = unshaded_material
	add_child(background_poly)

	# Stencil
	stencil_poly = Polygon2D.new()
	stencil_poly.polygon = poly
	stencil_poly.color = Color(0.0, 0.0, 0.0, 0.0) if Engine.is_editor_hint() else Color(0.0, 0.0, 0.0, 1.0)
	stencil_poly.visibility_layer = Util.LAYER_2
	stencil_poly.material = unshaded_material
	add_child(stencil_poly)

	# Light Occluder
	occluder_poly = OccluderPolygon2D.new()
	occluder_poly.polygon = poly
	occluder_poly.closed = true
	occluder_poly.cull_mode = OccluderPolygon2D.CULL_DISABLED

	occluder = LightOccluder2D.new()
	occluder.occluder = occluder_poly
	add_child(occluder)

	# TODO most likely remove this, only required for editor preview
	# Move whats needed for initial construction elsewqhere.
	# process should be able to assume everything is ready (including neighbours)
	_process(0.0)


func _process(delta: float) -> void:
	# TODO add dirty flag here? -> Benchmark
	# For now just update every time every frame
	update()
	
	_encode_stencil_buffer()


func update_walkability(new_is_walkable: bool) -> void:
	if is_walkable == new_is_walkable:
		return

	is_walkable = new_is_walkable

	# TODO this if is a bit hacky, only reuqired at level construction. Find better way
	if Global.level and Global.level.pathfinding:
		Global.level.pathfinding._update_cell_walkability(self)


func update() -> void:
	# GAMEPLAY
	# TODO for now this doesnt work in editor because get_neighbour relies on Global.level (which is not correctly set in editor)
	if not Engine.is_editor_hint():
		var neighbour_below := get_neighbour(Vector2i(0, 1))
		update_walkability((not is_solid) and neighbour_below and neighbour_below.is_solid)

	# VISUAL
	occluder.visible = is_solid

	# Change light mask if solid (no light passes through)
	background_poly.light_mask = 0 if is_solid else 1

	background_poly.color = Colors.get_cell_color(type, is_solid)


func get_neighbour(dir: Vector2i) -> Cell:
	assert(dir.length() == 1 and (dir.x == 0 or dir.y == 0), "Direction must be a unit vector in cardinal direction")
	return Global.level.get_cell(grid_pos + dir)

	
# Set Stencil Colors. Dont write to alpha, this is done only once to show/hide stencil in editor vs game
func _encode_stencil_buffer() -> void:
	# Encode flags in RED channel
	stencil_poly.color.r8 = 0
	stencil_poly.color.r8 |= (1 << 0) if is_highlighted else 0
	stencil_poly.color.r8 |= (1 << 1) if is_solid else 0
	stencil_poly.color.r8 |= (1 << 2) if is_selected else 0

	# Encode numbers in GREEN channel
	stencil_poly.color.g8 = 0
	# Mining Process in 3 bits
	stencil_poly.color.g8 |= Util.encode_into_bits(mining_process, 0, 3)

	# BLUE channel - used for debugging
	stencil_poly.color.b8 = 0
	stencil_poly.color.b8 |= (1 << 6) if is_walkable else 0


# Returns a rectangle polygon for cell at grid position (x, y)
func _get_cell_polygon() -> PackedVector2Array:
	var base: Vector2 = Vector2(grid_pos.x * Global.CELL_SIZE, grid_pos.y * Global.CELL_SIZE)

	# 4 Corners
	var top_left := Vector2.ZERO
	var top_right := Vector2(Global.CELL_SIZE, 0)
	var bot_right := Global.CELL_SIZE_VEC
	var bot_left := Vector2(0, Global.CELL_SIZE)

	# 4 Sides
	var top := (top_left + top_right) * 0.5
	var right := (top_right + bot_right) * 0.5
	var bot := (bot_right + bot_left) * 0.5
	var left := (bot_left + top_left) * 0.5

	# Offset
	var max_corner_offset := Global.CELL_SIZE * 0.1
	var max_side_offset := Global.CELL_SIZE * 0.125

	top_left += Util.rand_circular_offset(base + top_left, max_corner_offset)
	top_right += Util.rand_circular_offset(base + top_right, max_corner_offset)
	bot_right += Util.rand_circular_offset(base + bot_right, max_corner_offset)
	bot_left += Util.rand_circular_offset(base + bot_left, max_corner_offset)
	top += Util.rand_circular_offset(base + top, max_side_offset)
	right += Util.rand_circular_offset(base + right, max_side_offset)
	bot += Util.rand_circular_offset(base + bot, max_side_offset)
	left += Util.rand_circular_offset(base + left, max_side_offset)

	# Clockwise, starting from top-left
	return PackedVector2Array([top_left, top, top_right, right, bot_right, bot, bot_left, left])
