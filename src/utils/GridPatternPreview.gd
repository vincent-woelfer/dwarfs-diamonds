########################################################################################################################
# TOOL SCRIPT
########################################################################################################################
@tool
class_name GridPatternPreview
extends Node2D

# Scanned grid patterns and their colors
var grid_patterns: Array[GridPattern] = []
var grid_colors: Array[Color] = []

# Never draw ladder patterns in game to avoid visual clutter (these are drawn in editor only)
var never_draw_because_is_ladder: bool = false

# Visual properties
const alpha_fill: float = 0.15
const alpha_border: float = 0.5
const margin_width: float = 2.0

# Offset to visually center the pattern on the grid
const visual_offset: Vector2 = - Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR

# Dirty flag for redraw and rescan
var needs_redraw: bool
var needs_rescan: bool


func _draw() -> void:
	if grid_patterns.is_empty():
		return

	# Setup once
	self.z_index = 1 # Draw above grid/sprites
	var margin_vec: Vector2 = Vector2(margin_width, margin_width)

	# Per grid pattern
	var idx := 0
	for grid_pattern: GridPattern in grid_patterns:
		# Calculate grid_colors
		var color := grid_colors[idx] if idx < grid_colors.size() else Colors.FALLBACK_COLOR
		idx += 1
		var color_fill := Colors.with_alpha(color, alpha_fill)
		var color_border := Colors.with_alpha(color, alpha_border)

		for grid_pos: Vector2i in grid_pattern.get_local_positions():
			# Fill
			var pos: Vector2 = grid_pos * Global.CELL_SIZE
			var size: Vector2 = Global.CELL_SIZE_VEC
			var rect := Rect2(pos + visual_offset, size)
			draw_rect(rect, color_fill, true)

			# Border
			pos += margin_vec * 0.5
			size -= margin_vec
			rect = Rect2(pos + visual_offset, size)
			draw_rect(rect, color_border, false, margin_width)


func _ready() -> void:
	grid_patterns.clear()
	grid_colors.clear()
	needs_redraw = true
	needs_rescan = true

	EventBus.Signal_DevToogleDrawBuildingPattern.connect(_update_is_visible)


func _process(_delta: float) -> void:
	# Update grid pattern from parent if rescan needed
	if needs_rescan:
		# Only need to rescan in editor, in-game patterns are static once created
		needs_rescan = Engine.is_editor_hint()
		var parent_node := get_parent()
		if parent_node:
			_scan_node(parent_node)
			if Engine.is_editor_hint():
				print("%s: GridPatternPreview updated with %d pattern(s)" % [parent_node.name, grid_patterns.size()])
		else:
			if Engine.is_editor_hint():
				print("null-parent: GridPatternPreview updated with %d pattern(s)" % [grid_patterns.size()])

		_update_is_visible()
	
	if needs_redraw:
		needs_redraw = false
		queue_redraw()
		

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
				# Add all patterns with predefined grid_colors
				@warning_ignore("unsafe_cast")
				_add_building_data(value as BuildingData)

				# Check if ladder
				@warning_ignore("unsafe_cast")
				if (value as BuildingData).name == "Ladder":
					never_draw_because_is_ladder = true

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
		grid_colors.append(Colors.get_rand_grid_pattern_color(grid_colors.size()))
	else:
		grid_colors.append(color)
		
	needs_redraw = true


func _add_building_data(building_data: BuildingData) -> void:
	for pattern_with_color in building_data.get_all_patterns_with_colors():
		var grid_pattern: GridPattern = pattern_with_color["pattern"]
		var color: Color = pattern_with_color["color"]
		_add_grid_pattern(grid_pattern, color)


func _update_is_visible() -> void:
	var should_be_visible: bool

	# Exception for ladders, these are ONLY drawn in editor
	if never_draw_because_is_ladder and not Engine.is_editor_hint():
		should_be_visible = false
	else:
		should_be_visible = Engine.is_editor_hint() or EventBus.dev_draw_building_patterns

	# Apply
	self.visible = should_be_visible
