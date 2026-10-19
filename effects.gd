extends Node2D
## Global visual effects, autoloaded as `Effects`:
## glowing breath particles, smoke, lightning bolts, floating text and screen shake.

## Particle colors for each breath: fresh -> middle -> old, plus how fast they rise
## (negative falls) and what color their smoke is.
const PALETTES := {
	fire = {fresh = Color(1.0, 0.9, 0.3), mid = Color(1.0, 0.5, 0.05), old = Color(0.75, 0.1, 0.02), lift = 90.0, smoke = Color(0.3, 0.27, 0.27)},
	ice = {fresh = Color(1, 1, 1), mid = Color(0.55, 0.85, 1.0), old = Color(0.2, 0.45, 0.9), lift = -160.0, smoke = Color(0.85, 0.93, 1.0)},
	lightning = {fresh = Color(1, 1, 1), mid = Color(1.0, 0.95, 0.45), old = Color(0.6, 0.4, 1.0), lift = 0.0, smoke = Color(0.45, 0.4, 0.6)},
	poison = {fresh = Color(0.85, 1.0, 0.5), mid = Color(0.45, 0.9, 0.2), old = Color(0.15, 0.45, 0.1), lift = 40.0, smoke = Color(0.35, 0.5, 0.25)},
}

var _bolts: Array[Dictionary] = []
var _fire: Array[Dictionary] = []
var _smoke: Array[Dictionary] = []
var _texts: Array[Dictionary] = []
var _shake := 0.0

var _camera: Camera2D
var _glow: Node2D
var _text_layer: Node2D


func _ready() -> void:
	z_index = 10

	_camera = Camera2D.new()
	_camera.position = Vector2(World.WIDTH, World.HEIGHT) / 2.0
	add_child(_camera)

	# Fire gets its own layer so it always draws on top of smoke.
	_glow = Node2D.new()
	_glow.draw.connect(_draw_fire)
	add_child(_glow)

	_text_layer = Node2D.new()
	_text_layer.draw.connect(_draw_texts)
	add_child(_text_layer)


func fire(pos: Vector2, vel: Vector2, life: float, size: float, palette := "fire") -> void:
	_fire.append({pos = pos, vel = vel, life = life, max_life = life, size = size, palette = PALETTES[palette], lift = PALETTES[palette].lift})


func smoke(pos: Vector2, vel: Vector2, life: float, size: float, color := Color(0.3, 0.27, 0.27)) -> void:
	_smoke.append({pos = pos, vel = vel, life = life, max_life = life, size = size, color = color})


func explode(pos: Vector2, power := 1.0, palette := "fire") -> void:
	for i in int(26 * power):
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(60.0, 300.0) * power
		fire(pos, vel, randf_range(0.3, 0.7), randf_range(5.0, 11.0) * power, palette)
	for i in int(8 * power):
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(20.0, 90.0)
		smoke(pos, vel, randf_range(0.6, 1.2), randf_range(10.0, 18.0) * power, PALETTES[palette].smoke)


## A jagged lightning bolt between two points.
func bolt(from: Vector2, to: Vector2) -> void:
	var points := PackedVector2Array([from])
	var steps := maxi(int(from.distance_to(to) / 28.0), 2)
	var side := (to - from).normalized().orthogonal()
	for i in range(1, steps):
		points.append(from.lerp(to, float(i) / steps) + side * randf_range(-16, 16))
	points.append(to)
	_bolts.append({points = points, life = 0.2, max_life = 0.2})
	for i in 8:
		fire(to, Vector2.from_angle(randf() * TAU) * randf_range(60, 220), randf_range(0.15, 0.35), randf_range(3, 6), "lightning")


func text(pos: Vector2, value: String, color: Color, size := 30) -> void:
	_texts.append({pos = pos, text = value, color = color, size = size, life = 1.0, max_life = 1.0})


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func clear() -> void:
	_fire.clear()
	_smoke.clear()
	_bolts.clear()
	_texts.clear()
	_shake = 0.0


func _process(delta: float) -> void:
	_step(_fire, delta, 3.0, 90.0)
	_step(_smoke, delta, 2.0, 35.0)
	_step(_texts, delta, 0.0, 0.0)
	_step(_bolts, delta, 0.0, 0.0)
	for t in _texts:
		t.pos.y -= 50.0 * delta

	_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	_shake = lerpf(_shake, 0.0, 1.0 - exp(-10.0 * delta))

	queue_redraw()
	_glow.queue_redraw()
	_text_layer.queue_redraw()


## Moves particles (they slow down and drift upward) and removes dead ones.
func _step(list: Array[Dictionary], delta: float, drag: float, lift: float) -> void:
	var i := list.size() - 1
	while i >= 0:
		var p := list[i]
		p.life -= delta
		if p.life <= 0.0:
			list[i] = list.back()
			list.pop_back()
		elif p.has("vel"):
			p.vel = p.vel * exp(-drag * delta) + Vector2(0, -p.get("lift", lift) * delta)
			p.pos += p.vel * delta
		i -= 1


func _draw() -> void:
	for p in _smoke:
		var t: float = p.life / p.max_life
		draw_circle(p.pos, p.size * (1.8 - t * 0.8), Color(p.color, t * 0.5))


func _draw_fire() -> void:
	for p in _fire:
		var t: float = p.life / p.max_life
		# Fresh particles are bright, then cool through the middle color to the old one.
		var palette: Dictionary = p.palette
		var c: Color = palette.old.lerp(palette.mid, minf(t * 2.0, 1.0))
		c = c.lerp(palette.fresh, maxf(t * 2.0 - 1.0, 0.0))
		var r: float = p.size * (0.4 + 0.6 * t)
		_glow.draw_circle(p.pos, r * 1.8, Color(palette.mid, 0.15 * t))
		_glow.draw_circle(p.pos, r, Color(c, minf(t * 1.5, 1.0)))
	for b in _bolts:
		var alpha: float = b.life / b.max_life
		_glow.draw_polyline(b.points, Color(0.6, 0.45, 1.0, 0.45 * alpha), 12.0, true)
		_glow.draw_polyline(b.points, Color(1.0, 0.95, 0.5, alpha), 5.0, true)
		_glow.draw_polyline(b.points, Color(1, 1, 1, alpha), 2.0, true)


func _draw_texts() -> void:
	var font := ThemeDB.fallback_font
	for t in _texts:
		var alpha := clampf(t.life / t.max_life * 2.0, 0.0, 1.0)
		var width := font.get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, t.size).x
		var pos: Vector2 = t.pos - Vector2(width / 2.0, 0)
		_text_layer.draw_string_outline(font, pos, t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, t.size, 8, Color(0, 0, 0, alpha * 0.8))
		_text_layer.draw_string(font, pos, t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, t.size, Color(t.color, alpha))
