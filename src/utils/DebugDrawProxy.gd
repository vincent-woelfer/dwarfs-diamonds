class_name DebugDrawProxy
extends Node2D

var target: Node2D
var follow_target: bool = true

func _init(target_: Node2D, follow_target_: bool = true) -> void:
	target = target_
	follow_target = follow_target_
	if not follow_target:
		self.global_position = Vector2.ZERO

	# TODO maybe use screen space layer if not following target?
	Global.ui_canvas_layer_world_space.add_child(self)


func _process(delta: float) -> void:
	if not target:
		queue_free()
		return

	# Needs to update the positon every frame, not every redraw
	if follow_target:
		self.global_position = target.global_position
	else:
		self.global_position = Vector2.ZERO


func _draw() -> void:
	if not target:
		queue_free()
		return

	# Relative draw call
	if follow_target:
		if target.has_method("_debug_draw_in_ui"):
			if self.visible:
				@warning_ignore("UNSAFE_METHOD_ACCESS")
				target._debug_draw_in_ui(self)

		else:
			push_error("DebugDrawProxy: Target %s does not have method _debug_draw_in_ui" % [target])

	# Absolute draw call
	else:
		if target.has_method("_debug_draw_in_ui_absolute"):
			if self.visible:
				@warning_ignore("UNSAFE_METHOD_ACCESS")
				target._debug_draw_in_ui_absolute(self)
