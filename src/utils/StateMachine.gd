class_name StateMachine
extends RefCounted

########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################
# ENTER actually enters that state and triggers components
# EXIT stops components but task-finishing logic is handled where exit transition is called (mostly signal handlers).
# Transitions from within _exit functions are NOT ALLOWED
# Transitions from within _enter (as "enter checks") are allowed!
########################################################################################################################

signal Signal_StateChanged(prev_state: int, next_state: int)

## Current state
var state: int

# Reference to parent
var owner: Object

# Transitions from within enter/exit states is not allowed. Prevent this by tracking if in transition.
var currently_in_transition: bool = false

# List of state names corresponding to enum values. Index matches enum value.
var state_names: Array[String]

# Store if state is exitable. Defaults to true
var state_exitable: Array[bool]

# 
const INIT_STATE: int = -1


func _init(owner_: Object, enum_type_: Dictionary, initial_state: int) -> void:
    assert(owner_ != null, "StateMachine owner cannot be null.")
    assert(enum_type_ != null, "StateMachine enum type cannot be null.")
    assert(initial_state in enum_type_.values(), "Initial state must be a valid enum value.")

    owner = owner_
    state_names = Enum.to_string_array(enum_type_)
    assert(state_names.size() > 0, "Enum type must have at least one value.")

    # Init exitable array, default to true for all entries
    state_exitable.resize(state_names.size())
    state_exitable.fill(true)

    # Enter initial state
    state = INIT_STATE
    transition_to(initial_state)


func transition_to(next_state: int, ...enter_args: Array) -> void:
    if not _is_state_valid(next_state):
        push_error("Invalid state %d!" % next_state)
        return

    # We still need to re-enter the same state if we have enter arguments. Otherwise ignore
    if next_state == state and enter_args.is_empty():
        return

    if state != INIT_STATE and not state_exitable[state]:
        push_error("Cannot exit state %s as it is marked non-exitable." % _state_to_name(state))
        return

    # Prevent re-entrance
    if currently_in_transition:
        push_error("Cannot transition to state %s while exiting current state %s!" % [_state_to_name(next_state), _state_to_name(state)])
        assert(false)
        return
    currently_in_transition = true

    # Exit current state
    var prev_state := state
    if state != INIT_STATE:
        _call_state_func("_exit_", state, [])

    state = next_state

    # Reset transition flag
    currently_in_transition = false

    # Enter new state with arguments
    if enter_args.is_empty():
        _call_state_func("_enter_", state, [])
    else:
        _call_state_func("_enter_", state, enter_args)

    # Debug redraw
    var debug_draw_proxy: DebugDrawProxy = owner.get("_debug_draw_proxy_relative")
    if debug_draw_proxy != null:
        debug_draw_proxy.queue_redraw()
    debug_draw_proxy = owner.get("_debug_draw_proxy_absolute")
    if debug_draw_proxy != null:
        debug_draw_proxy.queue_redraw()

    Signal_StateChanged.emit(prev_state, next_state)


func set_state_exitable(state_value: int, exitable: bool) -> void:
    if not _is_state_valid(state_value):
        push_error("Invalid state %d!" % state_value)
        return

    state_exitable[state_value] = exitable


func process(delta: float) -> void:
    _call_state_func("_process_", state, [delta])


func physics_process(delta: float) -> void:
    _call_state_func("_physics_process_", state, [delta])


# --- Internal helpers ---
func _is_state_valid(state_value: int) -> bool:
    return state_value >= 0 and state_value < state_names.size()


func _call_state_func(prefix: String, state_value: int, var_args: Array) -> void:
    var state_name := _state_to_name(state_value)
    var func_name := prefix + state_name
    if owner.has_method(func_name):
        owner.callv(func_name, var_args)


# Converts typed enum value to lowercase name (e.g. State.IDLE → "idle")
func _state_to_name(state_value: int) -> String:
    if state_value == INIT_STATE:
        return "init_state"

    if not _is_state_valid(state_value):
        return "unknown"
    return String(state_names[state_value]).to_lower()
