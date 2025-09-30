extends CanvasLayer
class_name PostProcessCanvasLayer

@onready var window: Window = get_tree().root
@onready var color_rect: ColorRect = $StencilColorRect

var level_size: Vector2 = Global.CELL_SIZE_VEC * Vector2(Global.LEVEL_WIDTH, Global.LEVEL_HEIGHT)

func _ready() -> void:
    color_rect.size = get_viewport().get_visible_rect().size # Windows size


func update_size(new_size: Vector2) -> void:
    color_rect.size = new_size
    # print("Updated PostProcessCanvasLayer ColorRect Size to: ", color_rect.size)
