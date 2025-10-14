extends CanvasLayer
class_name PostProcessCanvasLayer

@onready var color_rect: ColorRect = $StencilColorRect

var post_process_material: ShaderMaterial

func _ready() -> void:
    color_rect.size = get_viewport().get_visible_rect().size # Windows size

    post_process_material = color_rect.material as ShaderMaterial


func _process(delta: float) -> void:
    if post_process_material and Global.camera:
        post_process_material.set_shader_parameter("zoom", Global.camera.zoom_curr)


func update_size(new_size: Vector2) -> void:
    color_rect.size = new_size
    # print("Updated PostProcessCanvasLayer ColorRect Size to: ", color_rect.size)
