class_name DwarfDebugDraw
extends Node2D

########################################################################################################################
# Data
########################################################################################################################
## Parent dwarf reference
var dwarf: Dwarf

var _debug_draw_proxy_relative := DebugDrawProxy.new(self, true)
var _debug_draw_proxy_absolute := DebugDrawProxy.new(self, false)

const debug_state_colors := {
	Dwarf.State.IDLE: Color.WHITE, # White
	Dwarf.State.MOVING: Color(1.0, 1.0, 0.0), # Yellow
	Dwarf.State.MINING: Color(1.0, 0.0, 0.0), # Red
	Dwarf.State.BUILDING: Color(0.0, 1.0, 0.0), # GREEN
	Dwarf.State.FALLING: Color(1.0, 0.0, 1.0), # Magenta
	Dwarf.State.DYING: Color(0.0, 0.0, 0.0), # Black
	Dwarf.State.ACTION: Color(0.2, 0.2, 1.0), # Blue
}

const debug_label_width := 1.0 * Global.CELL_SIZE
const debug_label_offset := Vector2(0.0, -0.8) * Global.CELL_SIZE_VEC + Vector2(-debug_label_width / 2.0, 0.0)
const debug_occupied_cell_alpha := 0.1

var debug_font := ThemeDB.fallback_font
var debug_font_size := 20


########################################################################################################################
# Methods
########################################################################################################################
func _ready() -> void:
	# A bit hacky but delay init to after dwarf (parent) is ready
	await get_tree().process_frame

	dwarf = get_parent() as Dwarf
	assert(dwarf != null, "DwarfDebugDraw must be a child of a Dwarf node")

	# Dev Signals
	EventBus.Signal_DevToggleLight.connect(_dev_toggle_light)
	EventBus.Signal_DevToggleDwarfDrawInfo.connect(_dev_toggle_dwarf_draw_info)

	# Init dev states according to global vars
	self._dev_toggle_light.call_deferred()
	self._dev_toggle_dwarf_draw_info.call_deferred()

	# Dwarf Signals
	dwarf.Signal_OnNewCellEntered.connect(_on_new_cell_entered)


## Triggered by movement component
func _on_new_cell_entered(new_cell: Cell) -> void:
	_debug_draw_proxy_absolute.queue_redraw()


## Called by DebugDrawProxy
func debug_draw_in_ui_relative(ui_layer: CanvasItem) -> void:
	print("4444")
	if not EventBus.dev_draw_dwarf_info:
		return

	print("5555")

	# Status Text
	var color_actual: Color = debug_state_colors.get(dwarf.sm.state, Colors.FALLBACK_COLOR)
	var text: String = Enum.to_str(Dwarf.State, dwarf.sm.state)
	print_rich("DRAWING %s Dwarf State: %s" % [dwarf, text])

	ui_layer.draw_string(debug_font, debug_label_offset, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, debug_font_size, color_actual)

	# Add movement component state below, smaller
	text = dwarf.movement_comp.get_state_string()
	var offset_second := debug_label_offset + Vector2(0.0, debug_font_size + 4.0)
	var size_second: int = roundi(debug_font_size * 0.65)
	ui_layer.draw_string(debug_font, offset_second, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, size_second, color_actual)


## Called by DebugDrawProxy
func debug_draw_in_ui_absolute(ui_layer: CanvasItem) -> void:
	if not EventBus.dev_draw_dwarf_info:
		return

	# Draw Occupied Cell
	var cell_to_draw: Cell = dwarf.curr_cell

	if cell_to_draw != null:
		var offset: Vector2 = cell_to_draw.global_position
		var cell_poly_points := cell_to_draw.visual.poly_points.duplicate()
		for i in range(cell_poly_points.size()):
			cell_poly_points[i] += offset

		ui_layer.draw_colored_polygon(cell_poly_points, Colors.with_alpha(dwarf.dwarf_color, debug_occupied_cell_alpha))


func _dev_toggle_light() -> void:
	if dwarf.light != null:
		dwarf.light.enabled = EventBus.dev_light_on


func _dev_toggle_dwarf_draw_info() -> void:
	_debug_draw_proxy_absolute.queue_redraw()
	_debug_draw_proxy_relative.queue_redraw()

	if dwarf.movement_comp.has_path():
		dwarf.movement_comp.path.set_debug_draw_enabled(EventBus.dev_draw_dwarf_info)
