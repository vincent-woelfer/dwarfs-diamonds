class_name CellVisuals
extends Node2D

# Parent Cell
var c: Cell

# Material
var unshaded_material: CanvasItemMaterial = preload("res://assets/materials/unshaded_material.tres")

var cell_global_texture_shader: ShaderMaterial = preload("res://assets/materials/cell_global_texture_material.tres")
var sky_global_texture_shader: ShaderMaterial = preload("res://assets/materials/sky_global_texture_material.tres")

# Polygons
var background_poly: Polygon2D
var stencil_poly: Polygon2D
var mineral_poly: Polygon2D

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

	###################################
	# Background Polygon
	###################################
	background_poly = Polygon2D.new()
	background_poly.polygon = poly_points
	background_poly.visibility_layer = Util.LAYER_1

	# Add material
	if c.type != Enum.CellType.SKY:
		background_poly.material = cell_global_texture_shader
	else:
		background_poly.material = sky_global_texture_shader
	# with shader sky does not get dark at night
	# if c.type == Enum.CellType.SKY:
		# background_poly.material = unshaded_material
		
	add_child(background_poly)

	###################################
	# Mineral Polygon
	###################################
	var mineral_texture: Texture2D = preload("res://assets/sprites/minerals_1.png")

	mineral_poly = Polygon2D.new()
	mineral_poly.polygon = poly_points
	mineral_poly.visibility_layer = Util.LAYER_1
	# mineral_poly.material = unshaded_material # TODO glow material?
	mineral_poly.texture = mineral_texture

	mineral_poly.texture_scale = Vector2.ONE * 0.85
	mineral_poly.texture_offset = Vector2.ONE * -20.0
	# mineral_poly.texture_rotation = randf_range(0.0, 2.0 * PI)

	mineral_poly.modulate = [Color.ORANGE_RED, Color.DARK_VIOLET, Color.DARK_CYAN].pick_random()
	mineral_poly.modulate *= 2.0
	mineral_poly.modulate.a = 1.0
	
	# mineral_poly.uv = _get_cell_polygon(mineral_texture.get_size().x) # scale UVs to texture size
	add_child(mineral_poly)

	###################################
	# Stencil Polygon
	###################################
	stencil_poly = Polygon2D.new()
	stencil_poly.polygon = poly_points
	stencil_poly.color = Color(0.0, 0.0, 0.0, 0.0) if Engine.is_editor_hint() else Color(0.0, 0.0, 0.0, 1.0)
	stencil_poly.visibility_layer = Util.LAYER_2
	stencil_poly.material = unshaded_material
	add_child(stencil_poly)

	###################################
	# Light Occluder
	###################################
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


func _process(delta: float) -> void:
	if dirty:
		dirty = false
		update()

	# TODO TEMP
	# 0  = air / not solid
	# 1  = adjacent to air
	# 2+ = deeper underground, higher means darker
	var mod_light_depth: Array[float] = [1.3, 0.4, 0.03, 0.0, 0.0]
	var light_depth_clamped := mod_light_depth[clamp(c.light_depth, 0, mod_light_depth.size() - 1)]

	background_poly.modulate = Color.WHITE * light_depth_clamped
	background_poly.modulate.a = 1.0

	mineral_poly.modulate.a = light_depth_clamped


func update() -> void:
	# VISUAL
	occluder.visible = c.is_solid

	# Change light mask if solid (no light passes through)
	background_poly.light_mask = 0 if c.is_solid else 1

	background_poly.color = Colors.get_cell_color(c.type)

	mineral_poly.visible = c.has_mineral and c.is_solid

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


# Returns a rectangle polygon for cell at grid position (x, y) in world-space RELATIVE TO CELL.
# Values range is [0, CELL_SIZE] + small random offset
func _get_cell_polygon(MAX_VAL: float = Global.CELL_SIZE) -> PackedVector2Array:
	var base: Vector2 = c.grid_pos * MAX_VAL

	# 4 Corners
	var top_left := Vector2.ZERO
	var top_right := Vector2(MAX_VAL, 0.0)
	var bot_right := Vector2(MAX_VAL, MAX_VAL)
	var bot_left := Vector2(0.0, MAX_VAL)

	# 4 Sides
	var top := (top_left + top_right) * 0.5
	var right := (top_right + bot_right) * 0.5
	var bot := (bot_right + bot_left) * 0.5
	var left := (bot_left + top_left) * 0.5

	# Deterministic-Random Offset
	var max_corner_offset := MAX_VAL * 0.1
	var max_side_offset := MAX_VAL * 0.125

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
