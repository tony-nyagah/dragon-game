extends Node2D
## Walks the field, stops to aim, and shoots arrows at the dragon. Worth 3 points.

signal shoot_arrow(pos: Vector2, vel: Vector2, big: bool)

const DRAW_TIME := 0.7  # how long they pull the bowstring before letting go
const LINE := Color(0.12, 0.08, 0.06)

var dragon: Node2D
var direction := 1.0
var speed := randf_range(35.0, 60.0)
var radius := 22.0
var points := 3
var reload := randf_range(1.5, 2.5)
var facing := 1.0
var aim_angle := 0.0  # bow angle, measured as if facing right
var walk := 0.0


func contains(p: Vector2) -> bool:
	return position.distance_to(p) < radius + 12.0


func center() -> Vector2:
	return position


func take_hit(_at: Vector2, _damage := 1, _breath := "fire") -> bool:
	return true


func destroy(breath := "fire") -> void:
	Effects.explode(position, 1.0, breath)
	Sfx.play("shatter" if breath == "ice" else "explode", -6)
	queue_free()


func _process(delta: float) -> void:
	if position.x < -100.0 or position.x > World.WIDTH + 100.0:
		queue_free()
		return

	var on_screen := position.x > 20.0 and position.x < World.WIDTH - 20.0
	reload -= delta
	if _drawing_bow(on_screen):
		var to_dragon := dragon.position - (position + Vector2(0, -12))
		if absf(to_dragon.x) > 1.0:
			facing = signf(to_dragon.x)
		aim_angle = Vector2(absf(to_dragon.x), to_dragon.y).angle()
	else:
		position.x += direction * speed * delta
		walk += delta * 8.0
		facing = direction
		aim_angle = lerp_angle(aim_angle, 0.4, 1.0 - exp(-8.0 * delta))

	if reload <= 0.0:
		if on_screen and is_instance_valid(dragon):
			var from := position + Vector2(0, -12) + Vector2.from_angle(aim_angle) * Vector2(facing, 1) * 20.0
			var aim := (dragon.position - from).normalized().rotated(randf_range(-0.1, 0.1))
			shoot_arrow.emit(from, aim * 430.0, false)
			Sfx.play("twang", -10)
		reload = randf_range(2.0, 3.2)
	queue_redraw()


func _drawing_bow(on_screen: bool) -> bool:
	return on_screen and reload < DRAW_TIME and is_instance_valid(dragon)


func _draw() -> void:
	draw_set_transform(Vector2(0, 20), 0.0, Vector2(1.4, 0.4))
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.2))

	var mirror := Transform2D(Vector2(facing, 0), Vector2(0, 1), Vector2.ZERO)
	draw_set_transform_matrix(mirror)

	# Legs swing while walking
	var stride := sin(walk) * 4.0
	draw_line(Vector2(-4, 8), Vector2(-4 + stride, 20), LINE, 5.0)
	draw_line(Vector2(4, 8), Vector2(4 - stride, 20), LINE, 5.0)

	# Tunic, belt, head, helmet and plume
	_shape(PackedVector2Array([Vector2(-10, -14), Vector2(10, -14), Vector2(13, 10), Vector2(-13, 10)]), Color(0.78, 0.16, 0.16))
	draw_rect(Rect2(-12, 0, 24, 3), Color(0.35, 0.22, 0.1))
	draw_circle(Vector2(0, -24), 10.5, LINE)
	draw_circle(Vector2(0, -24), 9.0, Color(0.95, 0.78, 0.6))
	var helmet := PackedVector2Array()
	for i in 9:
		helmet.append(Vector2(0, -25) + Vector2.from_angle(PI + i * PI / 8.0) * 11.0)
	_shape(helmet, Color(0.65, 0.67, 0.72))
	_shape(PackedVector2Array([Vector2(-2, -35), Vector2(-14, -42), Vector2(-12, -34)]), Color(0.95, 0.3, 0.2))
	draw_circle(Vector2(5, -22), 1.6, LINE)

	# Bow arm, rotated toward the dragon
	draw_set_transform_matrix(mirror * Transform2D(aim_angle, Vector2(0, -12)))
	var pull := 1.0 - clampf(reload / DRAW_TIME, 0.0, 1.0) if reload < DRAW_TIME else 0.0
	var tip_top := Vector2(10, 0) + Vector2.from_angle(-1.2) * 16.0
	var tip_bottom := Vector2(10, 0) + Vector2.from_angle(1.2) * 16.0
	var string_x := lerpf(tip_top.x, 0.0, pull)
	draw_line(Vector2.ZERO, Vector2(14, 0), Color(0.95, 0.78, 0.6), 4.0)
	draw_arc(Vector2(10, 0), 16.0, -1.2, 1.2, 16, Color(0.45, 0.28, 0.1), 3.5)
	draw_line(tip_top, Vector2(string_x, 0), Color(0.9, 0.9, 0.9), 1.0)
	draw_line(Vector2(string_x, 0), tip_bottom, Color(0.9, 0.9, 0.9), 1.0)
	if pull > 0.0:
		draw_line(Vector2(string_x, 0), Vector2(string_x + 30, 0), Color(0.45, 0.3, 0.15), 2.0)

	draw_set_transform(Vector2.ZERO)


func _shape(points: PackedVector2Array, fill: Color) -> void:
	Paint.shape(self, points, fill, LINE)
