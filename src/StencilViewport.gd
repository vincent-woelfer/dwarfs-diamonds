class_name StencilViewport
extends SubViewport

@onready var parent_viewport: Viewport

func _ready() -> void:
	# Render only layer 2 (the stencil layer)
	self.canvas_cull_mask = (1 << 1)

	parent_viewport = get_parent().get_viewport()

	print("Stencil Viewport got parent viewport: ", parent_viewport)


func _process(delta: float) -> void:
	# TODO verify this works
	
	# print("----- Stencil Viewport -----")
	# print("Local  Canvas Transform: ", self.canvas_transform)
	# print("Global Canvas Transform: ", self.global_canvas_transform)
	# print("Parent Local  Canvas Transform: ", parent_viewport.canvas_transform)
	# print("Parent Global Canvas Transform: ", parent_viewport.global_canvas_transform)
	if parent_viewport:
		self.canvas_transform = parent_viewport.canvas_transform
		# self.global_canvas_transform = parent_viewport.global_canvas_transform
