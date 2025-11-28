class_name BuildingManager
extends Node2D

var buildings: Array[BuildingBase] = []

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func register_building(building: BuildingBase) -> void:
	if building in buildings:
		return

	buildings.append(building)
	add_child(building)


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################

########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
# var _debug_draw_proxy := DebugDrawProxy.new(self)

# const debug_colors := {
# 	# Points
# 	"point_passable": Color(1.0, 0.6, 0.0, 0.6),
# 	"point_standable": Color(1.0, 0.6, 0.0, 1.0),
# 	"point_disabled": Color(1.0, 0.0, 0.0, 0.0), # Transparent
# }

# const debug_size_point := 5.0

# func _debug_draw_in_ui_absolute(ui_layer: CanvasItem) -> void:
# 	for building in buildings:
# 		if building.building_data == null:
# 			continue

# 		# Get pattern preview (todo improve)
# 		var preview: GridPatternPreview = building.get_child(0) as GridPatternPreview
# 		if preview == null:
# 			continue

# 		# preview
