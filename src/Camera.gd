class_name Camera
extends Camera2D

# Positional parameters
# pixels per second
@export var pan_speed: float = 900.0

# For panning and level bounds
# The world size (as in)
var level_size: Vector2 = Global.CELL_SIZE_VEC * Vector2(Global.LEVEL_WIDTH, Global.LEVEL_HEIGHT)
var margin_cells: int = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the visible screen size (in world units)
	# Start centered on horizonal axis
	var viewport_size: Vector2 = get_viewport_rect().size / zoom
	position.x = level_size.x * 0.5
	position.y = viewport_size.y * 0.5 - Global.CELL_SIZE
	_clamp_to_level()


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
		position += input_vector.normalized() * pan_speed * delta

	_clamp_to_level()

	# Also set for stencil viewport
	self.get_canvas_transform()



func _clamp_to_level() -> void:
	# Get the visible screen size (in world units)
	var viewport_half := get_viewport_rect().size / zoom * 0.5
	var margin := margin_cells * Global.CELL_SIZE
	position.x = clamp(position.x, viewport_half.x - margin, level_size.x - viewport_half.x + margin)
	position.y = clamp(position.y, viewport_half.y - margin, level_size.y - viewport_half.y + margin)
