class_name Dwarf
extends Node2D

@onready var light: PointLight2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mining_comp: MiningComponent = $MiningComponent


static var next_dwarf_id: int = 0
var dwarf_id: int
var speed := 10
var grid_pos: Vector2i

enum Status {IDLE, MOVING, MINING}
var status: Status

var job_with_path: JobWithPath


func _ready() -> void:
	dwarf_id = next_dwarf_id
	next_dwarf_id += 1

	status = Status.IDLE
	global_position = Util.grid_space_to_world_space_cell_center(grid_pos)

	EventBus.Signal_NavUpdated.connect(_on_nav_updated)


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
	var new_job_with_path: JobWithPath = Global.level.job_manager.get_new_job_for_worker(grid_pos)

	if new_job_with_path != null:
		job_with_path = new_job_with_path

		new_job_with_path.job.assign_dwarf(self)
		_transition_to_state(Status.MOVING)

		# Draw path by adding to scene tree
		add_child(job_with_path.path)
		print("%s started job %s at cell %s" % [self, Enum.to_str(Job.Type, job_with_path.job.type), job_with_path.job.target_cell])


func _tick_moving(delta: float) -> void:
	pass


func _tick_mining(delta: float) -> void:
	pass


func _transition_to_state(new_status: Status) -> void:
	status = new_status
	queue_redraw()


func _on_nav_updated() -> void:
	# If nav updated while moving -> recalculate path for job or abort if not valid
	if job_with_path != null:
		job_with_path.path.queue_free()
		
		# Force job to update workable cells first
		job_with_path.job.update_workable_from_cells()
		var new_path: Path = Global.level.nav.find_path_to_one_of(grid_pos, job_with_path.job.workable_from_grid_poses)

		if new_path != null:
			job_with_path.path = new_path
			add_child(job_with_path.path)
		else:
			print("%s lost path to job at cell %s" % [self, job_with_path.job.target_cell])
			job_with_path.job.unassign_dwarf(self)
			job_with_path = null
			_transition_to_state(Status.IDLE)


func _to_string() -> String:
	return "Dwarf(%d | pos=%s, status=%s)" % [dwarf_id, grid_pos, Enum.to_str(Status, status)]


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
