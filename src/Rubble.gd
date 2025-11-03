class_name Rubble
extends GridObject2D

# Scene Components
@onready var sprite: Sprite2D = $Sprite2D
@onready var movement_comp: MovementComponent = $MovementComponent

func setup(grid_pos_: Vector2i, sample_offset_: Vector2 = Global.VERT_OFFSET_SMALL) -> void:
	super.setup(grid_pos_, sample_offset_)


func _ready() -> void:
	global_position = Global.level.get_cell(grid_pos).get_floor_point()
	global_position.y -= Global.CELL_SIZE * 0.3 # Let rubble fall on spawn

	movement_comp.movement_capabilities.can_use_ladders = false
	movement_comp.movement_capabilities.can_use_ladders_when_falling = false

	# SIGNALS
	# EventBus.Signal_NavUpdated.connect(_on_nav_updated)

	movement_comp.Signal_MovementDirectionChanged.connect(_on_movement_direction_changed)
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)

	# Start falling	immediately
	movement_comp.sm.transition_to(MovementComponent.State.FALLING)

func _on_movement_direction_changed(new_dir: Vector2) -> void:
	pass
	# if new_dir.x != 0:
		# animated_sprite.flip_h = new_dir.x < 0


func _on_started_falling() -> void:
	pass


func _on_landed(fall_height_cells: int) -> void:
	pass
	# if fall_height_cells > 1:
		# audio_player.stream = Audio.sounds.get("dwarf_on_landing")
		# audio_player.play()
