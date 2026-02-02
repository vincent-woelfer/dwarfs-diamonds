########################################################################################################################
# TOOL SCRIPT - used both in editor and in-game for debugging
########################################################################################################################
@tool
class_name GridPatternVisualization
extends Node2D

# Scanned grid patterns and their colors
var grid_patterns: Array[GridPatternRes] = []
var grid_colors: Array[Color] = []
var grid_patterns_visible: bool = true

# Action points to visualize
var action_points: Array[ActionPointRes] = []
var action_points_visible: bool = true

# Never draw ladder patterns in game to avoid visual clutter (these are drawn in editor only)
var never_draw_because_is_ladder: bool = false

# Visual properties
const alpha_fill: float = 0.11
const alpha_border: float = 0.5
const border_margin_width_px: float = 2.0
const circle_radius_px: float = 0.15 * Global.CELL_SIZE
const circle_alpha: float = 0.6

# Text properties
const label_width := 1.0 * Global.CELL_SIZE
# relative to circle (cell center)
const label_offset := Vector2(0.0, -0.3) * Global.CELL_SIZE_VEC + Vector2(-label_width / 2.0, 0.0)

var font := ThemeDB.fallback_font
var font_size := 14

# Offset to visually center the pattern on the grid
const visual_offset: Vector2 = - Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR

# Dirty flag for redraw and rescan
var needs_redraw: bool
var needs_rescan: bool

########################################################################################################################
# DRAWING
########################################################################################################################
func _draw() -> void:
	# Setup once
	self.z_index = Enum.ZIndex.GRID_PATTERN_VISUALIZATION # Draw above grid/sprites

	###################################
	# GRID PATTERNS
	###################################
	if (not grid_patterns.is_empty()) and grid_patterns_visible:
		var idx := 0
		for grid_pattern: GridPatternRes in grid_patterns:
			# Calculate grid_colors
			var color := grid_colors[idx] if idx < grid_colors.size() else Colors.FALLBACK_COLOR
			var color_fill := Colors.with_alpha(color, alpha_fill)
			var color_border := Colors.with_alpha(color, alpha_border)
			idx += 1

			for grid_pos: Vector2i in grid_pattern.get_local_positions():
				_draw_rect_with_border(grid_pos, color_fill, color_border)

	###################################
	# ACTION POINTS
	###################################
	if (not action_points.is_empty()) and action_points_visible:
		for action_point: ActionPointRes in action_points:
			var color := Colors.get_action_point_color(action_point.type)
			var color_fill := Colors.with_alpha(color, alpha_fill)
			var color_border := Colors.with_alpha(color, alpha_border)

			_draw_rect_with_border(action_point.local_grid_offset, color_fill, color_border)

			# Action circle			
			var circle_pos: Vector2 = ((action_point.local_grid_offset as Vector2) + Vector2(0.5, 0.5)) * Global.CELL_SIZE + visual_offset
			var color_circle := Colors.with_alpha(color, circle_alpha)
			draw_circle(circle_pos, circle_radius_px, color_circle)

			# Text
			var text: String = Enum.to_str(ActionPoint.ActionType, action_point.type)
			var lable_pos: Vector2 = circle_pos + label_offset
			draw_string(font, lable_pos, text, HORIZONTAL_ALIGNMENT_CENTER, label_width, font_size, color)

	
func _draw_rect_with_border(grid_pos: Vector2i, color_fill: Color, color_border: Color) -> void:
	var margin_vec_px: Vector2 = Vector2(border_margin_width_px, border_margin_width_px)

	# Fill
	var pos: Vector2 = grid_pos * Global.CELL_SIZE
	var size: Vector2 = Global.CELL_SIZE_VEC
	var rect := Rect2(pos + visual_offset, size)
	draw_rect(rect, color_fill, true)

	# Border
	pos += margin_vec_px * 0.5
	size -= margin_vec_px
	rect = Rect2(pos + visual_offset, size)
	draw_rect(rect, color_border, false, border_margin_width_px)


########################################################################################################################
# SETUP
########################################################################################################################
func _ready() -> void:
	grid_patterns.clear()
	grid_colors.clear()
	action_points.clear()
	needs_redraw = true
	needs_rescan = true

	# Dev Signals
	EventBus.Signal_DevToogleDrawBuildingPattern.connect(_update_is_visible)
	EventBus.Signal_DevToogleDrawActionPoints.connect(_update_is_visible)
	_update_is_visible()


func _process(_delta: float) -> void:
	# Update grid pattern from parent if rescan needed
	if needs_rescan:
		# Only need to rescan in editor, in-game patterns are static once created
		needs_rescan = Engine.is_editor_hint()
		var old_patterns := grid_patterns.duplicate()
		var old_action_points := action_points.duplicate()
		var parent_node := get_parent()

		if parent_node:
			_scan_node(parent_node)

			if old_patterns != grid_patterns and Engine.is_editor_hint():
				print("%s: GridPatternVisualization updated with %d pattern(s)" % [parent_node.name, grid_patterns.size()])

			if old_action_points != action_points and Engine.is_editor_hint():
				print("%s: GridPatternVisualization updated with %d action point(s)" % [parent_node.name, action_points.size()])

		_update_is_visible()
	
	if needs_redraw:
		needs_redraw = false
		queue_redraw()
		

########################################################################################################################
# SCANNING
########################################################################################################################
func _scan_node(node: Object) -> void:
	# check this node's script variables
	for prop in node.get_property_list():
		if prop.type == TYPE_OBJECT:
			var prop_name: String = prop.name
			var value: Variant = node.get(prop_name)
			
			# Stray GridPatternRes (currently not really used)
			if value is GridPatternRes:
				# Add pattern directly with static color
				@warning_ignore("unsafe_cast")
				_add_grid_pattern(value as GridPatternRes)

			# BuildingDataRes - extract patterns and action points
			elif value is BuildingDataRes:
				# Add all patterns with predefined grid_colors
				@warning_ignore("unsafe_cast")
				_add_building_data(value as BuildingDataRes)

				# Check if ladder
				@warning_ignore("unsafe_cast")
				if (value as BuildingDataRes).name == "Ladder":
					never_draw_because_is_ladder = true

	# recurse into children (only if it's a Node)
	if node is Node:
		for child: Node in (node as Node).get_children():
			_scan_node(child)


func _add_grid_pattern(grid_pattern: GridPatternRes, color: Color = Color.BLACK) -> void:
	if grid_patterns.has(grid_pattern) or grid_pattern == null or grid_pattern.cells.is_empty():
		return

	grid_patterns.append(grid_pattern)

	if color == Color.BLACK:
		# Assign a color from the predefined list
		grid_colors.append(Colors.get_rand_grid_pattern_color(grid_colors.size()))
	else:
		grid_colors.append(color)
		
	needs_redraw = true

func _add_action_point(action_point: ActionPointRes) -> void:
	if action_points.has(action_point) or action_point == null:
		return

	action_points.append(action_point)
	needs_redraw = true


func _add_building_data(building_data: BuildingDataRes) -> void:
	# Grid Patterns
	for pattern_with_color in building_data.get_all_patterns_with_colors():
		var grid_pattern: GridPatternRes = pattern_with_color["pattern"]
		var color: Color = pattern_with_color["color"]
		_add_grid_pattern(grid_pattern, color)

	# Action Points
	for action_point: ActionPointRes in building_data.action_points:
		_add_action_point(action_point)


########################################################################################################################
# INTERNAL
########################################################################################################################
func _update_is_visible() -> void:
	# GridPatterns
	# Exception for ladders, these are ONLY drawn in editor
	if never_draw_because_is_ladder and not Engine.is_editor_hint():
		self.grid_patterns_visible = false
	else:
		self.grid_patterns_visible = Engine.is_editor_hint() or EventBus.dev_draw_building_patterns

	# ActionPoints
	self.action_points_visible = Engine.is_editor_hint() or EventBus.dev_draw_action_points

	needs_redraw = true
