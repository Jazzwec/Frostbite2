class_name JobRules
extends RefCounted
## Auto-assign. [brief] While it's on, every few seconds idle Jans go to the neediest job (the same
## rule as a newly thawed Jan), then at most one Jan moves from the job most over its share to the
## one that needs him most, so as few Jans as possible move. Guards are never touched.


## Puts `jan` on `job`, at the producer with the most room (guards and idle Jans have no plot).
## False, and he's left as he was, if every producer of that job is full.
static func assign(s: GameState, jan: Dictionary, job: String) -> bool:
	if job == "" or job == "guard":
		jan.job = job
		jan.site = -1
		CarryRules.reset(jan)
		return true
	var site := Economy.free_site(s, job)
	if site < 0:
		return false
	jan.job = job
	jan.site = site
	CarryRules.reset(jan)
	return true


## Puts `jan` at producer `i` if it has room.
static func assign_to_site(s: GameState, jan: Dictionary, i: int) -> bool:
	var job := Economy.site_job(s.sites[i].building)
	if job == "" or job == "guard" or s.sites[i].level < 1 or Economy.site_jans(s, i) >= Economy.site_slots(s, i):
		return false
	jan.job = job
	jan.site = i
	CarryRules.reset(jan)
	return true


## One rebalance. Returns how many Jans changed job.
static func rebalance(s: GameState) -> int:
	var moved := 0
	for jan in s.jans:
		if jan.job == "":
			var job := Economy.neediest_job(s)
			if job == "" or not assign(s, jan, job):
				break
			moved += 1
	var target := Economy.neediest_job(s)
	if target == "":
		return moved
	var donor := _most_over_share(s, target)
	if donor == "" or not _worth_moving(s, donor, target):
		return moved
	for i in range(s.jans.size() - 1, -1, -1):
		if s.jans[i].job == donor:
			return moved + (1 if assign(s, s.jans[i], target) else 0)
	return moved


## The job (other than `target`) with the most Jans for its share, keeping the last Lumber Yard
## worker where he is.
static func _most_over_share(s: GameState, target: String) -> String:
	var best := ""
	var most := -1.0
	for job in Balance.JOB_SHARES:
		if job == target:
			continue
		var count := Economy.job_count(s, job)
		if count == 0 or (job == "chop" and count == 1):
			continue
		var ratio: float = count / Balance.JOB_SHARES[job]
		if ratio > most:
			most = ratio
			best = job
	return best


## Urgent needs (nobody chopping, Food running short) always justify a move; otherwise only one
## that leaves the donor no worse off than the target, so Jans don't shuttle back and forth.
static func _worth_moving(s: GameState, donor: String, target: String) -> bool:
	if target == "chop" and Economy.job_count(s, "chop") == 0:
		return true
	if target == "hunt" and Economy.job_rate(s, "hunt") < Economy.food_eaten_per_second(s):
		return true
	var after_donor: float = (Economy.job_count(s, donor) - 1) / Balance.JOB_SHARES[donor]
	var after_target: float = (Economy.job_count(s, target) + 1) / Balance.JOB_SHARES[target]
	return after_donor >= after_target
