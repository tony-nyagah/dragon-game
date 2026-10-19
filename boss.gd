extends Node2D
## The Griffin Knight. Swoops around throwing spears, then lines up level
## with the dragon and charges across the screen with its lance.

signal shoot_arrow(pos: Vector2, vel: Vector2, big: bool)

const LINE := Color(0.12, 0.08, 0.06)
const FUR := Color(0.82, 0.63, 0.36)
const FEATHER := Color(0.58, 0.38, 0.2)
const FEATHER_BACK := Color(0.42, 0.27, 0.15)
const WHITE_FEATHER := Color(0.97, 0.95, 0.9)
const GOLD := Color(0.98, 0.78, 0.25)
const ARMOR := Color(0.74, 0.77, 0.82)

var dragon: Node2D
var level := 0
var max_hp := 25
var hp := 25
var points := 100
var dying := false
var title := "GRIFFIN KNIGHT"
var armor := ARMOR

var state := "enter"  # enter -> roam -> aim -> charge -> roam ...
var state_time := 0.0
var facing := -1.0
var time := 0.0
var flap := 0.0
var flash := 0.0
var throw_cooldown := 2.0
var lance_down := 0.0  # 0 = raised, 1 = lowered for a charge
var fall_speed := 0.0
var frozen := 0.0


func setup(boss_level: int, boss_title := "GRIFFIN KNIGHT") -> void:
	level = boss_level
	title = boss_title
	if title == "GRIFFIN KING":
		armor = GOLD
	max_hp = 25 + 15 * level
	hp = max_hp
	points = 100 + 50 * level


func _ready() -> void:
	position = Vector2(World.WIDTH + 200, 160)
	Sfx.play("roar")


func contains(p: Vector2) -> bool:
	return ((p - position - Vector2(0, -20)) / Vector2(90, 60)).length() < 1.0


func center() -> Vector2:
	return position + Vector2(0, -20)


func take_hit(at: Vector2, damage := 1, breath := "fire") -> bool:
	hp -= damage
	flash = 1.0
	Effects.explode(at, 0.35, breath)
	Sfx.play("clank", -8)
	return hp <= 0


func freeze(seconds: float) -> void:
	if frozen <= 0.0:
		Sfx.play("freeze", -4, 0.6)
	frozen = maxf(frozen, seconds)


func destroy(_breath := "fire") -> void:
	dying = true
	remove_from_group("targets")
	fall_speed = -200.0


func _process(delta: float) -> void:
	time += delta
	state_time += delta
	flash = maxf(flash - delta * 6.0, 0.0)
	if frozen > 0.0 and not dying:
		# Frozen solid: hangs in the air, can't move or attack.
		frozen -= delta
		queue_redraw()
		return
	flap += delta * (11.0 if state == "charge" else 6.0)
	lance_down = lerpf(lance_down, 1.0 if state in ["aim", "charge"] else 0.0, 1.0 - exp(-8.0 * delta))
	queue_redraw()

	if dying:
		_fall(delta)
		return
	if not is_instance_valid(dragon) and state != "charge":
		_glide_to(Vector2(640, 150), delta, 1.0)
		return

	match state:
		"enter":
			_glide_to(Vector2(950, 220), delta, 2.0)
			_face_dragon()
			if state_time > 2.0:
				_set_state("roam")
		"roam":
			_glide_to(Vector2(640 + 400 * sin(time * 0.5), 220 + 70 * sin(time * 1.3)), delta, 1.5)
			_face_dragon()
			throw_cooldown -= delta
			if throw_cooldown <= 0.0:
				throw_cooldown = maxf(2.2 - level * 0.3, 1.0)
				_throw_spears()
			if state_time > 6.0:
				_set_state("aim")
		"aim":
			# Move to the far side, level with the dragon, and lower the lance.
			var side := 130.0 if dragon.position.x > World.WIDTH / 2 else World.WIDTH - 130.0
			_glide_to(Vector2(side, clampf(dragon.position.y, 130, 560)), delta, 4.0)
			_face_dragon()
			if state_time > 1.3:
				Sfx.play("dash")
				_set_state("charge")
		"charge":
			position.x += facing * (950.0 + level * 120.0) * delta
			if randf() < delta * 40.0:
				Effects.smoke(position + Vector2(-facing * 60, randf_range(-30, 20)), Vector2(-facing * 100, 0), 0.5, 10.0, Color(1, 1, 1, 0.8))
			if position.x < -200.0 or position.x > World.WIDTH + 200.0:
				position.y = randf_range(150, 280)
				_set_state("roam")


func _set_state(next: String) -> void:
	state = next
	state_time = 0.0


func _glide_to(target: Vector2, delta: float, rate: float) -> void:
	position = position.lerp(target, 1.0 - exp(-rate * delta))


func _face_dragon() -> void:
	if is_instance_valid(dragon) and absf(dragon.position.x - position.x) > 10.0:
		facing = signf(dragon.position.x - position.x)


func _throw_spears() -> void:
	var from := position + Vector2(facing * 20, -60)
	var aim := (dragon.position - from).normalized()
	for spread in [-0.2, 0.0, 0.2]:
		shoot_arrow.emit(from, aim.rotated(spread) * 480.0, true)
	Sfx.play("twang", -4, 0.7)


func _fall(delta: float) -> void:
	fall_speed += 900.0 * delta
	position.y += fall_speed * delta
	rotation += delta * 3.0 * facing
	if randf() < delta * 30.0:
		Effects.fire(position + Vector2(randf_range(-40, 40), randf_range(-30, 30)), Vector2(0, -60), 0.5, 10.0)
		Effects.smoke(position, Vector2(0, -40), 1.0, 16.0)
	if position.y >= World.GROUND_Y - 30.0:
		Effects.explode(position, 3.0)
		Effects.shake(30.0)
		Sfx.play("boom_big")
		queue_free()


# --- Drawing (facing right, mirrored by `facing`) --------------------------

func _c(color: Color) -> Color:
	if frozen > 0.0:
		color = color.lerp(Color(0.65, 0.88, 1.0), 0.55)
	return color.lerp(Color.WHITE, flash * 0.7)


func _shape(points: PackedVector2Array, fill: Color) -> void:
	Paint.shape(self, points, _c(fill), LINE)


func _draw() -> void:
	draw_set_transform_matrix(Transform2D(Vector2(facing, 0), Vector2(0, 1), Vector2.ZERO))
	var beat := sin(flap) * 0.6

	_wing(Vector2(6, -16), beat + 0.15, FEATHER_BACK)
	_tail()

	# Lion hind legs and eagle front talons
	_shape(PackedVector2Array([Vector2(-50, 6), Vector2(-32, 6), Vector2(-30, 34), Vector2(-46, 34)]), FUR.darkened(0.2))
	_shape(PackedVector2Array([Vector2(-32, 10), Vector2(-14, 10), Vector2(-14, 34), Vector2(-28, 34)]), FUR)
	_shape(PackedVector2Array([Vector2(24, 10), Vector2(38, 10), Vector2(46, 32), Vector2(28, 32)]), GOLD)

	_shape(Paint.ellipse(Vector2.ZERO, Vector2(58, 28)), FUR)
	_shape(Paint.ellipse(Vector2(34, -6), Vector2(26, 22)), WHITE_FEATHER)

	_knight()

	# Eagle head with a hooked beak and an angry eye
	_shape(PackedVector2Array([Vector2(44, -40), Vector2(26, -54), Vector2(40, -46), Vector2(30, -60), Vector2(50, -46)]), WHITE_FEATHER)
	_shape(Paint.ellipse(Vector2(56, -32), Vector2(19, 17)), WHITE_FEATHER)
	_shape(PackedVector2Array([Vector2(68, -40), Vector2(86, -34), Vector2(90, -22), Vector2(80, -26), Vector2(68, -24)]), GOLD)
	draw_circle(Vector2(63, -36), 3.5, LINE)
	draw_circle(Vector2(64, -37), 1.2, Color.WHITE)
	draw_line(Vector2(55, -44), Vector2(70, -39), LINE, 3.0, true)

	_wing(Vector2(0, -18), beat, FEATHER)
	if frozen > 0.0:
		var block := Paint.ellipse(Vector2(0, -25), Vector2(100, 75))
		Paint.shape(self, block, Color(0.7, 0.9, 1.0, 0.3), Color(1, 1, 1, 0.8), 3.0)
	draw_set_transform(Vector2.ZERO)


## Feathers fanning out from the shoulder. `beat` rotates the whole wing.
func _wing(shoulder: Vector2, beat: float, color: Color) -> void:
	var lengths: Array[float] = [72.0, 92.0, 102.0, 96.0, 80.0]
	var points := PackedVector2Array([shoulder + Vector2(14, 6)])
	var tips := PackedVector2Array()
	for k in lengths.size():
		var angle := -1.45 - k * 0.3 - beat
		var tip := shoulder + Vector2.from_angle(angle) * lengths[k]
		tips.append(tip)
		points.append(tip)
		if k < lengths.size() - 1:
			points.append(shoulder + Vector2.from_angle(angle - 0.15) * lengths[k] * 0.78)
	points.append(shoulder + Vector2(-14, 6))
	_shape(points, color)
	for tip in tips:
		draw_line(shoulder, shoulder.lerp(tip, 0.7), _c(color.darkened(0.3)), 2.0, true)


func _tail() -> void:
	var points := PackedVector2Array()
	for i in 7:
		var k := i / 6.0
		points.append(Vector2(-54 - k * 40, 2 - k * 20 + sin(time * 3.0 - k * 2.0) * 6.0 * k))
	draw_polyline(points, LINE, 8.0, true)
	draw_polyline(points, _c(FUR), 5.0, true)
	draw_circle(points[6], 8.0, LINE)
	draw_circle(points[6], 6.5, _c(FUR.darkened(0.35)))


func _knight() -> void:
	# Shield, body, leg and helmet with a red plume
	_shape(PackedVector2Array([Vector2(-6, -30), Vector2(14, -30), Vector2(16, -12), Vector2(2, -12)]), armor.darkened(0.15))
	_shape(PackedVector2Array([Vector2(-22, -28), Vector2(4, -28), Vector2(8, -62), Vector2(-16, -62)]), armor)
	_shape(Paint.ellipse(Vector2(-22, -44), Vector2(12, 16)), Color(0.2, 0.35, 0.75))
	draw_line(Vector2(-22, -58), Vector2(-22, -30), _c(GOLD), 3.0)
	draw_line(Vector2(-32, -46), Vector2(-12, -46), _c(GOLD), 3.0)
	var plume := sin(time * 8.0) * 3.0
	_shape(PackedVector2Array([Vector2(-6, -84), Vector2(-34, -92 + plume), Vector2(-30, -80 + plume), Vector2(-10, -76)]), Color(0.9, 0.15, 0.15))
	_shape(Paint.ellipse(Vector2(-4, -74), Vector2(13, 13), 16), armor)
	draw_line(Vector2(0, -76), Vector2(10, -76), LINE, 3.0)

	# Lance: raised while roaming, lowered for a charge
	var hand := Vector2(10, -46)
	var dir := Vector2.from_angle(lerpf(-0.55, 0.05, lance_down))
	draw_line(hand - dir * 24, hand + dir * 120, LINE, 7.0, true)
	draw_line(hand - dir * 24, hand + dir * 120, _c(Color(0.55, 0.35, 0.18)), 4.0, true)
	var tip := hand + dir * 120
	_shape(PackedVector2Array([tip + dir * 22, tip + dir.orthogonal() * 6, tip - dir.orthogonal() * 6]), Color(0.85, 0.87, 0.9))
	var pennant := hand + dir * 92
	_shape(PackedVector2Array([pennant, pennant - dir * 22, pennant - dir * 14 + Vector2(-4, 14 + sin(time * 10.0) * 3.0)]), Color(0.9, 0.15, 0.15))
	if state == "aim":
		draw_circle(tip + dir * 22, 5.0 + sin(time * 30.0) * 3.0, Color(1, 1, 0.8, 0.9))
	draw_line(Vector2(0, -56), hand, _c(armor), 6.0)
