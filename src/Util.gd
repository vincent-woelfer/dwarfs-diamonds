@tool
class_name Util

########################################################################
# CONSTANTS
########################################################################
const LAYER_1 := 1 << 0
const LAYER_2 := 1 << 1

########################################################################
# Dwardfs & Diamonds NEW
########################################################################
static func is_map_border(pos: Vector2) -> bool:
	var min_x := 0.0
	var min_y := 0.0
	var max_x := Global.LEVEL_WIDTH * Global.CELL_SIZE
	var max_y := Global.LEVEL_HEIGHT * Global.CELL_SIZE
	return pos.x <= min_x or pos.y <= min_y or pos.x >= max_x or pos.y >= max_y


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
	if is_map_border(pos):
		return 0.0

	# Round inputs to 2 decimal places
	var x_ := roundi(pos.x * 100.0)
	var y_ := roundi(pos.y * 100.0)

	var n := x_ * 73856093 ^ y_ * 19349663 ^ z * 83492791
	n = n & 0x7fffffff
	return float(n % 10001) / 10000.0


########################################################################
# BIT STUFF
########################################################################
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


########################################################################
# LERP
########################################################################
const EPSILON: float = 0.001
static func lerp_towards_f(curr: float, goal: float, speed: float, delta: float) -> float:
	if abs(goal - curr) < EPSILON:
		return goal
	return lerp(curr, goal, 1.0 - exp(-speed * delta))


########################################################################
# Physics stuff
########################################################################
static func get_scene_root() -> Node2D:
	if Engine.is_editor_hint():
		return EditorInterface.get_edited_scene_root() as Node2D
	else:
		return (Engine.get_main_loop() as SceneTree).current_scene as Node2D

########################################################################
# Timing & Waiting
########################################################################
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
