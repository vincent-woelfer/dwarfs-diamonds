class_name Rubble
extends GridObject2D

# Scene Components
@onready var sprite: Sprite2D = $Sprite2D
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var carryable_item_comp: CarryableItemComponent = $CarryableItemComponent

# The pickup job associated with this rubble
var pickup_job: Job = null


func _ready() -> void:
	global_position = Global.level.get_cell(grid_pos).get_floor_point()
	global_position.y -= Global.CELL_SIZE * 0.3 # Let rubble fall a bit on spawn

	self.z_index = Enum.ZIndex.RUBBLE

	movement_comp.movement_capabilities.can_use_ladders = false
	movement_comp.movement_capabilities.can_use_ladders_when_falling = false

	# Modulate color randomly
	sprite.modulate = Colors.rand_rubble_color()

	# SIGNALS
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)

	# CarryableItemComponent + MovementComponent signals
	carryable_item_comp.Signal_OnPickedUp.connect(movement_comp.picked_up)
	carryable_item_comp.Signal_OnDropped.connect(movement_comp.dropped)

	carryable_item_comp.Signal_OnPickedUp.connect(_on_picked_up)
	carryable_item_comp.Signal_OnDropped.connect(_on_dropped)

	# Add pickup job
	pickup_job = Job.new(Job.Type.RUBBLE, curr_cell)
	pickup_job.rubble = self
	Global.level.job_manager.add_job(pickup_job)


# Add/remove pickup job on pick up / drop
func _on_picked_up() -> void:
	Global.level.job_manager.remove_job(pickup_job)
	pickup_job = null
func _on_dropped() -> void:
	pickup_job = Job.new(Job.Type.RUBBLE, curr_cell)
	pickup_job.rubble = self
	Global.level.job_manager.add_job(pickup_job)


# TODO unused
func delete() -> void:
	Global.level.job_manager.remove_job(pickup_job)
	queue_free()

# used by CarryableItemComponent to check whether this rubble can be picked up
func _can_be_picked_up() -> bool:
	return not movement_comp.is_falling()


func _on_new_cell_entered(new_cell: Cell) -> void:
	if new_cell == null or carryable_item_comp.is_being_carried:
		return

	if pickup_job != null:
		pickup_job.center_cell = new_cell
		pickup_job.update_workable_from_cells()


func _on_started_falling() -> void:
	pass


func _on_landed(fall_height_cells: int) -> void:
	# Trigger on cell entered anew to update job status
	_on_new_cell_entered(curr_cell)

	if fall_height_cells >= 1:
		Audio.play_at_pos("rubble_impact", global_position)


func _to_string() -> String:
	var color := Colors.to_print_color(sprite.modulate)
	return Util.color_string("Rubble", color)
