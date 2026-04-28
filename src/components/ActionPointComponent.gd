class_name ActionPointComponent
extends Node2D

## Emitted when interaction completed
signal Signal_OnActionCompleted(action_point: ActionPoint)

# internal
## The action point instance being used
var _curr_action_point: ActionPoint = null

# Reference to the used audio player
var _audio_player: AudioStreamPlayer2D = null

## Timestamp of when interaction started, used for timing logic
var action_started_timestamp: float = 0.0

## Timestamp for repeated steps of one action, used for timing logic
var repeated_tick_timestamp: float = 0.0

# Reference to parent dwarf. Needs to be a dwarf since this is tighly coupled
@onready var parent: Dwarf = get_parent()

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func start_action(action_point: ActionPoint) -> bool:
	# Check for errors
	if is_currently_interacting() or (action_point == null) or not can_interact_at_all(action_point):
		assert(false)
		return false

	if parent.grid_pos != action_point.grid_pos:
		print_rich("%s tried to interact with AP %s but is too far away, aborting" % [ self , action_point])
		return false

	_curr_action_point = action_point

	action_started_timestamp = Util.now()
	repeated_tick_timestamp = Util.now()

	return true


func stop_interacting() -> void:
	_curr_action_point = null

	if _audio_player != null:
		Audio.stop_player(_audio_player)
		_audio_player = null


func is_currently_interacting() -> bool:
	return _curr_action_point != null


## Can this action point component interact with this action point at all?
## Used to filter jobs
func can_interact_at_all(action_point: ActionPoint) -> bool:
	if action_point == null:
		return false

	if not action_point.is_active:
		return false

	return true


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
# func _ready() -> void:
	# SIGNALS

func _physics_process(delta: float) -> void:
	# Exit if not interacting
	if not is_currently_interacting():
		return

	# Check for errors
	if _curr_action_point == null:
		stop_interacting()
		return

	# Actual interaction logic
	var done := false

	if _curr_action_point.type == ActionPoint.ActionType.DROPOFF_RUBBLE:
		done = _dropoff_rubble()

	elif _curr_action_point.type == ActionPoint.ActionType.DROPOFF_GEMSTONE:
		done = _dropoff_gemstone()

	else:
		push_error("Unsupported action point type %s" % [Enum.to_str(ActionPoint.ActionType, _curr_action_point.type)])
		stop_interacting()
		return

	# Finish interaction if done
	if done:
		Signal_OnActionCompleted.emit(_curr_action_point)
		stop_interacting()


# ########################################################################################################################
# INTERACTION LOGIC
# called every frame from _physics_process while interacting, returns true if interaction is completed
# ########################################################################################################################
func _dropoff_rubble() -> bool:
	const dispose_time := 0.75
	const after_last_time := 0.3

	var carry_comp: CarryComponent = parent.carry_comp
	var has_rubble := carry_comp.is_carrying_item_of_type(Enum.ItemType.RUBBLE)

	# Check for rubble disposal
	if has_rubble and Util.has_time_passed(repeated_tick_timestamp, dispose_time):
		var rubble: Item = carry_comp.get_items_of_type(Enum.ItemType.RUBBLE)[-1]

		# Transfer
		carry_comp.transfer_to_other_storage(rubble, _curr_action_point.storage._storage)

		repeated_tick_timestamp = Util.now()

		Audio.play_at_pos("dispose_trash", _curr_action_point.global_position)

	# Check for done - 0.5 after last rubble was deleted
	if not has_rubble and Util.has_time_passed(repeated_tick_timestamp, after_last_time):
		return true

	return false


func _dropoff_gemstone() -> bool:
	const dispose_time := 0.35
	const after_last_time := 0.5

	var carry_comp: CarryComponent = parent.carry_comp
	var has_gemstone := carry_comp.is_carrying_item_of_type(Enum.ItemType.GEMSTONE)

	# Check for gemstone disposal
	if has_gemstone and Util.has_time_passed(repeated_tick_timestamp, dispose_time):
		carry_comp.delete(carry_comp.get_items_of_type(Enum.ItemType.GEMSTONE)[-1])
		repeated_tick_timestamp = Util.now()

		Global.level.level_stats_manager.update_gemstones_collected(1)

	# Check for done - 0.5 after last rubble was deleted
	if not has_gemstone and Util.has_time_passed(repeated_tick_timestamp, after_last_time):
		return true

	return false
