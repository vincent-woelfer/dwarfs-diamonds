# No class_name here, the name of the singleton is set in the autoload
extends Node

# Type of cell
enum CellType {
	A,
	B,
	C,
	BUILDING,
	SKY
}

# Type of job
enum JobType {
	MINE,
	BUILD,
	CARRY,
}

enum JobStatus {
	BLOCKED,
	READY,
	IN_PROCESS,
}


enum ProcessPriority {
    DEFAULT = 0,
    NAV = 1,
	JOBS = 2,
    CELL = 10,
    CELL_VISUAL = 11
}
