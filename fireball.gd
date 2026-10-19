extends Node2D

## Fire breath: a fireball that bursts on the first thing it hits.

var velocity := Vector2.ZERO
var kind := "fire"
var damage := 1
var life := 1.3
var _t := 0.0


func already_hit(_target: Node) -> bool:
	return false


## Returns true when the shot is used up.
func on_contact(_target: Node) -> bool:
	queue_free()
	return true


func _process(delta: float) -> void:
	position += velocity * delta
	_t += delta
	life -= delta

	# Flame trail
	var jitter := Vector2(randf_range(-30, 30), randf_range(-30, 30))
	Effects.fire(position + jitter * 0.15, -velocity * 0.1 + jitter, randf_range(0.15, 0.35), randf_range(4, 8))
	if randf() < 0.15:
		Effects.smoke(position, Vector2(0, -20), 0.6, 6.0)

	if position.y > World.GROUND_Y:
		Effects.explode(Vector2(position.x, World.GROUND_Y), 0.6)
		Effects.shake(3.0)
		queue_free()
	elif life <= 0.0:
		Effects.smoke(position, Vector2.ZERO, 0.5, 10.0)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var flicker := sin(_t * 40.0) * 2.0
	draw_circle(Vector2.ZERO, 24.0 + flicker, Color(1, 0.35, 0.05, 0.3))
	draw_circle(Vector2.ZERO, 15.0 + flicker, Color(0.9, 0.25, 0.05))
	draw_circle(Vector2.ZERO, 10.0, Color(1, 0.6, 0.1))
	draw_circle(Vector2.ZERO, 5.0, Color(1, 0.95, 0.55))
