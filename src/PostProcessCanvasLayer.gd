extends CanvasLayer
class_name PostProcessCanvasLayer

@onready var color_rect: ColorRect = $StencilColorRect

func _ready() -> void:
    color_rect.size = get_viewport().get_visible_rect().size # Windows size


func update_size(new_size: Vector2) -> void:
    color_rect.size = new_size
    # print("Updated PostProcessCanvasLayer ColorRect Size to: ", color_rect.size)
