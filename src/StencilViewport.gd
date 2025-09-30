class_name StencilViewport
extends SubViewport

@onready var window: Window = get_tree().root
@onready var parent_viewport: Viewport = window.get_viewport()

func _ready() -> void:
	# Render only layer 2 (the stencil layer)
	self.canvas_cull_mask = (1 << 1)
	# Ensure parent renders only layer 1
	parent_viewport.canvas_cull_mask = (1 << 0)

	# Enable Stencil Layer on Main Viewport for testing
	# parent_viewport.set_canvas_cull_mask_bit(1, true)

	self.world_2d = parent_viewport.world_2d

	# Size
	self.size = window.size

	# color_rect.size = self.size

	print("Window size: ", window.size)
	print("Stencil Viewport size: ", self.size)


func _process(delta: float) -> void:
	pass
