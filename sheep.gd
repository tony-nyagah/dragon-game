extends Node2D
## Wanders across the field and panics when the dragon swoops close. Worth 1 point.

const WOOL := [Vector2(-12, 0), Vector2(0, -6), Vector2(12, 0), Vector2(0, 6), Vector2(-6, 2), Vector2(6, 2)]

var dragon: Node2D
var direction := 1.0
var speed := randf_range(50.0, 100.0)
var radius := 22.0
var points := 1
var bob := randf() * TAU
var scared := false


func contains(p: Vector2) -> bool:
	return position.distance_to(p) < radius + 12.0


func center() -> Vector2:
	return position


func take_hit(_at: Vector2, _damage := 1, _breath := "fire") -> bool:
	return true


func destroy(breath := "fire") -> void:
	Effects.explode(position, 1.0, breath)
	Sfx.play("shatter" if breath == "ice" else "explode", -6)
	Sfx.play("baa", -10, 1.4)
	queue_free()


func _process(delta: float) -> void:
	var was_scared := scared
	scared = is_instance_valid(dragon) and dragon.position.distance_to(position) < 170.0
	if scared and not was_scared:
		Sfx.play("baa", -12, randf_range(0.9, 1.3))
	if scared and absf(position.x - dragon.position.x) > 4.0:
		direction = signf(position.x - dragon.position.x)

	position.x += direction * speed * (1.8 if scared else 1.0) * delta
	bob += delta * (22.0 if scared else 10.0)
	if position.x < -100.0 or position.x > World.WIDTH + 100.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	# Shadow
	draw_set_transform(Vector2(0, 20), 0.0, Vector2(1.6, 0.4))
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.2))

	var hop := -absf(sin(bob)) * (8.0 if scared else 3.0)
	draw_set_transform(Vector2(0, hop), 0.0, Vector2(direction, 1.0))
	var legs := sin(bob) * 3.0
	draw_rect(Rect2(-12 + legs, 8, 4, 12), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(8 - legs, 8, 4, 12), Color(0.15, 0.15, 0.15))
	for p in WOOL:
		draw_circle(p, 13.5, Color(0.35, 0.33, 0.33))
	for p in WOOL:
		draw_circle(p, 11.0, Color(0.98, 0.97, 0.94))
	draw_circle(Vector2(22, -4), 9.5, Color(0.35, 0.33, 0.33))
	draw_circle(Vector2(22, -4), 8.0, Color(0.15, 0.15, 0.15))
	draw_circle(Vector2(17, -10), 3.5, Color(0.15, 0.15, 0.15))
	draw_circle(Vector2(25, -6), 2.4 if scared else 1.8, Color.WHITE)

	draw_set_transform(Vector2.ZERO)
	if scared:
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(-5, -24 + hop), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color.BLACK)
		draw_string(font, Vector2(-5, -24 + hop), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 0.85, 0.2))
