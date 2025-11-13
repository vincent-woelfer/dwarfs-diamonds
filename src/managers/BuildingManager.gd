class_name BuildingManager
extends Node2D



########################################################################################################################
# PUBLIC METHODS
########################################################################################################################


########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy := DebugDrawProxy.new(self)

# const debug_colors := {
# 	# Points
# 	"point_passable": Color(1.0, 0.6, 0.0, 0.6),
# 	"point_standable": Color(1.0, 0.6, 0.0, 1.0),
# 	"point_disabled": Color(1.0, 0.0, 0.0, 0.0), # Transparent
# }

# const debug_size_point := 5.0

func _debug_draw_in_ui(ui_layer: CanvasItem) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toogle_building_draw"):
		_debug_draw_proxy.visible = not _debug_draw_proxy.visible
		_debug_draw_proxy.queue_redraw()
