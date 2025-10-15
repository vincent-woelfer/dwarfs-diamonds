class_name Dwarf
extends Node2D

@onready var light: PointLight2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mining_comp: MiningComponent = $MiningComponent


var speed := 10
var grid_pos: Vector2i

enum Status {IDLE, MOVING, MINING}
var status: Status

var curr_job_with_path: JobWithPath


func _ready() -> void:
	status = Status.IDLE
	global_position = Util.grid_space_to_world_space_cell_center(grid_pos)
	

# TODO implement state machine properly
func _physics_process(delta: float) -> void:
	if status == Status.IDLE:
		_tick_idle(delta)
	elif status == Status.MOVING:
		_tick_moving(delta)
	elif status == Status.MINING:
		_tick_mining(delta)
		

func _tick_idle(delta: float) -> void:
	# Try to get a new job
	var job_with_path: JobWithPath = Global.level.job_manager.get_new_job_for_worker(grid_pos)

	if job_with_path != null:
		curr_job_with_path = job_with_path
		curr_job_with_path.job.status = Job.Status.IN_PROCESS

		_transition_to_state(Status.MOVING)

		# Draw path by adding to scene tree
		add_child(curr_job_with_path.path)

		print("Dwarf at %s started job %s at cell %s" % [grid_pos, Enum.to_str(Job.Type, curr_job_with_path.job.type), curr_job_with_path.job.cell])
	else:
		print("Dwarf at ", grid_pos, " found no job, staying idle.")


func _tick_moving(delta: float) -> void:
	pass


func _tick_mining(delta: float) -> void:
	pass


func _transition_to_state(new_status: Status) -> void:
	status = new_status
	queue_redraw()

########################################################################
# DEBUG DRAWING
########################################################################
var debug_show := true
const debug_color_idle := Color.DIM_GRAY
const debug_color_moving := Color(1.0, 1.0, 0.0)
const debug_color_mining := Color(1.0, 0.0, 0.0)

const debug_offset := Vector2(-0.4, -0.4) * Global.CELL_SIZE_VEC
const debug_label_width := 0.8 * Global.CELL_SIZE

var debug_font := ThemeDB.fallback_font
var debug_font_size := 22


func _draw() -> void:
	if not debug_show:
		return

	var color_actual: Color
	match status:
		Status.IDLE:
			color_actual = debug_color_idle
		Status.MOVING:
			color_actual = debug_color_moving
		Status.MINING:
			color_actual = debug_color_mining

	var text: String = Enum.to_str(Dwarf.Status, status)
	var pos := debug_offset
	draw_string(debug_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, debug_font_size, color_actual)
