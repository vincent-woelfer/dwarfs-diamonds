class_name DecoTorch
extends Node2D

@onready var light: Light2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_sheet: SpriteFrames = animated_sprite.sprite_frames as SpriteFrames

var grid_pos: Vector2i

# Hardcoded torch sizes from sprite sheet
var torch_sizes: Array[float] = [1.0, 0.6, 0.8, 1.2]

var default_light_energy: float

func _ready() -> void:
    # Signals
    EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)
    _dev_toogle_light(EventBus.dev_light_on)

    animated_sprite.frame_changed.connect(_on_new_frame)

    animated_sprite.flip_h = (randf() < 0.5) as bool
    animated_sprite.play()

    # Read defaults
    default_light_energy = light.energy

    
func place_in_cell(cell: Cell) -> void:
    self.grid_pos = cell.grid_pos

    # Left/right random offset
    # self.position.x = randf_range(0.2, 0.8) * Global.CELL_SIZE
    self.position.x = Global.CELL_SIZE / 2.0

    # On floor
    self.position.y = Global.CELL_SIZE / 2.0


func _on_new_frame() -> void:
    var frame_index: int = animated_sprite.frame % animated_sprite.sprite_frames.get_frame_count("idle")
    var factor: float = torch_sizes[frame_index]
    var curr_energy: float = light.energy
    var target_energy: float = default_light_energy * factor

    var time_for_one_frame: float = sprite_sheet.get_frame_duration("idle", frame_index) / (sprite_sheet.get_animation_speed("idle") * abs(animated_sprite.get_playing_speed()))

    # Tween to new energy in half the time. So 1/2 tween, 1/2 hold
    var tween := create_tween()
    tween.tween_property(light, "energy", target_energy, time_for_one_frame / 2.0)
    
    
func _dev_toogle_light(is_light_on: bool) -> void:
    light.enabled = is_light_on
