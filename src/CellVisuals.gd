class_name CellVisuals
extends Node2D

# Parent Cell
var c: Cell

# Material
var unshaded_material: CanvasItemMaterial = preload("res://assets/materials/unshaded_material.tres")

var cell_global_texture_shader: ShaderMaterial = preload("res://assets/materials/cell_global_texture_material.tres")

var background_poly: Polygon2D
var stencil_poly: Polygon2D

var ladder_sprite: Sprite2D

# Light / Shadows
var occluder: LightOccluder2D
var occluder_poly: OccluderPolygon2D

# world-space RELATIVE TO CELL
var poly_points: PackedVector2Array

var dirty: bool

# Methods
func _init(_parent_cell: Cell) -> void:
	self.process_priority = Enum.ProcessPriority.CELL_VISUAL
	self.c = _parent_cell


func _ready() -> void:
	# Required for chilren to be able to use these layers
	self.visibility_layer = Util.LAYER_1 | Util.LAYER_2
	self.z_index = Enum.ZIndex.CELL

	poly_points = _get_cell_polygon()

	# Background
	background_poly = Polygon2D.new()
	background_poly.polygon = poly_points
	background_poly.visibility_layer = Util.LAYER_1

	# Add material
	if c.type != Enum.CellType.SKY:
		# var mat: ShaderMaterial = ShaderMaterial.new()
		# mat.shader = cell_global_texture_shader
		background_poly.material = cell_global_texture_shader
		

	# with shader sky does not get dark at night
	# if c.type == Enum.CellType.SKY:
		# background_poly.material = unshaded_material
		
	add_child(background_poly)

	# Stencil
	stencil_poly = Polygon2D.new()
	stencil_poly.polygon = poly_points
	stencil_poly.color = Color(0.0, 0.0, 0.0, 0.0) if Engine.is_editor_hint() else Color(0.0, 0.0, 0.0, 1.0)
	stencil_poly.visibility_layer = Util.LAYER_2
	stencil_poly.material = unshaded_material
	add_child(stencil_poly)

	# Light Occluder
	occluder_poly = OccluderPolygon2D.new()
	occluder_poly.polygon = poly_points
	occluder_poly.closed = true
	occluder_poly.cull_mode = OccluderPolygon2D.CULL_DISABLED

	occluder = LightOccluder2D.new()
	occluder.occluder = occluder_poly
	add_child(occluder)

	update()

func set_dirty() -> void:
	dirty = true


# dirty flag IS ONLY A PERFOCMANCE OPTIMIZATION -> ignore for now
func _process(delta: float) -> void:
	if Global.camera:
		cell_global_texture_shader.set_shader_parameter("zoom", Global.camera.zoom_curr)

	if dirty:
		dirty = false
		update()


func update() -> void:
	# VISUAL
	occluder.visible = c.is_solid

	# Change light mask if solid (no light passes through)
	background_poly.light_mask = 0 if c.is_solid else 1

	background_poly.color = Colors.get_cell_color(c.type, c.is_solid)

	_encode_stencil_buffer()


# Set Stencil Colors. Dont write to alpha, this is done only once to show/hide stencil in editor vs game
func _encode_stencil_buffer() -> void:
	# Encode flags in RED channel
	stencil_poly.color.r8 = 0
	stencil_poly.color.r8 |= (1 << 0) if c.is_marked_for_mining else 0
	stencil_poly.color.r8 |= (1 << 1) if c.is_solid else 0
	stencil_poly.color.r8 |= (1 << 2) if c.is_selected else 0

	# Encode numbers in GREEN channel
	stencil_poly.color.g8 = 0
	# Mining Process in 3 bits
	stencil_poly.color.g8 |= Util.encode_into_bits(c.mining_process, 0, 3)

	# BLUE channel - used for debugging
	stencil_poly.color.b8 = 0
	stencil_poly.color.b8 |= (1 << 6) if c.is_standable() else 0


## Returns a single poly point in world-space RELATIVE TO CELL
func get_poly_point(point: Enum.PolyPoint) -> Vector2:
	assert(poly_points.size() == 8)
	assert(point >= 0 and point < poly_points.size())
	return poly_points[point]


# Returns a rectangle polygon for cell at grid position (x, y) in world-space RELATIVE TO CELL
func _get_cell_polygon() -> PackedVector2Array:
	var base: Vector2 = c.grid_pos * Global.CELL_SIZE

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

	# Deterministic-Random Offset
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
