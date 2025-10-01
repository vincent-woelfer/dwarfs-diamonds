class_name StencilViewport
extends SubViewport

@onready var window: Window = get_tree().root
@onready var root_viewport: Viewport = window.get_viewport()

func _ready() -> void:
	# Render only layer 2 (the stencil layer)
	self.canvas_cull_mask = Util.LAYER_2

	# Ensure root-viewport renders only layer 1
	root_viewport.canvas_cull_mask = Util.LAYER_1

	# Enable Stencil Layer on Main Viewport for testing
	# root_viewport.set_canvas_cull_mask_bit(1, true)

	self.world_2d = root_viewport.world_2d
	self.size = window.size


func update_size(new_size: Vector2) -> void:
	self.size = new_size
	# print("Updated Stencil-Viewport-Size to: ", self.size)
