class_name Item
extends GridObject2D

# THIS IS A SCENE
# Scene Components - Required
@onready var sprite: Sprite2D = $Sprite
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var stacking_shape: CollisionShape2D = $StackingShape

# Scene Components - Optional
@onready var light: PointLight2D = $PointLight

# Used to set Item weight
@export var weight: float = 1.0
@export var item_type: Enum.ItemType

# Storage state
var is_in_storage: bool = false
var storage: AbstractStorage = null

# Pick-up animation state - used by CarryComponent / StockpileComponent
var pick_up_animation_finished: bool = false
var pick_up_animation_start_time: float = 0.0

# Scale tween for pickup animation
var scale_tween: Tween
var target_scale: Vector2 = Vector2.ONE
const in_storage_scale: Vector2 = Vector2.ONE * 0.7


# Sounds
@export var on_spawned_audio: AudioStream
@export var on_landed_audio: AudioStream


# The pickup job associated with this item
var pickup_job: Job = null

# Further Config
var light_energy_default: float = 0.25


# Spawn offset y must be negative to be placed above floor
func setup_item(grid_pos_: Vector2i, spawn_offset: Vector2 = Vector2.ZERO) -> void:
	# Validation
	assert(item_type in Enum.ItemType.values(), "Invalid item type %s" % [item_type])
	setup_grid_object(grid_pos_)
	
	global_position = Global.level.get_cell(grid_pos).get_center_floor_point() + spawn_offset


func _ready() -> void:
	self.z_index = Enum.ZIndex.GEMSTONE if item_type == Enum.ItemType.GEMSTONE else Enum.ZIndex.RUBBLE
	add_to_group(Global.GROUP_CARRYABLE_ITEMS)


	# Setup MovementComponent
	movement_comp.movement_stats.can_use_ladders = false
	movement_comp.movement_stats.can_use_ladders_falling = false

	movement_comp.set_parent_width(get_stacking_size().x)

	# Gemstone color
	var gem_color: Color = [Color.HOT_PINK, Color.CYAN, Color.YELLOW_GREEN].pick_random()
	if item_type == Enum.ItemType.GEMSTONE:
		sprite.modulate = gem_color * 2.0
	elif item_type == Enum.ItemType.RUBBLE:
		sprite.modulate = Colors.rand_rubble_color()

	# Light
	if light != null:
		var light_color: Color = gem_color if item_type == Enum.ItemType.GEMSTONE else Color.WHITE
		light.color = Color.WHITE.lerp(light_color, 0.5)
		light.energy = light_energy_default

	# SIGNALS
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)

	######
	_add_pickup_job()
	Audio.play_at_pos_stream(on_spawned_audio, global_position)
	# _spawn_animation()


func on_picked_up(new_storage: AbstractStorage) -> void:
	is_in_storage = true
	storage = new_storage
	
	pick_up_animation_finished = false
	pick_up_animation_start_time = Util.now()

	tween_to_scale(Vector2.ONE * in_storage_scale)

	Actions.archive_job(pickup_job, true)
	pickup_job = null

	# reduce light energy when carried
	light.energy = 0.0

	movement_comp.on_picked_up()

func on_dropped() -> void:
	is_in_storage = false
	storage = null

	tween_to_scale(Vector2.ONE)

	_add_pickup_job()

	# restore light energy when dropped
	if light != null:
		light.energy = light_energy_default

	movement_comp.on_dropped()


func _process(delta: float) -> void:
	if light:
		var light_rotation_speed_rad_per_sec := deg_to_rad(15)
		light.rotate(light_rotation_speed_rad_per_sec * delta)


func _add_pickup_job() -> void:
	if pickup_job != null:
		return

	pickup_job = Job.new(Job.Type.PICKUP, curr_cell)
	pickup_job.carryable_item = self
	Global.level.job_manager.add_job(pickup_job)

func can_be_picked_up_right_now() -> bool:
	if is_in_storage or movement_comp.is_falling():
		return false

	return true


## This always returns the in-inventory size!
func get_stacking_size() -> Vector2:
	return stacking_shape.shape.get_rect().size * in_storage_scale


func _on_new_cell_entered(new_cell: Cell) -> void:
	if new_cell == null or is_in_storage:
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
	var print_name: String = "Rubble" if item_type == Enum.ItemType.RUBBLE else "Gemstone"
	return Util.color_string("%s @%s" % [print_name, self._grid_pos], color)


func _spawn_animation() -> void:
	var prev_modulate := modulate

	# Start scaled to zero and bright white
	scale = Vector2.ZERO
	modulate = Color(8.0, 8.0, 8.0, 1.0) # HDR white flash

	var tween: Tween = create_tween().set_parallel(true)

	# Plop: scale from 0 to 1 with slight overshoot
	tween.tween_property(self , "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# White flash: fade modulate back to normal color
	tween.tween_property(self , "modulate", prev_modulate, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func tween_to_scale(new_scale: Vector2, duration: float = 0.25) -> void:
	target_scale = new_scale

	if scale_tween:
		scale_tween.kill()

	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_SINE)
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self , "scale", target_scale, duration)
