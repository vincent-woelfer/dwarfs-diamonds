class_name MovementStats
extends RefCounted

# Capabilities
var can_use_ladders: bool = true
var can_use_ladders_when_falling: bool = false

# var can_climb_walls: bool = true

# Movement Speeds (pixels per second)
var speed_walking: float = 260.0
var speed_climbing_ladder_up: float = 140.0
var speed_climbing_ladder_down: float = 180.0
var speed_climbing_wall_up: float = 90.0
var speed_climbing_wall_down: float = 150.0


# Falling Speeds (pixels per second)
const falling_acceleration: float = 600.0 # pixels per second squared
const falling_starting_speed: float = 200.0
const falling_max_speed: float = 2000.0


func get_speed(move_mode: Enum.MoveMode) -> float:
    match move_mode:
        Enum.MoveMode.WALK:
            return speed_walking
        Enum.MoveMode.CLIMB_LADDER_UP:
            return speed_climbing_ladder_up
        Enum.MoveMode.CLIMB_LADDER_DOWN:
            return speed_climbing_ladder_down
        Enum.MoveMode.CLIMB_WALL_UP:
            return speed_climbing_wall_up
        Enum.MoveMode.CLIMB_WALL_DOWN:
            return speed_climbing_wall_down

    assert(false)
    return 10.0
