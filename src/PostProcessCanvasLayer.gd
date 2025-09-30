extends CanvasLayer
class_name PostProcessCanvasLayer

@onready var window: Window = get_tree().root
@onready var color_rect: ColorRect = $StencilColorRect

var level_size: Vector2 = Global.CELL_SIZE_VEC * Vector2(Global.LEVEL_WIDTH, Global.LEVEL_HEIGHT)

func _ready() -> void:
    color_rect.position = Vector2.ZERO
    color_rect.size = level_size

    print("PostProcessCanvasLayer Viewport: ", get_viewport())
    print("PostProcessCanvasLayer ColorRect Size: ", color_rect.size)

    # print("PostProcessCanvasLayer size: ", self.get_viewport())
