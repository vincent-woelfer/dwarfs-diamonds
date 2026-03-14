class_name Gemstone
extends GridObject2D

# Scene Components
@onready var sprite: Sprite2D = $Sprite2D
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var carryable_item_comp: CarryableItemComponent = $CarryableItemComponent
@onready var light: PointLight2D = $PointLight2D

# The pickup job associated with this gemstone
var pickup_job: Job = null

var light_energy_default: float = 0.25

func _ready() -> void:
	global_position = Global.level.get_cell(grid_pos).get_floor_point()
	global_position.y -= Global.CELL_SIZE * 0.3 # Let it fall a bit on spawn

	self.z_index = Enum.ZIndex.GEMSTONE

	movement_comp.movement_stats.can_use_ladders = false
	movement_comp.movement_stats.can_use_ladders_when_falling = false

	# Set carryable item type
	carryable_item_comp.item_type = Enum.CarryableType.GEMSTONE

	# Modulate color randomly
	var color: Color = [Color.HOT_PINK, Color.CYAN, Color.YELLOW_GREEN].pick_random()
	sprite.modulate = color * 2.0

	light.color = Color.WHITE.lerp(color, 0.5)
	light.energy = light_energy_default

	# SIGNALS
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)

	# CarryableItemComponent + MovementComponent signals
	carryable_item_comp.Signal_OnPickedUp.connect(movement_comp.picked_up)
	carryable_item_comp.Signal_OnDropped.connect(movement_comp.dropped)

	carryable_item_comp.Signal_OnPickedUp.connect(_on_picked_up)
	carryable_item_comp.Signal_OnDropped.connect(_on_dropped)

	_add_pickup_job()


# Add/remove pickup job on pick up / drop
func _on_picked_up() -> void:
	Actions.archive_job(pickup_job, true)
	pickup_job = null

	# reduce light energy when carried
	light.energy = 0.0

func _on_dropped() -> void:
	_add_pickup_job()

	# restore light energy when dropped
	light.energy = light_energy_default


func _process(delta: float) -> void:
	var light_rotation_speed_rad_per_sec := deg_to_rad(15)
	light.rotate(light_rotation_speed_rad_per_sec * delta)


func _add_pickup_job() -> void:
	if pickup_job != null:
		return

	pickup_job = Job.new(Job.Type.PICKUP, curr_cell)
	pickup_job.carryable_item = carryable_item_comp
	Global.level.job_manager.add_job(pickup_job)

# used by CarryableItemComponent to check whether this rubble can be picked up
func _can_be_picked_up() -> bool:
	return not movement_comp.is_falling()


func _on_new_cell_entered(new_cell: Cell) -> void:
	if new_cell == null or carryable_item_comp.is_being_carried:
		return

	if pickup_job != null:
		pickup_job.center_cell = new_cell
		pickup_job.update_workable_from_cells()


func _on_started_falling(est_fall_height_cells: int) -> void:
	pass


func _on_landed(fall_height_cells: int) -> void:
	# Trigger on cell entered anew to update job status
	_on_new_cell_entered(curr_cell)

	if fall_height_cells >= 1:
		Audio.play_at_pos("gemstone_drop", global_position)


func _to_string() -> String:
	var color := Colors.to_print_color(sprite.modulate)
	return Util.color_string("Gemstone @%s" % [ self._grid_pos], color)
