extends Node2D
## Poison breath: a lobbed glob that splashes into a toxic puddle where it lands.

signal splash(x: float)

const GRAVITY := 900.0

var velocity := Vector2.ZERO
var kind := "poison"
var damage := 1


func already_hit(_target: Node) -> bool:
	return false


func on_contact(_target: Node) -> bool:
	_splat()
	return true


func _process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
	if randf() < 0.5:
		Effects.fire(position, Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.4, randf_range(3, 6), "poison")
	if position.y >= World.GROUND_Y:
		position.y = World.GROUND_Y
		_splat()
	elif position.x < -50.0 or position.x > World.WIDTH + 50.0:
		queue_free()
	queue_redraw()


func _splat() -> void:
	if is_queued_for_deletion():
		return
	Effects.explode(position, 0.5, "poison")
	Sfx.play("splat", -6)
	splash.emit(position.x)
	queue_free()


func _draw() -> void:
	# Stretch the blob along its direction of travel so it looks gooey.
	draw_set_transform(Vector2.ZERO, velocity.angle(), Vector2(1.3, 0.85))
	draw_circle(Vector2.ZERO, 12.0, Color(0.1, 0.3, 0.05))
	draw_circle(Vector2.ZERO, 10.0, Color(0.45, 0.88, 0.2))
	draw_circle(Vector2(3, -4), 3.5, Color(0.85, 1.0, 0.6))
	draw_set_transform(Vector2.ZERO)
