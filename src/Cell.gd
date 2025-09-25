@tool
class_name Cell
extends Node2D

var shader_material: ShaderMaterial = preload("res://assets/materials/cell_selection_material.tres")

# Variables
enum CellType {
	A,
	B,
	C
}

var type: CellType
var grid_pos: Vector2i
var is_solid: bool
# var pos: Vector2

var background_poly: Polygon2D
var occluder: LightOccluder2D
var occluder_poly: OccluderPolygon2D

# Methods

func _init(_grid_pos: Vector2i, _type: CellType) -> void:
	self.grid_pos = _grid_pos
	self.type = _type

	self.is_solid = randf() <= 0.3


func _ready() -> void:
	# Background
	background_poly = Polygon2D.new()
	background_poly.polygon = _get_cell_polygon(grid_pos.x, grid_pos.y)
	background_poly.color = Colors.get_cell_color(type, is_solid)

	background_poly.material = shader_material.duplicate(true)
	
	if is_solid:
		background_poly.light_mask = 0
	# background_poly.vertex_colors = _get_cell_colors()
	add_child(background_poly)

	# Light Occluder
	if is_solid:
		occluder_poly = OccluderPolygon2D.new()
		occluder_poly.polygon = background_poly.polygon
		occluder_poly.closed = true
		occluder_poly.cull_mode = OccluderPolygon2D.CULL_DISABLED

		occluder = LightOccluder2D.new()
		occluder.occluder = occluder_poly
		add_child(occluder)

	#####
	if randf() <= 0.5:
		var mat: ShaderMaterial = background_poly.material
		mat.set_shader_parameter("highlight", true)


func _get_cell_colors() -> PackedColorArray:
	var base_color := Colors.rand_color()
	var _color_variation := 0.1

	var colors: PackedColorArray = []
	for i in range(8):
		colors.append(base_color)

	# for i in range(8):
		# var r = clamp(base_color.r + randf_range(-color_variation, color_variation), 0.0, 1.0)
		# var g = clamp(base_color.g + randf_range(-color_variation, color_variation), 0.0, 1.0)
		# var b = clamp(base_color.b + randf_range(-color_variation, color_variation), 0.0, 1.0)
		# colors.append(Color(r, g, b, 1.0))

	return colors

# Returns a rectangle polygon for cell at grid position (x, y)
func _get_cell_polygon(x: int, y: int) -> PackedVector2Array:
	# 4 Corners
	var top_left := Vector2(x * Global.CELL_SIZE, y * Global.CELL_SIZE)
	var top_right := top_left + Vector2(Global.CELL_SIZE, 0)
	var bot_right := top_left + Global.CELL_SIZE_VEC
	var bot_left := top_left + Vector2(0, Global.CELL_SIZE)

	# 4 Sides
	var top := (top_left + top_right) * 0.5
	var right := (top_right + bot_right) * 0.5
	var bot := (bot_right + bot_left) * 0.5
	var left := (bot_left + top_left) * 0.5

	# Offset
	var max_corner_offset := Global.CELL_SIZE * 0.1
	var max_side_offset := Global.CELL_SIZE * 0.125

	top_left += Util.rand_circular_offset(top_left, max_corner_offset)
	top_right += Util.rand_circular_offset(top_right, max_corner_offset)
	bot_right += Util.rand_circular_offset(bot_right, max_corner_offset)
	bot_left += Util.rand_circular_offset(bot_left, max_corner_offset)
	top += Util.rand_circular_offset(top, max_side_offset)
	right += Util.rand_circular_offset(right, max_side_offset)
	bot += Util.rand_circular_offset(bot, max_side_offset)
	left += Util.rand_circular_offset(left, max_side_offset)

	# Clockwise, starting from top-left
	return PackedVector2Array([top_left, top, top_right, right, bot_right, bot, bot_left, left])
