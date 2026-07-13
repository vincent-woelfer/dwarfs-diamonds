class_name Camera
extends Node2D

# Positional parameters
# pixels per second, one cell is 128 x 128 pixel (defined in Global.gd)
var pan_speed: float = Global.CELL_SIZE * 11.0

var zoom_curr: float = 1.0
var zoom_target: float = 1.0
var zoom_step: float = 0.15
var zoom_speed: float = 15.0

# min = zoomed out, max = zoomed in
# Larger value = more zoomed in
var zoom_min: float = 0.7
var zoom_max: float = 6.0 # for gameplay maybe 3 -> but for testing allow closer

# Move towards mouse cursor when zooming in
# strength: 0 -> zoom towards center, 1 -> zoom towards mouse position, 0.5 -> half way between mouse and center
# 1 = cell under mouse cursor stays the same.
var zoom_to_mouse_strength: float = 1.0

# For panning and level bounds
# The world size (as in)
var level_size: Vector2 = Global.CELL_SIZE_VEC * Global.LEVEL_SIZE_VEC
var margin_cells: int = 4

@onready var stencil_viewport: StencilViewport = get_tree().root.get_node("root/StencilViewport")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the visible screen size (in world units)
	# Start centered on horizonal axis
	var viewport_size: Vector2 = get_viewport_rect().size / zoom_curr
	position.x = level_size.x * 0.5
	position.y = (viewport_size.y * 0.5) - Global.CELL_SIZE / zoom_curr
	_clamp_pos_to_level()


## In pixel space
func get_mouse_pos_world_space() -> Vector2:
	# Mouse in local viewport space - unit is pixels
	var screen_mouse: Vector2 = get_viewport().get_mouse_position()
	var mouse_screen_center_relative := screen_mouse - get_viewport_rect().size * 0.5
	return self.position + mouse_screen_center_relative / zoom_curr


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe := event as InputEventMouseButton
		# Zoom in/out with mouse wheel - make it feel linear by adjusting the zoom_target multiplicatively not additively
		# ZOOM IN
		if mbe.button_index == MOUSE_BUTTON_WHEEL_UP and mbe.pressed:
			zoom_target *= (1.0 + zoom_step)
		# ZOOM OUT
		elif mbe.button_index == MOUSE_BUTTON_WHEEL_DOWN and mbe.pressed:
			zoom_target *= (1.0 - zoom_step)

		zoom_target = clamp(zoom_target, zoom_min, zoom_max)
		_clamp_zoom_to_level_horizontally()


func _process(delta: float) -> void:
	###################################
	# ZOOMING
	###################################
	var mouse_world_before_zoom: Vector2 = get_mouse_pos_world_space()

	# Zoom towards target (which is updated in _input)
	zoom_curr = Util.lerp_towards_f(zoom_curr, zoom_target, zoom_speed, delta)

	var mouse_world_after_zoom: Vector2 = get_mouse_pos_world_space()
	var mouse_world_drift: Vector2 = mouse_world_before_zoom - mouse_world_after_zoom

	# ZOOM IN: Move towards mouse cursor
	if zoom_target > zoom_curr:
		position += mouse_world_drift * clampf(zoom_to_mouse_strength, 0.0, 1.0)

	# ZOOM OUT: Move away from mouse cursor
	if zoom_target < zoom_curr:
		position += mouse_world_drift * clampf(zoom_to_mouse_strength, 0.0, 1.0)

	###################################
	# PANNING via WASD or arrow keys
	###################################
	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("cam_move_left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("cam_move_right"):
		input_vector.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("cam_move_up"):
		input_vector.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("cam_move_down"):
		input_vector.y += 1.0

	# Actually move
	if input_vector != Vector2.ZERO:
		# Adjust fore zoom. Zoomed in = larger zoom value -> slower panning
		var pan_speed_adjusted_for_zoom := pan_speed / lerpf(zoom_curr, 1.0, 0.5)
		position += input_vector.normalized() * pan_speed_adjusted_for_zoom * delta

	_clamp_pos_to_level()

	###################################
	# Set root viewport and stencil viewport transform
	###################################
	var t := Transform2D()
	t.x *= Vector2.ONE * zoom_curr
	t.y *= Vector2.ONE * zoom_curr
	t.origin = -position * zoom_curr + get_viewport_rect().size * 0.5

	get_viewport().canvas_transform = t
	if stencil_viewport:
		stencil_viewport.canvas_transform = t


## Clamping only works horizontally, we assume the level is always deep enough vertically.
func _clamp_zoom_to_level_horizontally() -> void:
	# Get the visible screen size (in world units)
	var viewport_width: float = get_viewport_rect().size.x

	# A Camera2D viewport covers viewport_width / zoom.x world units.
	# Therefore, zoom must be at least viewport_width / level_size.x.
	var zoom_min_effective: float = maxf(zoom_min, viewport_width / level_size.x)
	var zoom_max_effective: float = zoom_max

	if zoom_min_effective > zoom_max_effective:
		zoom_min_effective = zoom_max_effective

	# Clamp both individually, this keeps zoom tweening intact but enforces the level bounds on both.
	zoom_target = clampf(zoom_target, zoom_min_effective, zoom_max_effective)
	zoom_curr = clampf(zoom_curr, zoom_min_effective, zoom_max_effective)


func _clamp_pos_to_level() -> void:
	# Get the visible screen size (in world units)
	var viewport_half := get_viewport_rect().size / zoom_curr * 0.5
	var margin := margin_cells * Global.CELL_SIZE / zoom_curr # Currently 0 margin

	# Vector clamp doesnt work when scaling larger than level size -> clamp each axis individually
	position.x = clamp(position.x, viewport_half.x - margin, level_size.x - viewport_half.x + margin)
	position.y = clamp(position.y, viewport_half.y - margin, level_size.y - viewport_half.y + margin)
