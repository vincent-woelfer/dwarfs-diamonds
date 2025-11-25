########################################################################################################################
# TOOL SCRIPT
########################################################################################################################
@tool
class_name GridPatternPreview
extends Node2D

var grid_patterns: Array[GridPattern] = []
var colors: Array[Color] = []

var alpha_fill: float = 0.15
var alpha_border: float = 0.5
var margin_width: float = 2.0

# Offset to visually center the pattern on the grid
var offset_for_editor: Vector2 = - Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR

var dirty: bool = true


func _draw() -> void:
	if not _should_draw() or grid_patterns.is_empty():
		return

	# Setup once
	self.z_index = 1 # Draw above grid/sprites
	var margin_vec: Vector2 = Vector2(margin_width, margin_width)

	# Per grid pattern
	var idx := 0
	for grid_pattern: GridPattern in grid_patterns:
		# Calculate colors
		var color := colors[idx] if idx < colors.size() else Colors.DEFAULT
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


func _ready() -> void:
	grid_patterns.clear()
	colors.clear()
	dirty = true

func _process(_delta: float) -> void:
	if not _should_draw():
		# TODO remove drawn patterns somehow
		# TODO add flag so this gets called exactly once when toggled off
		queue_redraw()
		return

	# Update grid pattern from parent
	var parent_node := get_parent()
	if parent_node:
		_scan_node(parent_node)

	if dirty:
		dirty = false
		queue_redraw()
		if parent_node:
			print("%s: GridPatternPreview updated with %d pattern(s)" % [parent_node.name, grid_patterns.size()])
		else:
			print("null-parent: GridPatternPreview updated with %d pattern(s)" % [grid_patterns.size()])


func _scan_node(node: Object) -> void:
	# check this node's script variables
	for prop in node.get_property_list():
		if prop.type == TYPE_OBJECT:
			var prop_name: String = prop.name
			var value: Variant = node.get(prop_name)
			if value is GridPattern:
				# Add pattern directly with static color
				@warning_ignore("unsafe_cast")
				_add_grid_pattern(value as GridPattern)
			elif value is BuildingData:
				# Add all patterns with predefined colors
				@warning_ignore("unsafe_cast")
				_add_building_data(value as BuildingData)

	# recurse into children (only if it's a Node)
	if node is Node:
		for child: Node in (node as Node).get_children():
			_scan_node(child)


func _add_grid_pattern(grid_pattern: GridPattern, color: Color = Color.BLACK) -> void:
	if grid_patterns.has(grid_pattern) or grid_pattern == null or grid_pattern.pattern.is_empty():
		return

	grid_patterns.append(grid_pattern)

	if color == Color.BLACK:
		# Assign a color from the predefined list
		colors.append(Colors.get_rand_grid_pattern_color(colors.size()))
	else:
		colors.append(color)
		
	dirty = true


func _add_building_data(building_data: BuildingData) -> void:
	for pattern_with_color in building_data.get_all_patterns_with_colors():
		var grid_pattern: GridPattern = pattern_with_color["pattern"]
		var color: Color = pattern_with_color["color"]
		_add_grid_pattern(grid_pattern, color)


func _should_draw() -> bool:
	return Engine.is_editor_hint() or Global.draw_debug_building_patterns
