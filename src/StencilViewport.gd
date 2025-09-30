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

	print("Stencil Viewport size: ", self.size)
	print("Window size: ", window.size)

	print("Stencil Viewport got world2D: ", self.world_2d)
	print("Parent Viewport got world2D: ", parent_viewport.world_2d)


func _process(delta: float) -> void:
	pass
	# TODO verify this works

	# print("----- Stencil Viewport -----")
	# print("Local  Canvas Transform: ", self.canvas_transform)
	# print("Global Canvas Transform: ", self.global_canvas_transform)
	# print("Parent Local  Canvas Transform: ", parent_viewport.canvas_transform)
	# print("Parent Global Canvas Transform: ", parent_viewport.global_canvas_transform)
	# if parent_viewport:
		# self.canvas_transform = parent_viewport.canvas_transform
		# self.global_canvas_transform = parent_viewport.global_canvas_transform
