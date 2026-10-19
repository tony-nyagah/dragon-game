extends Node
## Which levels are unlocked and the best score on each, saved between sessions.
## Autoloaded as `Progress`. Level -1 is endless mode.

const PATH := "user://progress.cfg"

var unlocked := 1  # levels 1..unlocked can be played
var current := 0  # the level being played (index into Levels.LIST)
var _best := {}


func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		unlocked = file.get_value("progress", "unlocked", 1)
		for key in (file.get_section_keys("best") if file.has_section("best") else PackedStringArray()):
			_best[int(key)] = file.get_value("best", key)


func best(level: int) -> int:
	return _best.get(level, 0)


## Records a score; returns true if it's a new best.
func record(level: int, score: int) -> bool:
	if score <= best(level):
		return false
	_best[level] = score
	_save()
	return true


func complete(level: int) -> void:
	unlocked = clampi(level + 2, unlocked, Levels.LIST.size())
	_save()


func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("progress", "unlocked", unlocked)
	for level in _best:
		file.set_value("best", str(level), _best[level])
	file.save(PATH)
