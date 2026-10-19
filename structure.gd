extends Node2D
## A village house or a watchtower. Takes several hits, catches fire where it's hit,
## and collapses into smoking rubble. Towers have an archer on top.
## `position` is the bottom-center, on the ground.

signal shoot_arrow(pos: Vector2, vel: Vector2, big: bool)

const LINE := Color(0.12, 0.08, 0.06)

var kind := "house"
var dragon: Node2D
var max_hp := 5
var hp := 5
var points := 10
var width := 120.0
var height := 135.0

var grow := 0.0  # rises out of the ground from 0 to 1
var flash := 0.0
var reload := 3.0
var ruin_time := -1.0  # counts down once destroyed
var time := 0.0
var _burning: Array[Vector2] = []  # local spots that are on fire
var _chimney_timer := 0.0
var frozen := 0.0


func setup(structure_kind: String) -> void:
	kind = structure_kind
	if kind == "tower":
		max_hp = 9
		points = 25
		width = 80.0
		height = 215.0
	hp = max_hp


func contains(p: Vector2) -> bool:
	return ruin_time < 0.0 and Rect2(position.x - width / 2 - 8, position.y - height * grow, width + 16, height * grow).has_point(p)


func center() -> Vector2:
	return position + Vector2(0, -height * grow / 2)


func take_hit(at: Vector2, damage := 1, breath := "fire") -> bool:
	hp -= damage
	flash = 1.0
	if breath == "fire":
		var spot := at - position
		_burning.append(Vector2(clampf(spot.x, -width / 2 + 10, width / 2 - 10), clampf(spot.y, -height + 25, -10)))
		Sfx.play("explode", -14, 1.4)
	elif breath == "poison":
		Sfx.play("splat", -18, 1.3)
	return hp <= 0


## Ice puts out fires and stops the tower archer from shooting for a while.
func freeze(seconds: float) -> void:
	frozen = maxf(frozen, seconds * 2.0)
	_burning.clear()


func destroy(breath := "fire") -> void:
	remove_from_group("targets")
	ruin_time = 6.0
	for i in 6:
		Effects.explode(position + Vector2(randf_range(-width / 2, width / 2), -randf() * height), 1.0, breath)
	Effects.shake(16.0)
	Sfx.play("collapse")
	if breath == "fire":
		# Keep a few embers smoldering in the rubble.
		_burning = [Vector2(-width * 0.25, -12), Vector2(width * 0.2, -16)]


func _ready() -> void:
	z_index = -1
	Effects.smoke(position + Vector2(-width / 2, -5), Vector2(-40, -10), 1.0, 18.0, Color(0.6, 0.5, 0.4))
	Effects.smoke(position + Vector2(width / 2, -5), Vector2(40, -10), 1.0, 18.0, Color(0.6, 0.5, 0.4))
	Sfx.play("rise", -8)


func _process(delta: float) -> void:
	time += delta
	grow = minf(grow + delta * 1.2, 1.0)
	flash = maxf(flash - delta * 6.0, 0.0)
	frozen -= delta

	for spot in _burning:
		if randf() < delta * 25.0:
			var p := position + spot + Vector2(randf_range(-10, 10), 0)
			Effects.fire(p, Vector2(randf_range(-15, 15), -90), randf_range(0.3, 0.6), randf_range(5, 10))
		if randf() < delta * 3.0:
			Effects.smoke(position + spot, Vector2(randf_range(-10, 10), -50), 1.5, 12.0, Color(0.2, 0.18, 0.18))

	if ruin_time >= 0.0:
		ruin_time -= delta
		modulate.a = clampf(ruin_time, 0.0, 1.0)
		if ruin_time <= 0.0:
			queue_free()
	elif kind == "house" and hp == max_hp:
		_chimney_timer -= delta
		if _chimney_timer <= 0.0:
			_chimney_timer = 0.35
			Effects.smoke(position + Vector2(36, -height + 8), Vector2(12, -30), 1.6, 7.0, Color(0.85, 0.85, 0.88))
	elif kind == "tower" and grow >= 1.0 and frozen <= 0.0 and is_instance_valid(dragon):
		reload -= delta
		if reload <= 0.0:
			reload = randf_range(2.2, 3.4)
			var from := position + Vector2(0, -height + 10)
			var aim := (dragon.position - from).normalized().rotated(randf_range(-0.08, 0.08))
			shoot_arrow.emit(from, aim * 450.0, false)
			Sfx.play("twang", -8, 1.2)
	queue_redraw()


## Darkens a color as the building gets burned, and flashes it when hit.
func _c(color: Color) -> Color:
	var burnt := (1.0 - float(hp) / max_hp) * 0.55
	if frozen > 0.0:
		color = color.lerp(Color(0.65, 0.88, 1.0), 0.5)
	return color.darkened(burnt).lerp(Color.WHITE, flash * 0.6)


func _shape(points: PackedVector2Array, fill: Color) -> void:
	Paint.shape(self, points, _c(fill), LINE)


func _rect(r: Rect2, fill: Color) -> void:
	_shape(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), fill)


func _draw() -> void:
	if ruin_time >= 0.0:
		_draw_rubble()
		return
	# Rise out of the ground by squashing vertically.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, grow))
	if kind == "tower":
		_draw_tower()
	else:
		_draw_house()
	draw_set_transform(Vector2.ZERO)


func _draw_house() -> void:
	var beam := Color(0.35, 0.22, 0.12)
	_rect(Rect2(28, -128, 16, 40), Color(0.6, 0.4, 0.3))  # chimney
	_rect(Rect2(-58, -80, 116, 80), Color(0.94, 0.86, 0.7))  # walls
	for x in [-58.0, -20.0, 20.0, 54.0]:
		draw_line(Vector2(x + 2, -80), Vector2(x + 2, 0), _c(beam), 4.0)
	draw_line(Vector2(-58, -42), Vector2(58, -42), _c(beam), 4.0)
	# Door and glowing windows
	_shape(PackedVector2Array([Vector2(-12, 0), Vector2(-12, -30), Vector2(0, -40), Vector2(12, -30), Vector2(12, 0)]), Color(0.45, 0.28, 0.14))
	for x in [-44.0, 28.0]:
		_rect(Rect2(x, -70, 18, 18), Color(1.0, 0.85, 0.45))
		draw_line(Vector2(x + 9, -70), Vector2(x + 9, -52), _c(beam), 2.0)
	# Thatched roof
	_shape(PackedVector2Array([Vector2(-72, -76), Vector2(72, -76), Vector2(0, -135)]), Color(0.82, 0.62, 0.3))
	for i in 5:
		var y := -84.0 - i * 10.0
		var half := 62.0 * (1.0 - (i + 1) * 0.16)
		draw_line(Vector2(-half, y), Vector2(half, y), _c(Color(0.65, 0.47, 0.2)), 2.0)


func _draw_tower() -> void:
	var stone := Color(0.64, 0.62, 0.6)
	_rect(Rect2(-32, -170, 64, 170), stone)
	for row in 10:
		var y := -17.0 * (row + 1)
		draw_line(Vector2(-32, y), Vector2(32, y), _c(stone.darkened(0.25)), 1.5)
		for col in 3:
			var x := -32.0 + col * 24.0 + (12.0 if row % 2 else 0.0)
			if x > -32.0 and x < 32.0:
				draw_line(Vector2(x, y), Vector2(x, y + 17), _c(stone.darkened(0.25)), 1.5)
	_shape(PackedVector2Array([Vector2(-12, 0), Vector2(-12, -26), Vector2(0, -36), Vector2(12, -26), Vector2(12, 0)]), Color(0.4, 0.25, 0.12))
	_rect(Rect2(-4, -120, 8, 22), Color(0.15, 0.12, 0.1))  # arrow slit

	# Lookout platform with an archer peeking over the battlements
	_rect(Rect2(-42, -184, 84, 16), stone.lightened(0.05))
	if hp > 0:
		draw_circle(Vector2(0, -196), 9.0, LINE)
		draw_circle(Vector2(0, -196), 7.5, _c(Color(0.95, 0.78, 0.6)))
		draw_arc(Vector2(0, -197), 8.5, PI, TAU, 10, _c(Color(0.65, 0.67, 0.72)), 5.0)
	for i in 4:
		_rect(Rect2(-42 + i * 24, -200, 12, 16), stone.lightened(0.05))

	# Waving flag
	draw_line(Vector2(30, -200), Vector2(30, -240), _c(LINE), 3.0)
	var flag := PackedVector2Array()
	for i in 6:
		flag.append(Vector2(30 + i * 6, -238 + sin(time * 6.0 - i * 0.8) * 2.5))
	for i in range(5, -1, -1):
		flag.append(Vector2(30 + i * 6, -224 + sin(time * 6.0 - i * 0.8) * 2.5))
	_shape(flag, Color(0.85, 0.15, 0.15))


func _draw_rubble() -> void:
	var dark := Color(0.25, 0.22, 0.2)
	_shape(PackedVector2Array([
		Vector2(-width / 2 - 10, 0), Vector2(-width * 0.3, -20), Vector2(-width * 0.05, -30),
		Vector2(width * 0.2, -22), Vector2(width / 2 + 10, 0)
	]), dark)
	draw_line(Vector2(-width * 0.35, -6), Vector2(width * 0.1, -40), LINE, 6.0)
	draw_line(Vector2(width * 0.05, -4), Vector2(width * 0.4, -28), LINE, 5.0)
