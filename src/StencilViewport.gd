class_name StencilViewport
extends SubViewport

@onready var window: Window = get_tree().root
@onready var root_viewport: Viewport = window.get_viewport()

func _ready() -> void:
	# For this stencil-viewport render only layer 2 (the stencil layer)
	self.canvas_cull_mask = Util.LAYER_2

	# Ensure the root-viewport renders only layer 1 (normal game-world layer)
	# Set this to layer 2 to debug the stencil buffer
	root_viewport.canvas_cull_mask = Util.LAYER_1

	self.world_2d = root_viewport.world_2d
	self.size = window.size


func update_size(new_size: Vector2) -> void:
	self.size = new_size
	# print("Updated Stencil-Viewport-Size to: ", self.size)
