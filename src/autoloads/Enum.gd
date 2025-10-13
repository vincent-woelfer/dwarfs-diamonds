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
static func job_type_to_string(job_type: JobType) -> String:
	match job_type:
		JobType.MINE:
			return "MINE"
		JobType.BUILD:
			return "BUILD"
		JobType.CARRY:
			return "CARRY"
		_:
			return "UNKNOWN"

enum JobStatus {
	BLOCKED,
	READY,
	IN_PROCESS,
}

static func job_status_to_string(job_status: JobStatus) -> String:
	match job_status:
		JobStatus.BLOCKED:
			return "BLOCKED"
		JobStatus.READY:
			return "READY"
		JobStatus.IN_PROCESS:
			return "IN_PROCESS"
		_:
			return "UNKNOWN"

enum ProcessPriority {
    DEFAULT = 0,
    NAV = 1,
	JOBS = 2,
    CELL = 10,
    CELL_VISUAL = 11
}
