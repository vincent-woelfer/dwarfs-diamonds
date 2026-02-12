class_name ActionPointComponent
extends Node2D

## Emitted when interaction completed
signal Signal_OnActionCompleted(action_point: ActionPoint)

# internal
## The action point instance being used
var _curr_action_point: ActionPoint = null

# Reference to the used audio player
var _audio_player: AudioStreamPlayer2D = null

var interaction_timestamp: float = 0.0

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

	interaction_timestamp = Util.now()

	# _audio_player = Audio.play_at_pos("dispose_trash", action_point.global_position)

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


# ########################################################################################################################
# # PRIVATE METHODS
# ########################################################################################################################
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

	if _curr_action_point.type == ActionPoint.ActionType.DISPOSE_RUBBLE:
		done = _dispose_rubble()

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
# ########################################################################################################################
# These return "done = true" if the interaction is completed

func _dispose_rubble() -> bool:
	var carry_comp: CarryComponent = parent.carry_comp

	# Check for rubble disposal
	if Util.has_time_passed(interaction_timestamp, 1.2):
		if carry_comp.is_carrying_item_of_type(Enum.CarryableItemType.RUBBLE):
			print_rich("%s is disposing rubble at %s" % [parent, _curr_action_point])
			carry_comp.drop_all()

			Audio.play_at_pos("dispose_trash", _curr_action_point.get_global_position())

	# Check for done
	if Util.has_time_passed(interaction_timestamp, 1.5):
		return true

	return false
