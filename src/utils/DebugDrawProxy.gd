class_name DebugDrawProxy
extends Node2D

var target: Node2D
var follow_target: bool = true

const method_draw_in_ui_relative := "debug_draw_in_ui_relative"
const method_draw_in_ui_absolute := "debug_draw_in_ui_absolute"


func _init(target_: Node2D, follow_target_: bool = true) -> void:
	target = target_
	follow_target = follow_target_
	if not follow_target:
		self.global_position = Vector2.ZERO

	# TODO maybe use screen space layer if not following target?
	if not Engine.is_editor_hint():
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
		print("1")
		if target.has_method(method_draw_in_ui_relative):
			print("2")
			if self.visible:
				print("3")
				@warning_ignore("UNSAFE_METHOD_ACCESS")
				target.debug_draw_in_ui_relative(self)
		else:
			push_error("DebugDrawProxy: Target %s does not have method %s" % [target, method_draw_in_ui_relative])

	# Absolute draw call
	else:
		if target.has_method(method_draw_in_ui_absolute):
			if self.visible:
				@warning_ignore("UNSAFE_METHOD_ACCESS")
				target.debug_draw_in_ui_absolute(self)
		else:
			push_error("DebugDrawProxy: Target %s does not have method %s" % [target, method_draw_in_ui_absolute])
