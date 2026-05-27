class_name JobDistributionHandler
extends RefCounted

## Uses Hungarian Algorithm to distribute jobs optimally according to scores
func distribute_jobs(dwarfs_looking_for_jobs: Array[Dwarf]) -> DwarfJobsAssignment:
	var job_set: Dictionary[Job, bool] = {}
	var dwarfs_with_scored_jobs: Dictionary[Dwarf, Array] = {} # Type = [Dwarf, Array[ScoredJob]]

	# Collect all scored jobs
	for dwarf: Dwarf in dwarfs_looking_for_jobs:
		var scored_jobs: Array[ScoredJob] = Global.level.job_manager.score_jobs_for_dwarf(dwarf)
		dwarfs_with_scored_jobs[dwarf] = scored_jobs
		for scored_job: ScoredJob in scored_jobs:
			job_set[scored_job.job] = true

	# Expand each job into capacity-many slots, capped at dwarf count to limit matrix size
	# This array contains references to the same job multiple times if it has capacity > 1
	var job_slots: Array[Job] = []
	for job: Job in job_set.keys():
		var slots: int = mini(job.calculate_capacity(), dwarfs_looking_for_jobs.size())
		for _i: int in slots:
			job_slots.append(job)

	# Build nxn cost matrix, Indexing is [dwarf_idx][slot_idx]
	var matrix_size: int = max(dwarfs_looking_for_jobs.size(), job_slots.size())
	const NO_JOB_PENALTY: float = 1e9

	# Type = Array[Array[float]], Indexing is [dwarf_idx][slot_idx]
	var cost_matrix: Array[Array] = []
	for i: int in matrix_size:
		cost_matrix.append([])
		for j: int in matrix_size:
			cost_matrix[i].append(NO_JOB_PENALTY)

	# Populate matrix - all slots belonging to the same job share the same score
	for dwarf_idx: int in dwarfs_looking_for_jobs.size():
		for scored_job: ScoredJob in dwarfs_with_scored_jobs[dwarfs_looking_for_jobs[dwarf_idx]]:
			for slot_idx: int in job_slots.size():
				if job_slots[slot_idx] == scored_job.job:
					cost_matrix[dwarf_idx][slot_idx] = scored_job.score

	# Get optimal assignment, index = dwarf_idx, value = slot_idx
	var dwarf_job_mapping: Array[int] = _hungarian_job_caluclation(cost_matrix, matrix_size)

	# Build return struct
	var dwarf_jobs_assignment: DwarfJobsAssignment = DwarfJobsAssignment.new()

	# slot_idx maps directly back to a Job reference via job_slots
	for dwarf_idx: int in dwarfs_with_scored_jobs.size():
		var slot_idx: int = dwarf_job_mapping[dwarf_idx]
		var job: Job = null
		if slot_idx < job_slots.size() and cost_matrix[dwarf_idx][slot_idx] < NO_JOB_PENALTY:
			job = job_slots[slot_idx]

		# Assign job to dwarf (including null for no job) - except the dwarf was not actually looking but got added as a dummy
		var dwarf: Dwarf = dwarfs_looking_for_jobs[dwarf_idx]
		if dwarf.sm.state == Dwarf.State.FALLING:
			continue

		# Assign null jobs aswell (means no job assigned, none available)
		dwarf_jobs_assignment.add_assignment(dwarf, job)

	return dwarf_jobs_assignment

# cost_matrix type is Array[Array[float]], Indexing is [dwarf_idx][job_idx]
# Returns assignment array. index = dwarf_idx, value = job_idx (or -1 if no job assigned)
func _hungarian_job_caluclation(cost_matrix: Array[Array], matrix_size: int) -> Array[int]:
	var u: Array = []; var v: Array = []
	var p: Array = []; var way: Array = []
	for i: int in matrix_size + 1:
		u.append(0.0); v.append(0.0); p.append(0); way.append(0)

	for i: int in range(1, matrix_size + 1):
		p[0] = i
		var j0: int = 0
		var minVal: Array[float] = []
		var used: Array[bool] = []
		for _k: int in matrix_size + 1:
			minVal.append(INF)
			used.append(false)

		while true:
			used[j0] = true
			var i0: int = p[j0]
			var delta: float = INF
			var j1: int = -1
			for j: int in range(1, matrix_size + 1):
				if not used[j]:
					var cur: float = cost_matrix[i0 - 1][j - 1] - u[i0] - v[j]
					if cur < minVal[j]:
						minVal[j] = cur
						way[j] = j0
					if minVal[j] < delta:
						delta = minVal[j]
						j1 = j
			for j: int in range(0, matrix_size + 1):
				if used[j]:
					u[p[j]] += delta; v[j] -= delta
				else:
					minVal[j] -= delta
			j0 = j1
			if p[j0] == 0:
				break
		while j0 != 0:
			p[j0] = p[way[j0]]
			j0 = way[j0]

	var assignment: Array[int] = []
	assignment.resize(matrix_size)
	for j: int in range(1, matrix_size + 1):
		if p[j] != 0:
			assignment[p[j] - 1] = j - 1

	return assignment
