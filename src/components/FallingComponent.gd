class_name FallingComponent
extends Node2D

# Signals
signal Signal_OnStartedFalling()
signal Signal_OnLanded()

# Constants
const falling_acceleration: float = 500.0 # pixels per second squared
const max_falling_speed: float = 1000.0 # pixels per second
const landing_threshold_y: float = 1.0 # pixels

@onready var parent: Node2D = get_parent()

# Current state
var _ignore_ladders: bool = false

var _is_falling: bool = false
var _curr_falling_speed: float = 0.0


func _physics_process(delta: float) -> void:
    _update_on_ground_check()

    if _is_falling:
        _curr_falling_speed = min(_curr_falling_speed + falling_acceleration * delta, max_falling_speed)
        parent.global_position.y += _curr_falling_speed * delta


func is_falling() -> bool:
    return _is_falling


## Returns true if state changed (started or stopped falling)
func _update_on_ground_check() -> void:
    var cell_curr := Global.level.get_cell_at_world_pos(global_position)
    var can_stand_in_current_cell := cell_curr.is_standable(_ignore_ladders)

    # Currently standing on solid ground or ladder
    if not _is_falling:
        if can_stand_in_current_cell:
            # Nothing to do            
            return
        else:
            # Start falling
            _is_falling = true
            _curr_falling_speed = 0.0
            Signal_OnStartedFalling.emit()
            return

    # Currently falling -> require cell to land on but also position inside of current cell to be around cell center
    else:
        var y_cell_center := Util.grid_space_to_world_space_cell_center(cell_curr.grid_pos).y
        if can_stand_in_current_cell and global_position.y >= (y_cell_center - landing_threshold_y):
            # Landed
            _is_falling = false
            _curr_falling_speed = 0.0
            parent.global_position.y = y_cell_center
            Signal_OnLanded.emit()
            return
        else:
            # Still falling
            return
