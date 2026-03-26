class_name CellVisuals
extends Node2D

# Parent Cell
var c: Cell

# Material
var unshaded_material: CanvasItemMaterial = preload("res://assets/materials/unshaded_material.tres")

var cell_global_texture_shader: ShaderMaterial = preload("res://assets/materials/cell_global_texture_material.tres")
var sky_global_texture_shader: ShaderMaterial = preload("res://assets/materials/sky_global_texture_material.tres")

var dummy_1x1_texture: Texture2D = preload("res://assets/textures/dummy_1x1.png")
var mineral_texture: Texture2D = preload("res://assets/sprites/minerals_1.png")

# Shadow Material
var shadow_material: ShaderMaterial = preload("res://assets/materials/CellShadow.tres")

# Polygons
var background_poly: Polygon2D
var stencil_poly: Polygon2D
var mineral_poly: Polygon2D
var shadow_poly: Polygon2D

# Light / Shadows
var occluder: LightOccluder2D
var occluder_poly: OccluderPolygon2D

# world-space RELATIVE TO CELL
var poly_points: PackedVector2Array
var uv_points: PackedVector2Array

var dirty: bool

# Methods
func _init(_parent_cell: Cell) -> void:
	self.process_priority = Enum.ProcessPriority.CELL_VISUAL
	self.c = _parent_cell


func _ready() -> void:
	# Required for chilren to be able to use these layers
	self.visibility_layer = Util.LAYER_1 | Util.LAYER_2
	self.z_index = Enum.ZIndex.CELL

	EventBus.Signal_LightDepthUpdated.connect(set_dirty)

	poly_points = _compute_cell_polygon()
	uv_points = _compute_cell_uvs()

	###################################
	# Background Polygon
	###################################
	background_poly = Polygon2D.new()
	background_poly.z_as_relative = true
	background_poly.z_index = 0
	background_poly.polygon = poly_points
	background_poly.uv = uv_points
	background_poly.visibility_layer = Util.LAYER_1

	# Add material
	if c.type == Enum.CellType.SKY:
		background_poly.material = sky_global_texture_shader		
	else:
		background_poly.material = cell_global_texture_shader
		background_poly.set_instance_shader_parameter("is_solid", c.is_solid)
		
	# with shader sky does not get dark at night
	# if c.type == Enum.CellType.SKY:
		# background_poly.material = unshaded_material
		
	add_child(background_poly)

	###################################
	# Mineral Polygon
	###################################
	mineral_poly = Polygon2D.new()
	mineral_poly.z_as_relative = true
	mineral_poly.z_index = 1
	mineral_poly.polygon = poly_points
	mineral_poly.uv = uv_points
	mineral_poly.visibility_layer = Util.LAYER_1
	# mineral_poly.material = unshaded_material # TODO glow material?
	mineral_poly.texture = mineral_texture

	mineral_poly.texture_scale = Vector2.ONE * 0.85
	mineral_poly.texture_offset = Vector2.ONE * -20.0
	# mineral_poly.texture_rotation = randf_range(0.0, 2.0 * PI)

	mineral_poly.modulate = [Color.ORANGE_RED, Color.DARK_VIOLET, Color.DARK_CYAN].pick_random()
	mineral_poly.modulate *= 2.0
	mineral_poly.modulate.a = 1.0
	
	add_child(mineral_poly)

	###################################
	# Shadow Polygon
	###################################
	shadow_poly = Polygon2D.new()
	shadow_poly.z_as_relative = true
	shadow_poly.z_index = 2
	shadow_poly.visibility_layer = Util.LAYER_1
	shadow_poly.polygon = poly_points
	shadow_poly.uv = uv_points
	shadow_poly.texture = dummy_1x1_texture

	# Set global colors
	shadow_material.set_shader_parameter("lit_color", Colors.LIT_CELL_COLOR)
	shadow_material.set_shader_parameter("fade_color", Colors.FADE_CELL_COLOR)
	# Would need to include canvas modulate here because shader sets the final value excluding canvas modulate.
	shadow_material.set_shader_parameter("unlit_color", Colors.UNLIT_CELL_COLOR)

	shadow_poly.material = shadow_material

	for i in range(8):
		shadow_poly.set_instance_shader_parameter("uvs_%d" % i, uv_points[i])

	
	add_child(shadow_poly)

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

	###################################
	# Finalize
	###################################
	_update()

func set_dirty() -> void:
	dirty = true


func _process(delta: float) -> void:
	if dirty:
		dirty = false
		_update()
		_update_light_depth_visuals()


func _update() -> void:
	# VISUAL
	occluder.visible = c.is_solid

	# Change light mask if solid (no light passes through)
	background_poly.light_mask = 0 if c.is_solid else 1
	background_poly.color = Colors.get_cell_color(c.type)

	# TODO change this for is solid AND especially change background texture (in cellGlobalTexture shader)
	if c.is_solid:
		background_poly.color *= Color(1.0, 1.0, 1.0, 1.0)

	# background_poly.modulate = Color(1, 1, 1, 1) if not c.is_solid else Color(0.1, 0.1, 0.4, 1.0)

	mineral_poly.visible = c.has_mineral and c.is_solid # and c.light_depth <= 1

	_encode_stencil_buffer()
	_update_light_depth_visuals()


func _update_light_depth_visuals() -> void:
	shadow_poly.set_instance_shader_parameter("light_depth", c.light_depth)

	# 0 = light, 1 = border, 2+ = dark
	if c.light_depth == 0:
		shadow_poly.visible = false
	else:
		shadow_poly.visible = true

		# Update light_depths array into shader as bitfield
		# True = lit = apply fade, False = Shadow = no fade, black till border
		var neighbour_lit_bits: int = 0
		var idx: int = 0
		for dir: Vector2i in Util.neighbours_all:
			var n: Cell = c.get_neighbour(dir)
			var n_lit: bool = n != null and n.light_depth == 0
			if n_lit:
				neighbour_lit_bits |= (1 << idx)
			idx += 1

		# Assign to shader		
		shadow_poly.set_instance_shader_parameter("neighbour_lit_bits", neighbour_lit_bits)


# Set Stencil Colors. Dont write to alpha, this is done only once to show/hide stencil in editor vs game
func _encode_stencil_buffer() -> void:
	# Encode flags in RED channel
	stencil_poly.color.r8 = 0
	stencil_poly.color.r8 |= (1 << 0) if c.is_marked_for_mining else 0
	stencil_poly.color.r8 |= (1 << 1) if c.is_solid else 0
	stencil_poly.color.r8 |= (1 << 2) if c.is_highlighted else 0

	# Encode numbers in GREEN channel
	stencil_poly.color.g8 = 0
	# Mining Process in 3 bits
	stencil_poly.color.g8 |= Util.encode_into_bits(c.mining_process, 0, 3)

	# BLUE channel - used for debugging
	stencil_poly.color.b8 = 0


## Returns a single poly point in world-space RELATIVE TO CELL
func get_poly_point(point: Enum.PolyPoint) -> Vector2:
	assert(poly_points.size() == 8)
	assert(point >= 0 and point < poly_points.size())
	return poly_points[point]


# Returns a rectangle polygon for cell at grid position (x, y) in world-space RELATIVE TO CELL.
# Values range is [0, CELL_SIZE] + small random offset
func _compute_cell_polygon() -> PackedVector2Array:
	const SIDE_LENGTH: float = Global.CELL_SIZE

	# 4 Corners
	var top_left := Vector2.ZERO
	var top_right := Vector2(SIDE_LENGTH, 0.0)
	var bot_right := Vector2(SIDE_LENGTH, SIDE_LENGTH)
	var bot_left := Vector2(0.0, SIDE_LENGTH)

	# 4 Sides
	var top := (top_left + top_right) * 0.5
	var right := (top_right + bot_right) * 0.5
	var bot := (bot_right + bot_left) * 0.5
	var left := (bot_left + top_left) * 0.5

	# Deterministic-Random Offset
	var max_corner_offset := SIDE_LENGTH * 0.115
	var max_side_offset := SIDE_LENGTH * 0.135

	var base: Vector2 = c.grid_pos * SIDE_LENGTH
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

# Compute normalized UVs by simply scaling down polygon by SIDE_LENGTH
func _compute_cell_uvs() -> PackedVector2Array:
	const SIDE_LENGTH: float = Global.CELL_SIZE
	var uvs: PackedVector2Array = []
	for p in poly_points:
		uvs.append(p / SIDE_LENGTH)
	return uvs
