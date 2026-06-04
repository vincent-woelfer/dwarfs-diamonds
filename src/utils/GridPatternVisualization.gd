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
# Rectangles
const alpha_fill: float = 0.11
const alpha_border: float = 0.5
const border_margin_width_px: float = 2.0

# Circle
const circle_radius_px: float = 0.125 * Global.CELL_SIZE
const circle_alpha: float = 0.6

# Text properties
const label_font_size := 14
var label_font := ThemeDB.fallback_font
const label_width := 1.3 * Global.CELL_SIZE
const label_vert_spacing := 4.0

# Dirty flag for redraw and rescan
var needs_redraw: bool
var needs_rescan: bool


########################################################################################################################
# DRAWING
########################################################################################################################
# ATTENTION: Everything must be offset by -Global.CELL_OFFSET_CENTER_FLOOR to be drawn correctly.
# This is because in editor (0,0) is not the top-left corner of cell (0,0) but the center of the floor tile.
# This is because we want objects/dwarfs to be centered on the floor.
########################################################################################################################
func _draw() -> void:
	###################################
	# GRID PATTERNS
	###################################
	if not grid_patterns.is_empty() and grid_patterns_visible:
		var idx := 0
		for grid_pattern: GridPatternRes in grid_patterns:
			# Calculate grid_colors
			var grid_color := grid_colors[idx] if idx < grid_colors.size() else Colors.FALLBACK_COLOR
			var color_fill := Colors.with_alpha(grid_color, alpha_fill)
			var color_border := Colors.with_alpha(grid_color, alpha_border)
			idx += 1

			for grid_pos: Vector2i in grid_pattern.get_positions():
				_draw_rect_with_border(grid_pos, color_fill, color_border)

	###################################
	# ACTION POINTS
	###################################
	# Create dict with total num APs per grid_pos and running index to calculate offsets for multiple APs on the same cell
	var grid_pos_total_num_aps: Dictionary[Vector2i, int] = {}
	var grid_pos_current_idx: Dictionary[Vector2i, int] = {}
	for action_point: ActionPointRes in action_points:
		var pos: Vector2i = action_point.grid_offset
		grid_pos_total_num_aps[pos] = grid_pos_total_num_aps.get(pos, 0) + 1
		grid_pos_current_idx[pos] = 0

	# Actually draw action points
	if not action_points.is_empty() and action_points_visible:
		for action_point: ActionPointRes in action_points:
			var ap_color := Colors.get_action_point_color(action_point.type)

			var cell_center_pos: Vector2 = (action_point.grid_offset as Vector2) * Global.CELL_SIZE_VEC + Global.CELL_OFFSET_CENTER - Global.CELL_OFFSET_CENTER_FLOOR
			var total_num_aps: int = grid_pos_total_num_aps.get(action_point.grid_offset, 1)
			var current_idx: int = grid_pos_current_idx.get(action_point.grid_offset, 0)
			grid_pos_current_idx[action_point.grid_offset] = current_idx + 1

			# Cell center, shifted upwards by (total label size / 2), corrected for label size
			var combined_label_height := total_num_aps * label_font_size + (total_num_aps - 1) * label_vert_spacing
			var label_base_pos: Vector2 = cell_center_pos - Vector2(0, combined_label_height * 0.5) - Vector2(label_width, -label_font_size) * 0.5
			var label_pos: Vector2 = label_base_pos + Vector2(0, current_idx * (label_font_size + label_vert_spacing)) # Shift down for each additional AP on the same cell

			# Text
			var label_text: String = Enum.to_str(ActionPoint.ApType, action_point.type)
			draw_string_outline(label_font, label_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, label_width, label_font_size, 2, Color.BLACK)
			draw_string(label_font, label_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, label_width, label_font_size, ap_color)

	
func _draw_rect_with_border(grid_pos: Vector2i, color_fill: Color, color_border: Color) -> void:
	var margin_vec_px: Vector2 = Vector2(border_margin_width_px, border_margin_width_px)

	# Fill
	var pos: Vector2 = grid_pos * Global.CELL_SIZE
	var size: Vector2 = Global.CELL_SIZE_VEC
	var rect := Rect2(pos - Global.CELL_OFFSET_CENTER_FLOOR, size)
	draw_rect(rect, color_fill, true)

	# Border
	pos += margin_vec_px * 0.5
	size -= margin_vec_px
	rect = Rect2(pos - Global.CELL_OFFSET_CENTER_FLOOR, size)
	draw_rect(rect, color_border, false, border_margin_width_px)


########################################################################################################################
# SETUP
########################################################################################################################
func _ready() -> void:
	self.z_index = Enum.ZIndex.GRID_PATTERN_VISUALIZATION

	grid_patterns.clear()
	grid_colors.clear()
	action_points.clear()
	needs_redraw = true
	needs_rescan = true

	# Dev Signals
	EventBus.Signal_DevToggleDrawBuildingPattern.connect(_update_is_visible)
	EventBus.Signal_DevToggleDrawActionPoints.connect(_update_is_visible)
	_update_is_visible()


func refresh() -> void:
	needs_rescan = true


func _process(_delta: float) -> void:
	# Update grid pattern from parent if rescan needed
	if needs_rescan:
		# Only need to rescan in editor, in-game patterns are static once created
		needs_rescan = Engine.is_editor_hint() # Only rescan in editor, in-game patterns are static once created
		var old_patterns := grid_patterns.duplicate()
		var old_action_points := action_points.duplicate()
		var parent_node := get_parent()

		if parent_node:
			grid_patterns.clear()
			grid_colors.clear()
			action_points.clear()

			_scan_node_recursively(parent_node)

			if Engine.is_editor_hint():
				if old_patterns != grid_patterns or old_action_points != action_points:
					print("%s: GridPatternVisualization updated with %d patterns and %d APs" % [parent_node.name, grid_patterns.size(), action_points.size()])

		_update_is_visible()
	
	if needs_redraw:
		needs_redraw = false
		queue_redraw()
		

########################################################################################################################
# SCANNING
########################################################################################################################
func _scan_node_recursively(node: Object) -> void:
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
				if (value as BuildingDataRes).type == Enum.BuildingType.LADDER:
					never_draw_because_is_ladder = true

	# recurse into children (only if it's a Node)
	if node is Node:
		for child: Node in (node as Node).get_children():
			_scan_node_recursively(child)


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
