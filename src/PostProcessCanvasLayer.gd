extends CanvasLayer
class_name PostProcessCanvasLayer

@onready var window: Window = get_tree().root
@onready var color_rect: ColorRect = $StencilColorRect

func _ready() -> void:
    color_rect.size = window.size

    print("PostProcessCanvasLayer Viewport: ", get_viewport())
    print("PostProcessCanvasLayer ColorRect Size: ", color_rect.size)

    # print("PostProcessCanvasLayer size: ", self.get_viewport())
