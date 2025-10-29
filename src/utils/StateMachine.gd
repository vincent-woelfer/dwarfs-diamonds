class_name StateMachine
extends RefCounted

signal Signal_StateChanged(prev_state: int, next_state: int)

var state: int = -1
var owner: Object
var enum_type_name: String

var state_names: Array[String]

func _init(owner_: Object, enum_type_: Dictionary) -> void:
    owner = owner_
    state_names = Enum.to_string_array(enum_type_)
    assert(state_names.size() > 0, "Enum type must have at least one value.")


func transition_to(next_state: int) -> void:
    if next_state == state:
        return

    var prev_state := state
    if state != -1:
        _call_state_func("_exit_", state)

    state = next_state
    _call_state_func("_enter_", state)

    Signal_StateChanged.emit(prev_state, next_state)

    # Debug redraw
    var debug_draw_proxy: DebugDrawProxy = owner.get("_debug_draw_proxy")
    if debug_draw_proxy != null:
        debug_draw_proxy.queue_redraw()


func process(delta: float) -> void:
    if state != -1:
        _call_state_func("_process_", state, delta)


func physics_process(delta: float) -> void:
    if state != -1:
        _call_state_func("_physics_process_", state, delta)


# --- Internal helpers ---
func _call_state_func(prefix: String, state_value: int, arg: Variant = null) -> void:
    var state_name := _state_to_name(state_value)
    var func_name := prefix + state_name
    if owner.has_method(func_name):
        if arg == null:
            owner.call(func_name)
        else:
            owner.call(func_name, arg)


# Converts typed enum value to lowercase name (e.g. State.IDLE → "idle")
func _state_to_name(state_value: int) -> String:
    if state_value < 0 or state_value >= state_names.size():
        return "unknown"
    return String(state_names[state_value]).to_lower()
