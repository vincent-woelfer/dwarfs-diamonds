class_name Rubble
extends GridObject2D

# Scene Components
@onready var sprite: Sprite2D = $Sprite2D
@onready var movement_comp: MovementComponent = $MovementComponent

# The pickup job associated with this rubble
var pickup_job: Job = null

func setup(grid_pos_: Vector2i, sample_offset_: Vector2 = Global.VERT_OFFSET_SMALL) -> void:
	super.setup(grid_pos_, sample_offset_)


func _ready() -> void:
	global_position = Global.level.get_cell(grid_pos).get_floor_point()
	global_position.y -= Global.CELL_SIZE * 0.3 # Let rubble fall on spawn

	movement_comp.movement_capabilities.can_use_ladders = false
	movement_comp.movement_capabilities.can_use_ladders_when_falling = false

	# Modulate color
	sprite.modulate = Colors.rand_rubble_color()

	# SIGNALS
	movement_comp.Signal_MovementDirectionChanged.connect(_on_movement_direction_changed)
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)

	# Start falling	immediately
	movement_comp.sm.transition_to(MovementComponent.State.FALLING)

	# Add pickup job
	pickup_job = Job.new(Job.Type.RUBBLE, curr_cell)
	pickup_job.rubble = self
	Global.level.job_manager.add_job(pickup_job)


func can_pickup() -> bool:
	return not movement_comp.is_falling()


func delete() -> void:
	Global.level.job_manager.remove_job(pickup_job)
	queue_free()


func _on_new_cell_entered(new_cell: Cell) -> void:
	if new_cell == null:
		return

	pickup_job.center_cell = new_cell
	pickup_job.update_workable_from_cells()


func _on_movement_direction_changed(new_dir: Vector2) -> void:
	pass


func _on_started_falling() -> void:
	pass


func _on_landed(fall_height_cells: int) -> void:
	# Trigger on cell entered anew to update job status
	_on_new_cell_entered(curr_cell)

	if fall_height_cells >= 1:
		Audio.play_at_pos("rubble_impact", global_position)
