class_name MovementStats
extends RefCounted

# Capabilities
var can_use_ladders: bool = true
var can_use_ladders_falling: bool = false

# Movement Speeds (pixels per second)
# See Enum.MoveMode for which speed applies to which move mode
var speed_walking: float = 260.0
var speed_climbing_ladder_up: float = 140.0
var speed_climbing_ladder_down: float = 180.0
var speed_climbing_wall_up: float = 90.0
var speed_climbing_wall_down: float = 150.0


# Falling Speeds (pixels per second)
const falling_acceleration: float = 600.0 # pixels per second squared
const falling_starting_speed: float = 220.0
const falling_max_speed: float = 2000.0


func get_movement_mode_speed(move_mode: Enum.MoveMode) -> float:
    var speed: float
    match move_mode:
        Enum.MoveMode.WALK, Enum.MoveMode.WALK_NO_FALLING_SPECIAL:
            speed = speed_walking
        Enum.MoveMode.CLIMB_LADDER_UP:
            speed = speed_climbing_ladder_up
        Enum.MoveMode.CLIMB_LADDER_DOWN:
            speed = speed_climbing_ladder_down
        Enum.MoveMode.CLIMB_WALL_UP:
            speed = speed_climbing_wall_up
        Enum.MoveMode.CLIMB_WALL_DOWN:
            speed = speed_climbing_wall_down
        _:
            # Default to walking speed for unhandled move modes, but log an error
            speed = speed_walking
            assert(false, "Unhandled move mode: %s" % str(move_mode))

    return speed
