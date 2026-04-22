@tool
class_name DecoTorch
extends DecoBase

########################################################################################################################
# Scene Nodes
########################################################################################################################
@onready var light: Light2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var sprite_sheet: SpriteFrames = animated_sprite.sprite_frames as SpriteFrames

# Hardcoded torch sizes from sprite sheet
const torch_sizes: Array[float] = [1.0, 0.6, 0.8, 1.2]
const animation_name: String = "idle"

var default_light_energy: float

########################################################################################################################
# SETUP
########################################################################################################################
func place_in_cell(cell: Cell) -> void:
    super.place_in_cell(cell)

    # Left/right random offset
    # self.position.x = randf_range(0.2, 0.8) * Global.CELL_SIZE
    self.position.x = Global.CELL_SIZE / 2.0

    # On wall
    self.position.y = Global.CELL_SIZE / 2.0

func _ready() -> void:
    # Dev Signals
    EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)
    _dev_toogle_light()

    # Signals
    animated_sprite.frame_changed.connect(_on_new_frame)

    # Read defaults
    default_light_energy = light.energy

    # Randomize flip & speed
    animated_sprite.flip_h = (randf() < 0.5) as bool
    animated_sprite.speed_scale = randf_range(0.8, 1.2)

    # Start animation
    animated_sprite.play(animation_name)
    animated_sprite.set_frame_and_progress(randi_range(0, torch_sizes.size() - 1), randf())

    # Normal Map Depth
    light.set_height(30.0)
   

static func instantiate() -> DecoTorch:
    var torch_scene: PackedScene = preload('res://scenes/deco/DecoTorch.tscn')
    var instance: DecoTorch = torch_scene.instantiate() as DecoTorch
    return instance


func _on_new_frame() -> void:
    var frame_index: int = animated_sprite.frame % animated_sprite.sprite_frames.get_frame_count(animation_name)
    var factor: float = torch_sizes[frame_index]
    var curr_energy: float = light.energy
    var target_energy: float = default_light_energy * factor

    # Calculate time for one frame based on animation speed
    var frame_duration: float = sprite_sheet.get_frame_duration(animation_name, frame_index)
    var anim_speed: float = sprite_sheet.get_animation_speed(animation_name) * abs(animated_sprite.get_playing_speed())
    var time_for_one_frame: float = frame_duration / anim_speed

    # Tween to new energy in half the time. So 1/2 tween, 1/2 hold
    var tween := create_tween()
    tween.tween_property(light, "energy", target_energy, time_for_one_frame / 2.0)
    
    
func _dev_toogle_light() -> void:
    light.enabled = EventBus.dev_light_on
