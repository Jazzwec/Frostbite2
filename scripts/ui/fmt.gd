class_name Fmt
extends RefCounted
## Number and time formatting for the UI.

const SUFFIXES := ["", "K", "M", "B", "T"]


## 999, 1.2K, 3.4M, 5.6B. Values below 1000 are whole numbers.
static func num(value: float) -> String:
	var v := floorf(value)
	var i := 0
	while absf(v) >= 1000.0 and i < SUFFIXES.size() - 1:
		v /= 1000.0
		i += 1
	if i == 0:
		return str(int(v))
	return ("%.1f" % (floorf(v * 10.0) / 10.0)) + SUFFIXES[i]


## 4:05, 12:30.
static func clock(seconds: float) -> String:
	var s := maxi(int(ceilf(seconds)), 0)
	return "%d:%02d" % [s / 60, s % 60]


## "15 Wood + 5 Materials".
static func cost(c: Dictionary) -> String:
	var parts := []
	for k in c:
		parts.append("%s %s" % [num(c[k]), str(k).capitalize()])
	return " + ".join(parts)
