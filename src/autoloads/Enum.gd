# No class_name here, the name of the singleton is set in the autoload
extends Node

func to_str(enum_dict: Dictionary, value: int) -> String:
    for n: String in enum_dict:
        if enum_dict[n] == value:
            return n
    return "Unknown"

# Type of cell
enum CellType {
	A,
	B,
	C,
	BUILDING,
	SKY
}

enum ProcessPriority {
    DEFAULT = 0,
    NAV = 1,
	JOBS = 2,
    CELL = 10,
    CELL_VISUAL = 11
}
