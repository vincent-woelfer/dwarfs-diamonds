class_name Util

########################################################################################################################
# CONSTANTS
########################################################################################################################
const LAYER_1 := 1 << 0 # Normal visual layer
const LAYER_2 := 1 << 1 # Stencil buffer, used for passing data to shaders


const EPSILON_LERP: float = 0.001
const EPSILON_PIXEL_DIST: float = Global.CELL_SIZE * 0.1

## For sampling grid_position from world_position
# Sample a bit above the center of the cell to avoid issues with sampling when right at the edge of a cell
const SAMPLE_OFFSET_VERTICAL_EPSILON := -Vector2(0.0, Global.CELL_SIZE * 0.2)

########################################################################################################################
# Dwardfs & Diamonds NEW
########################################################################################################################
static func color_string(text: String, color: Color) -> String:
	return "[color=%s]%s[/color]" % [color.to_html(false), text]

static func is_pos_inside_map_no_border(pos: Vector2) -> bool:
	var min_x := 0.0
	var min_y := 0.0
	var max_x := Global.LEVEL_WIDTH * Global.CELL_SIZE
	var max_y := Global.LEVEL_HEIGHT * Global.CELL_SIZE
	return pos.x > min_x and pos.y > min_y and pos.x < max_x and pos.y < max_y


static func is_grid_pos_valid(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < Global.LEVEL_WIDTH and grid_pos.y >= 0 and grid_pos.y < Global.LEVEL_HEIGHT


static func rand_circular_offset(v: Vector2, r_max: float) -> Vector2:
	var r1 := rand_from_coords(v, 0)
	var r2 := rand_from_coords(v, 1)

	var angle := r1 * 2.0 * PI
	var r := r2 * r_max
	return vec_from_radius_angle(r, angle)


static func vec_from_radius_angle(r: float, angle: float) -> Vector2:
	return Vector2(r * cos(angle), r * sin(angle))


static func rand_from_coords(pos: Vector2, z: int = 0) -> float:
	# No offset for map border
	if not is_pos_inside_map_no_border(pos):
		return 0.0

	# Round inputs to 2 decimal places
	var x_ := roundi(pos.x * 100.0)
	var y_ := roundi(pos.y * 100.0)

	var n := x_ * 73856093 ^ y_ * 19349663 ^ z * 83492791
	n = n & 0x7fffffff
	return float(n % 10001) / 10000.0

static func randi_from_coords(pos: Vector2, min_inclusive: int, max_inclusive: int, z: int = 0) -> int:
	var r: float = rand_from_coords(pos, z)
	return min_inclusive + roundi(r * (max_inclusive - min_inclusive))


static func grid_to_world_cell_center(grid_pos: Vector2i) -> Vector2:
	return ((grid_pos as Vector2) + Vector2(0.5, 0.5)) * Global.CELL_SIZE_VEC


static func grid_to_world_cell_center_array(grid_poses: Array[Vector2i]) -> Array[Vector2]:
	var world_positions: Array[Vector2] = []
	for gp in grid_poses:
		world_positions.append(grid_to_world_cell_center(gp))
	return world_positions

# NO world_space_to_grid_space -> Use Level.get_cell_at_world_pos


########################################################################################################################
# Neighbours
########################################################################################################################
static var neighbours_cardinal := [
	Global.VEC_LEFT,
	Global.VEC_RIGHT,
	Global.VEC_UP,
	Global.VEC_DOWN,
]

static var neighbours_diagonal := [
	Vector2i(-1, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1),
	Vector2i(1, -1)
]

# These follow the same order as the 8 poly points, so we can easily loop through them together when needed (e.g. for vertex colors)
# ORDER: top_left, top, top_right, right, bot_right, bot, bot_left, left
static var neighbours_all := [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
]

## Allows for both cardinal and diagonal neighbours
static func are_neighbours(pos_a: Vector2i, pos_b: Vector2i) -> bool:
	# Squared distance must be 1 (cardinal) or 2 (diagonal). dist-2-cardinal = 2*2 = 4 so is not a neighbour
	var dist: int = pos_a.distance_squared_to(pos_b)
	return dist == 1 or dist == 2

static func are_cardinal_neighbours(pos_a: Vector2i, pos_b: Vector2i) -> bool:
	# Squared distance must be 1 (cardinal)
	return pos_a.distance_squared_to(pos_b) == 1

static func are_diagonal_neighbours(pos_a: Vector2i, pos_b: Vector2i) -> bool:
	# Squared distance must be 2 (diagonal)
	return pos_a.distance_squared_to(pos_b) == 2


## Compare vertically and get the lower cell (higher y)
static func get_lower_cell(a: Cell, b: Cell) -> Cell:
	return a if a.grid_pos.y > b.grid_pos.y else b

## Compare vertically and get the upper cell (lower y)
static func get_upper_cell(a: Cell, b: Cell) -> Cell:
	return a if a.grid_pos.y < b.grid_pos.y else b


########################################################################################################################
# BIT STUFF
########################################################################################################################
# Encodes a normalized float (0.0–1.0) into an integer bitfield
# value     – float in range [0.0, 1.0]
# num_bits  – how many bits to use (e.g. 3 bits → values 0–7)
# start_bit – where in the integer to place the bits (bit offset)
static func encode_into_bits(value: float, start_bit: int, num_bits: int) -> int:
	value = clampf(value, 0.0, 1.0)
	
	# e.g. 3 bits -> 7
	var max_val: int = (1 << num_bits) - 1
	# scale into 0..max_val
	var quantized: int = clampi(roundi(value * max_val), 0, max_val)
	# shift into correct position
	return quantized << start_bit


########################################################################################################################
# LERP
########################################################################################################################
static func lerp_towards_f(curr: float, goal: float, speed: float, delta: float) -> float:
	if abs(goal - curr) < EPSILON_LERP:
		return goal
	return lerp(curr, goal, 1.0 - exp(-speed * delta))


########################################################################################################################
# GEOMETRY
########################################################################################################################
static func is_point_near_line_segment(p: Vector2, a: Vector2, b: Vector2) -> bool:
	# Epsilon is in world space units -> dont use "0.001" or similar
	const epsilon: float = Util.EPSILON_PIXEL_DIST

	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq == 0.0:
		return p.distance_to(a) <= epsilon

	var t: float = (p - a).dot(ab) / ab_len_sq
	t = clamp(t, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return p.distance_to(closest) <= epsilon

########################################################################################################################
# Physics stuff
########################################################################################################################
static func get_scene_root() -> Node2D:
	if Engine.is_editor_hint():
		return EditorInterface.get_edited_scene_root() as Node2D
	else:
		return (Engine.get_main_loop() as SceneTree).current_scene as Node2D

########################################################################################################################
# Timing & Waiting
########################################################################################################################
static func await_until(node: Node2D, condition: Callable) -> void:
	while not condition.call():
		await node.get_tree().physics_frame

static func await_time(time: float) -> void:
	await get_scene_root().get_tree().create_timer(time).timeout


static func delete_after(time: float, node: Node2D) -> void:
	if node == null:
		return
	timer_one_shot(time, Callable(node, "queue_free"))


static func timer(time: float, timeout_callable: Callable, one_shot: bool = false) -> Timer:
	var t := Timer.new()
	t.wait_time = time
	t.one_shot = one_shot
	t.autostart = true
	t.timeout.connect(timeout_callable)
	return t

static func timer_one_shot(time: float, timeout_callable: Callable) -> void:
	var scene_tree_timer := get_scene_root().get_tree().create_timer(time)
	scene_tree_timer.timeout.connect(timeout_callable)


## Returns the time since the game started in seconds
static func now() -> float:
	return (Time.get_ticks_msec() / 1000.0) as float

## Returns true if the given duration has passed since start_time
static func has_time_passed(timestamp: float, duration: float) -> bool:
	return now() - timestamp >= duration


########################################################################################################################
# ARRAYS
########################################################################################################################
static func array_append_unique_not_null(arr: Array, item: Variant) -> void:
	if item != null and item not in arr:
		arr.append(item)


static func get_action_points_grid_positions(aps: Array[ActionPoint]) -> Array[Vector2i]:
	var grid_positions: Array[Vector2i] = []
	for ap: ActionPoint in aps:
		grid_positions.append(ap.grid_pos)
	return grid_positions

########################################################################################################################
# Hash
########################################################################################################################
static func hash(v: Vector2i) -> int:
	# Maps [x,y] -> N, works bidirectionally but only for unsigned integers
	# Based on Szudzik pairing
	# https://www.vertexfragment.com/ramblings/cantor-szudzik-pairing-functions/#szudzik-pairing
	return ((v.x * v.x) + v.x + v.y) if v.x >= v.y else ((v.y * v.y) + v.x)


static func unhash(n: int) -> Vector2i:
	# Reverse of Szudzik pairing (unsigned)
	var sqrt_n := int(floori(sqrt(n)))
	var sq := sqrt_n * sqrt_n
	
	if n - sq < sqrt_n:
		# Case where x < y, so y = sqrt_n
		return Vector2i(n - sq, sqrt_n)
	else:
		# Case where x >= y
		return Vector2i(sqrt_n, n - sq - sqrt_n)


########################################################################################################################
# Building Specific
########################################################################################################################
static func instantiate_building_visual_base(building_type: Enum.BuildingType) -> BuildingVisualRoot:
	var path_name: String = _internal_get_building_path_name(building_type)
	var visual_scene: PackedScene = load("res://scenes/building_visuals/%sVisual.tscn" % [path_name]) as PackedScene

	# Verification
	var type_name_requested: String = Enum.to_str(Enum.BuildingType, building_type)
	assert(visual_scene != null, "Visual scene not found for building type %s" % [type_name_requested])

	var visual_base: BuildingVisualRoot = visual_scene.instantiate()
	return visual_base


static func get_building_data(building_type: Enum.BuildingType) -> BuildingDataRes:
	var path_name: String = _internal_get_building_path_name(building_type)
	var building_data: BuildingDataRes = load("res://scenes/building_data/%sData.tres" % [path_name]) as BuildingDataRes

	# Verification
	var type_name_requested: String = Enum.to_str(Enum.BuildingType, building_type)
	var type_name_actual: String = Enum.to_str(Enum.BuildingType, building_data.type)
	assert(building_data != null, "BuildingDataRes not found for building type %s" % [type_name_requested])
	assert(building_data.type == building_type, "BuildingDataRes type %s does not match requested type %s" % [type_name_actual, type_name_requested])

	return building_data


static func _internal_get_building_path_name(building_type: Enum.BuildingType) -> String:
	var parts: PackedStringArray = Enum.to_str(Enum.BuildingType, building_type).split("_")
	var result: String = ""
	for part in parts:
		if part.length() > 0:
			result += part.capitalize()
	return result
