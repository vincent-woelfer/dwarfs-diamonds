class_name DecoTorch
extends Node2D

@onready var light: Light2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var grid_pos: Vector2i

func _ready() -> void:
    EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)
    _dev_toogle_light(EventBus.dev_light_on)

    animated_sprite.flip_h = (randf() < 0.5) as bool
    animated_sprite.play()


func place_in_cell(cell: Cell) -> void:
    self.grid_pos = cell.grid_pos

    # Left/right random offset
    # self.position.x = randf_range(0.2, 0.8) * Global.CELL_SIZE
    self.position.x = Global.CELL_SIZE / 2.0

    # On floor
    self.position.y = Global.CELL_SIZE / 2.0


func _dev_toogle_light(is_light_on: bool) -> void:
    light.enabled = is_light_on
