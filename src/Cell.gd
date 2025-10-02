@tool
class_name Cell
extends Node2D

# Variables
enum CellType {
	A,
	B,
	C
}

var type: CellType
var grid_pos: Vector2i

var is_solid: bool
# Red stripes, used for destruction marked
var is_highlighted: bool = false
# Yellow overlay, used for selection
var is_selected: bool = false

var mining_process: float = 0.0

# Visuals
var background_poly: Polygon2D
var stencil_poly: Polygon2D

# Light / Shadows
var occluder: LightOccluder2D
var occluder_poly: OccluderPolygon2D

# Selection
# var collision_area: Area2D
# var collision_poly: CollisionPolygon2D


# Material
var unshaded_material: CanvasItemMaterial = preload("res://assets/materials/unshaded_material.tres")

# Methods
func _init(_grid_pos: Vector2i, _type: CellType, _is_solid: bool) -> void:
	self.grid_pos = _grid_pos
	self.type = _type
	self.is_solid = _is_solid

	self.is_highlighted = randf() < 0.05
	self.is_selected = false
	# self.mining_process = 0.1 if randf() < 0.2 else 0.0

func _ready() -> void:
	# Required for chilren to be able to use these layers
	self.visibility_layer = Util.LAYER_1 | Util.LAYER_2

	var poly := _get_cell_polygon()

	# Background
	background_poly = Polygon2D.new()
	background_poly.polygon = poly
	background_poly.color = Colors.get_cell_color(type, is_solid)
	background_poly.visibility_layer = Util.LAYER_1
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

	# # Collision (for selection)
	# collision_poly = CollisionPolygon2D.new()
	# collision_poly.polygon = poly
	# collision_area = Area2D.new()
	# collision_area.add_child(collision_poly)
	# collision_area.visible = false
	# add_child(collision_area)

	_process(0.0)


# TODO add dirty flag here? -> Benchmark
func _process(delta: float) -> void:
	occluder.visible = is_solid

	# Change light mask if solid (no light passes through)
	background_poly.light_mask = 0 if is_solid else 1

	background_poly.color = Colors.get_cell_color(type, is_solid)
	
	_encode_stencil_buffer()
	

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

	# BLUE channel
	stencil_poly.color.b8 = 0


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
