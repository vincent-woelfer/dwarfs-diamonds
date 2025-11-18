@tool
class_name GridPatternPreview
extends Node2D

var grid_patterns: Array[GridPattern] = []
var colors: Array[Color] = []

var default_color := Color(0, 0, 1.0)

var alpha_fill: float = 0.15
var alpha_border: float = 0.5
var margin_width: float = 2.0

# Offset to visually center the pattern on the grid
var offset_for_editor: Vector2 = Vector2(-0.5, -1.0) * Global.CELL_SIZE_VEC

var dirty: bool = true

func _draw() -> void:
	if not Engine.is_editor_hint() or grid_patterns.is_empty():
		return

	# Setup once
	self.z_index = -100
	var margin_vec: Vector2 = Vector2(margin_width, margin_width)

	# Per grid pattern
	var idx := 0
	for grid_pattern: GridPattern in grid_patterns:
		# Calculate colors
		var color := colors[idx] if idx < colors.size() else default_color
		idx += 1
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
	if not Engine.is_editor_hint():
		return

	# Update grid pattern from parent
	var parent_node := get_parent()
	if parent_node:
		_scan_node(parent_node)

	if dirty:
		dirty = false
		queue_redraw()
		print("redraw")


func _scan_node(node: Object) -> void:
	# check this node's script variables
	for prop in node.get_property_list():
		if prop.type == TYPE_OBJECT:
			var prop_name: String = prop.name
			var value: Variant = node.get(prop_name)
			if value is GridPattern:
				@warning_ignore("unsafe_cast")
				_add_grid_pattern(value as GridPattern, prop_name)

	# recurse into children (only if it's a Node)
	if node is Node:
		for child: Node in (node as Node).get_children():
			_scan_node(child)


func _add_grid_pattern(grid_pattern: GridPattern, variable_name: String) -> void:
	if grid_patterns.has(grid_pattern):
		return

	dirty = true
	grid_patterns.append(grid_pattern)

	# Colors
	var new_color := Colors.get_rand_grid_pattern_color(colors.size())
	colors.append(new_color)
