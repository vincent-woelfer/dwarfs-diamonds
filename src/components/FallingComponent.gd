class_name FallingComponent
extends Node2D

# Signals
signal Signal_OnStartedFalling()
signal Signal_OnLanded(fall_height_cells: int)

# Constants - all in world space (pixels)
const falling_acceleration: float = 600.0 # pixels per second squared
const max_falling_speed: float = 2000.0 # pixels per second
const starting_speed: float = 200.0 # pixels per second

@onready var parent: Node2D = get_parent()

# Current state
var _ignore_ladders: bool = false
var _ignore_ladders_when_falling: bool = true

var _is_falling: bool = false
var _curr_falling_speed: float = 0.0

## For tracking fall distance in cells
var _fall_start_y: int


func _physics_process(delta: float) -> void:
    _update_on_ground_check()

    if _is_falling:
        _curr_falling_speed = min(_curr_falling_speed + falling_acceleration * delta, max_falling_speed)
        parent.global_position.y += _curr_falling_speed * delta


func is_falling() -> bool:
    return _is_falling


func _get_parent_cell() -> Cell:
    # Attempt to access grid_pos of parent
    var cell: Cell = null
    
    var grid_pos: Vector2i = parent.get("grid_pos")
    if grid_pos != null:
        cell = Global.level.get_cell(grid_pos)
    else:
        cell = Global.level.get_cell_at_world_pos(parent.global_position + Global.VERT_OFFSET_SMALL)
    return cell


## Returns true if state changed (started or stopped falling)
func _update_on_ground_check() -> void:
    var cell_curr := _get_parent_cell()
    var can_stand_in_current_cell := cell_curr.is_standable(_get_ignore_ladders())

    # TODO this is dirty. To avoid stating to fall when "climbing" a diagonal connection wall we just check
    # if we are horizontally centered in the cell.
    var horizontally_centered: bool = abs(parent.global_position.x - cell_curr.get_floor_point().x) <= Global.CELL_SIZE * 0.1

    # Currently standing on solid ground or ladder
    if not _is_falling:
        if can_stand_in_current_cell or not horizontally_centered: # TODO hacky
            # Nothing to do            
            return
        else:
            # Start falling
            _is_falling = true
            _curr_falling_speed = starting_speed
            # this is cell-center as we only track grid pos difference here
            _fall_start_y = cell_curr.grid_pos.y
            Signal_OnStartedFalling.emit()
            return

    # Currently falling -> require cell to land on but also position inside of current cell to be on floor
    else:
        var y_cell_floor := cell_curr.get_floor_point().y
        if can_stand_in_current_cell and global_position.y >= y_cell_floor:
            # Landed
            _is_falling = false
            parent.global_position.y = y_cell_floor
            var fall_height_cells: int = abs(_fall_start_y - cell_curr.grid_pos.y)
            Signal_OnLanded.emit(fall_height_cells)
            return
        else:
            # Still falling
            return


func _get_ignore_ladders() -> bool:
    return _ignore_ladders if !_is_falling else _ignore_ladders_when_falling
