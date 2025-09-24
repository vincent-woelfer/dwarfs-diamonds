@tool
class_name Util

# Grid dimensions
const LEVEL_WIDTH: int = 20
const LEVEL_HEIGHT: int = 14
const CELL_SIZE: Vector2 = Vector2(64, 64)

static func is_map_border(x: float, y: float) -> bool:
	return x <= 0.0 or y <= 0.0 or x >= LEVEL_WIDTH * int(CELL_SIZE.x) or y >= LEVEL_HEIGHT * int(CELL_SIZE.y)

static func rand_circular_offset(v: Vector2, r_max: float) -> Vector2:
	var r1 := rand_from_vec(v, 0)
	var r2 := rand_from_vec(v, 1)

	var angle := r1 * 2.0 * PI
	var r := r2 * r_max
	return vec_from_radius_angle(r, angle)

static func vec_from_radius_angle(r: float, angle: float) -> Vector2:
	return Vector2(r * cos(angle), r * sin(angle))

static func rand_from_vec(v: Vector2, z: int = 0) -> float:
	return rand_from_coords(v.x, v.y, z)

static func rand_from_coords(x: float, y: float, z: int = 0) -> float:
	# No offset for map border
	if is_map_border(x, y):
		return 0.0

	# Round inputs to 2 decimal places
	var x_ = int(round(x * 100.0))
	var y_ = int(round(y * 100.0))
	
	var n = x_ * 73856093 ^ y_ * 19349663 ^ z * 83492791
	n = n & 0x7fffffff
	return float(n % 10001) / 10000.0
