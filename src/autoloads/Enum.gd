# No class_name here, the name of the singleton is set in the autoload
extends Node2D

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
    CELL = 10,
    CELL_VISUAL = 11
}
