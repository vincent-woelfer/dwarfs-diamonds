@tool
class_name GridPatternPreview
extends Node2D

var grid_pattern: GridPattern

@export var color := Color(0, 0, 1.0)

var alpha_fill: float = 0.15
var alpha_border: float = 0.5
var margin_width: float = 2.0

# Offset to center the pattern on the grid
var offset_for_editor: Vector2 = Vector2(-0.5, -1.0) * Global.CELL_SIZE_VEC

func _draw() -> void:
	if not grid_pattern or not Engine.is_editor_hint():
		return

	self.z_index = -100

	var margin_vec: Vector2 = Vector2(margin_width, margin_width)

	# Calculate colors
	var color_fill := Colors.with_alpha(color, alpha_fill)
	var color_border := Colors.with_alpha(color, alpha_border)

	for grid_pos: Vector2i in grid_pattern.get_local_positions():
		# Fill
		var pos: Vector2 = grid_pos * Global.CELL_SIZE
		var size: Vector2 = Global.CELL_SIZE_VEC
		var rect := Rect2(pos + offset_for_editor, size)
		draw_rect(rect, color_fill, true)

		# Border
		pos += margin_vec * 0.5
		size -= margin_vec
		rect = Rect2(pos + offset_for_editor, size)
		draw_rect(rect, color_border, false, margin_width)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

		# Update grid pattern from parent
		var parent_node := get_parent()
		if parent_node and parent_node is BuildingBase:
			var building_base: BuildingBase = parent_node as BuildingBase
			# print(building_base)
			grid_pattern = GridPattern.new([Vector2i.LEFT], Vector2i.ZERO)
			# grid_pattern = building_base.grid_pattern
