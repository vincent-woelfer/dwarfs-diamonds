class_name DebugDrawProxy
extends Node2D

var target: Node2D

func _init(target_: Node2D) -> void:
    target = target_
    Global.ui_canvas_layer.add_child(self)


func _process(delta: float) -> void:
    if not target:
        queue_free()
        return

    self.global_position = target.global_position


func _draw() -> void:
    if not target:
        queue_free()
        return

    # Not enough, needs to update the positon every frame, not every redraw
    #self.global_position = target.global_position

    if target.has_method("_debug_draw_in_ui"):
        if self.visible:
            @warning_ignore("UNSAFE_METHOD_ACCESS")
            target._debug_draw_in_ui(self)

    else:
        push_error("DebugDrawProxy: Target %s does not have method _debug_draw_in_ui" % [target])
