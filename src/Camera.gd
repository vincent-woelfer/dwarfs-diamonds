class_name Camera
extends Node2D

# Positional parameters
# pixels per second
var pan_speed: float = 1000.0

var zoom_curr: float = 1.0
var zoom_target: float = 1.0
var zoom_step: float = 0.1
var zoom_speed: float = 15.0
# min = zoomed out, max = zoomed in
var zoom_min: float = 0.7
var zoom_max: float = 3.0

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
	_clamp_to_level()


func mouse_pos_world_space() -> Vector2:
	# Mouse in local viewport space
	var screen_mouse: Vector2 = get_viewport().get_mouse_position()
	var centered := screen_mouse - get_viewport_rect().size * 0.5
	return self.position + centered / zoom_curr
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_WHEEL_UP and mbe.pressed:
			zoom_target += zoom_step
		elif mbe.button_index == MOUSE_BUTTON_WHEEL_DOWN and mbe.pressed:
			zoom_target -= zoom_step
		
		zoom_target = clamp(zoom_target, zoom_min, zoom_max)

func _process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("cam_move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("cam_move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("cam_move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("cam_move_down"):
		input_vector.y += 1

	
	# Actually move
	if input_vector != Vector2.ZERO:
		var pan_speed_adjusted := pan_speed / lerpf(zoom_curr, 1.0, 0.5)
		position += input_vector.normalized() * pan_speed_adjusted * delta

	# Zoom
	zoom_curr = Util.lerp_towards_f(zoom_curr, zoom_target, zoom_speed, delta)


	_clamp_to_level()

	# Set root viewport and stencil viewport transform
	var t := Transform2D()
	t.x *= Vector2.ONE * zoom_curr
	t.y *= Vector2.ONE * zoom_curr
	t.origin = - position * zoom_curr + get_viewport_rect().size * 0.5

	get_viewport().canvas_transform = t
	stencil_viewport.canvas_transform = t


func _clamp_to_level() -> void:
	# Get the visible screen size (in world units)
	var viewport_half := get_viewport_rect().size / zoom_curr * 0.5
	var margin := margin_cells * Global.CELL_SIZE / zoom_curr
	position.x = clamp(position.x, viewport_half.x - margin, level_size.x - viewport_half.x + margin)
	position.y = clamp(position.y, viewport_half.y - margin, level_size.y - viewport_half.y + margin)
