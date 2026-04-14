class_name Item
extends GridObject2D

# Number is used to sort groups in inventory for now (TODO refactor)
enum ItemType {
	RUBBLE = 0,
	GEMSTONE = 1,
}

# THIS IS A SCENE
# Scene Components - Required
@onready var sprite: Sprite2D = $Sprite
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var carryable_item_comp: CarryableItemComponent = $CarryableItemComponent
@onready var stacking_shape: CollisionShape2D = $StackingShape

# Scene Components - Optional
@onready var light: PointLight2D = $PointLight

# Used to set CarryableItemComponent weight
@export var weight: float = 1.0
@export var item_type: ItemType

# Sounds
@export var on_spawned_audio: AudioStream
@export var on_landed_audio: AudioStream


# The pickup job associated with this item
var pickup_job: Job = null

# Further Config
var light_energy_default: float = 0.25

# Spawn offset y must be negative to be placed above floor
func setup(grid_pos_: Vector2i, spawn_offset: Vector2 = Vector2.ZERO) -> void:
	# Validation
	assert(item_type in ItemType.values(), "Invalid item type %s" % [item_type])
	super.setup(grid_pos_)
	global_position = Global.level.get_cell(grid_pos).get_floor_point() + spawn_offset


func _ready() -> void:
	self.z_index = Enum.ZIndex.GEMSTONE if item_type == ItemType.GEMSTONE else Enum.ZIndex.RUBBLE

	# Setup MovementComponent
	movement_comp.movement_stats.can_use_ladders = false
	movement_comp.movement_stats.can_use_ladders_falling = false

	movement_comp.set_parent_width(get_stacking_size().x)

	# Setup CarryableItemComponent
	carryable_item_comp.item_type = item_type
	carryable_item_comp.weight = weight

	# Gemstone color
	var gem_color: Color = [Color.HOT_PINK, Color.CYAN, Color.YELLOW_GREEN].pick_random()
	if item_type == ItemType.GEMSTONE:
		sprite.modulate = gem_color * 2.0
	elif item_type == ItemType.RUBBLE:
		sprite.modulate = Colors.rand_rubble_color()

	# Light
	if light != null:
		var light_color: Color = gem_color if item_type == ItemType.GEMSTONE else Color.WHITE
		light.color = Color.WHITE.lerp(light_color, 0.5)
		light.energy = light_energy_default

	# SIGNALS
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)
	carryable_item_comp.Signal_OnPickedUp.connect(movement_comp.on_picked_up)
	carryable_item_comp.Signal_OnDropped.connect(movement_comp.on_dropped)
	carryable_item_comp.Signal_OnPickedUp.connect(_on_picked_up)
	carryable_item_comp.Signal_OnDropped.connect(_on_dropped)

	######
	_add_pickup_job()

	Audio.play_at_pos_stream(on_spawned_audio, global_position)
	
	_spawn_animation()


# Add/remove pickup job on pick up / drop
func _on_picked_up() -> void:
	Actions.archive_job(pickup_job, true)
	pickup_job = null

	# reduce light energy when carried
	light.energy = 0.0

func _on_dropped() -> void:
	_add_pickup_job()

	# restore light energy when dropped
	if light != null:
		light.energy = light_energy_default


func _process(delta: float) -> void:
	if light:
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


func get_stacking_size() -> Vector2:
	return stacking_shape.shape.get_rect().size

func _on_new_cell_entered(new_cell: Cell) -> void:
	if new_cell == null or carryable_item_comp.is_in_storage:
		return

	if pickup_job != null:
		pickup_job.center_cell = new_cell
		pickup_job.update_workable_from_cells()


func _on_started_falling(est_fall_height_cells: int) -> void:
	pass


func _on_landed(fall_height_cells: int) -> void:
	# Trigger on cell entered anew to update job status
	_on_new_cell_entered(curr_cell)

	if fall_height_cells >= 0:
		Audio.play_at_pos_stream(on_landed_audio, global_position)


func _to_string() -> String:
	var color := Colors.to_print_color(sprite.modulate)
	var print_name: String = "Rubble" if item_type == ItemType.RUBBLE else "Gemstone"
	return Util.color_string("%s @%s" % [print_name, self._grid_pos], color)


func _spawn_animation() -> void:
	# Start scaled to zero and bright white
	scale = Vector2.ZERO
	modulate = Color(8.0, 8.0, 8.0, 1.0) # HDR white flash

	var tween: Tween = create_tween().set_parallel(true)

	# Plop: scale from 0 to 1 with slight overshoot
	tween.tween_property(self , "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# White flash: fade modulate back to normal color
	tween.tween_property(self , "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
