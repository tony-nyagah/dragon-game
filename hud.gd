extends Control
## Score, hearts, energy, breath picker, goals, combo, boss bar, banners and
## the pause / level complete / game over screens.

var score := 0
var lives := 3
var max_lives := 3
var combo := 0
var combo_left := 0.0  # 0..1, how much of the combo window remains
var flash := 0.0
var energy := 1.0  # 0..1
var energy_low := false
var breath_index := 0
var breaths_unlocked := 4
var boss_hp := -1.0  # 0..1, or negative when there's no boss
var boss_title := "GRIFFIN KNIGHT"

var level_title := ""
var goals: Array = []  # [{text, done}]

## Full-screen message (pause, level complete, game over). Empty title = hidden.
var overlay_title := ""
var overlay_color := Color.WHITE
var overlay_lines: Array = []

var _banner := ""
var _banner_sub := ""
var _banner_time := 0.0

var _shown_score := 0
var _score_pop := 0.0
var _time := 0.0
var _shown_lives := 3
var _heart_pop := 0.0


func _ready() -> void:
	size = Vector2(World.WIDTH, World.HEIGHT)
	mouse_filter = MOUSE_FILTER_IGNORE


func banner(message: String, subtitle := "") -> void:
	_banner = message
	_banner_sub = subtitle
	_banner_time = 3.0


func _process(delta: float) -> void:
	_time += delta
	if score != _shown_score:
		_shown_score = score
		_score_pop = 1.0
	_score_pop = maxf(_score_pop - delta * 4.0, 0.0)
	flash = maxf(flash - delta * 1.5, 0.0)
	if lives > _shown_lives:
		_heart_pop = 1.0
	_shown_lives = lives
	_heart_pop = maxf(_heart_pop - delta * 3.0, 0.0)
	_banner_time -= delta
	queue_redraw()


func _draw() -> void:
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.1, 0.1, flash * 0.35))

	_text(Vector2(24, 52), str(_shown_score), int(36 + _score_pop * 14), Color(1, 0.95, 0.7))
	for i in max_lives:
		_heart(Vector2(36 + i * 40, 90), i < lives, 1.0 + _heart_pop * 0.6 if i == lives - 1 else 1.0)
	_energy_meter(Vector2(20, 116))
	if breaths_unlocked > 1:
		_breath_picker(Vector2(20, 142))
	_goals_panel()

	if boss_hp >= 0.0:
		_text_centered(Vector2(size.x / 2, 34), boss_title, 22, Color(1, 0.9, 0.7))
		draw_rect(Rect2(size.x / 2 - 254, 42, 508, 22), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(size.x / 2 - 250, 46, 500 * boss_hp, 14), Color(0.85, 0.15, 0.15))
		draw_rect(Rect2(size.x / 2 - 250, 46, 500 * boss_hp, 4), Color(1, 0.5, 0.45))

	if combo > 1:
		var pulse := 1.0 + sin(_time * 12.0) * 0.08
		var y := 120.0 if boss_hp >= 0.0 else 70.0
		_text_centered(Vector2(size.x / 2, y), "COMBO x%d" % combo, int(40 * pulse), Color(1, 0.6, 0.15))
		draw_rect(Rect2(size.x / 2 - 80, y + 14, 160 * combo_left, 6), Color(1, 0.6, 0.15))

	if _banner_time > 0.0:
		var pop := 1.0 + maxf(_banner_time - 2.7, 0.0) * 2.0
		var alpha := clampf(_banner_time * 2.0, 0.0, 1.0)
		_text_centered(Vector2(size.x / 2, 250), _banner, int(52 * pop), Color(1, 0.8, 0.3, alpha))
		if _banner_sub != "":
			_text_centered(Vector2(size.x / 2, 295), _banner_sub, 24, Color(1, 1, 1, alpha))

	var controls := "WASD: fly    Mouse: aim    Click / Space: breathe    Swoop onto sheep or guards: eat    Esc: pause"
	if breaths_unlocked > 1:
		controls = "WASD: fly    Mouse: aim    Click / Space: breathe    1-%d / Q / E / wheel: switch breath    Swoop onto sheep or guards: eat    Esc: pause" % breaths_unlocked
	_text(Vector2(16, size.y - 14), controls, 16, Color(1, 1, 1, 0.8))

	if overlay_title != "":
		_draw_overlay()


func _draw_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	_text_centered(size / 2 - Vector2(0, 60), overlay_title, 68, overlay_color)
	for i in overlay_lines.size():
		var last := i == overlay_lines.size() - 1
		# The last line holds the key hints, so it gently pulses.
		var color := Color(1, 1, 1, 0.6 + 0.4 * sin(_time * 4.0)) if last else Color.WHITE
		_text_centered(size / 2 + Vector2(0, 5 + i * 40 + (20 if last else 0)), overlay_lines[i], 24 if last else 30, color)


## Level name and a checklist of goals in the top-right corner.
func _goals_panel() -> void:
	if level_title == "":
		return
	var right := size.x - 20
	_text_right(Vector2(right, 34), level_title, 20, Color(1, 0.85, 0.5))
	for i in goals.size():
		var goal: Dictionary = goals[i]
		var y := 64.0 + i * 28.0
		var color := Color(0.55, 1.0, 0.5) if goal.done else Color.WHITE
		var width := _text_right(Vector2(right, y), goal.text, 18, color)
		var box := Rect2(right - width - 26, y - 15, 16, 16)
		draw_rect(box, Color(0, 0, 0, 0.6))
		draw_rect(box, color, false, 2.0)
		if goal.done:
			draw_polyline(PackedVector2Array([box.position + Vector2(3, 8), box.position + Vector2(7, 12), box.position + Vector2(13, 3)]), color, 2.5)


func _energy_meter(pos: Vector2) -> void:
	var breath: Dictionary = Breaths.LIST[breath_index]
	var low := energy_low and int(_time * 8.0) % 2 == 0
	draw_rect(Rect2(pos, Vector2(124, 16)), Color(0, 0, 0, 0.7))
	var fill: Color = Color(0.9, 0.15, 0.1) if low else breath.color.lerp(Color.WHITE, 0.25 * energy)
	draw_rect(Rect2(pos + Vector2(2, 2), Vector2(120 * energy, 12)), fill)
	draw_rect(Rect2(pos + Vector2(2, 2), Vector2(120 * energy, 4)), Color(1, 1, 1, 0.3))
	_text(pos + Vector2(132, 14), breath.name, 16, breath.color)


## One small box per unlocked breath with its number key; the active one is lit up.
func _breath_picker(pos: Vector2) -> void:
	for i in breaths_unlocked:
		var breath: Dictionary = Breaths.LIST[i]
		var box := Rect2(pos + Vector2(i * 34, 0), Vector2(30, 30))
		var active := i == breath_index
		draw_rect(box, Color(0, 0, 0, 0.7 if active else 0.45))
		draw_circle(box.get_center() + Vector2(0, -2), 9.0 if active else 6.0, Color(breath.color, 1.0 if active else 0.5))
		if active:
			draw_rect(box, Color.WHITE, false, 2.0)
		_text(box.position + Vector2(2, 28), str(i + 1), 12, Color(1, 1, 1, 0.9 if active else 0.5))


func _text(pos: Vector2, value: String, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(0, 0, 0, 0.8 * color.a))
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _text_centered(pos: Vector2, value: String, font_size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(pos - Vector2(width / 2.0, 0), value, font_size, color)


## Draws text ending at `pos.x`; returns its width.
func _text_right(pos: Vector2, value: String, font_size: int, color: Color) -> float:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(pos - Vector2(width, 0), value, font_size, color)
	return width


func _heart(center: Vector2, full: bool, s := 1.0) -> void:
	_heart_shape(center, 1.25 * s, Color(0, 0, 0, 0.7))
	_heart_shape(center, s, Color(0.95, 0.2, 0.3) if full else Color(0.25, 0.2, 0.22))
	if full:
		draw_circle(center + Vector2(-8, -7) * s, 3.0 * s, Color(1, 1, 1, 0.7))


func _heart_shape(c: Vector2, s: float, color: Color) -> void:
	draw_circle(c + Vector2(-7, -4) * s, 9.0 * s, color)
	draw_circle(c + Vector2(7, -4) * s, 9.0 * s, color)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-15.5, -1) * s, c + Vector2(15.5, -1) * s, c + Vector2(0, 16) * s
	]), color)
