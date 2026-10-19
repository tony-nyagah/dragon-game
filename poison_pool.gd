extends Node2D
## A toxic puddle left by poison breath. Hurts anything on the ground that touches it,
## once every TICK seconds per target.

const WIDTH := 120.0
const TICK := 0.5

var life := 3.5
var time := 0.0
var _last_hit := {}  # target instance id -> time it was last hurt


func _ready() -> void:
	z_index = -1
	position.y = World.GROUND_Y


func touches(target: Node) -> bool:
	if time - _last_hit.get(target.get_instance_id(), -99.0) < TICK:
		return false
	for i in 7:
		if target.contains(Vector2(position.x - WIDTH / 2 + i * WIDTH / 6, World.GROUND_Y - 12)):
			return true
	return false


func mark(target: Node) -> void:
	_last_hit[target.get_instance_id()] = time


func _process(delta: float) -> void:
	time += delta
	life -= delta
	if randf() < delta * 14.0:
		var bubble := position + Vector2(randf_range(-WIDTH, WIDTH) * 0.4, -4)
		Effects.fire(bubble, Vector2(0, -30), 0.5, randf_range(3, 6), "poison")
	if life <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var spread := minf(time * 6.0, 1.0)
	var fade := clampf(life, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(spread, 0.22))
	draw_circle(Vector2.ZERO, WIDTH / 2 + 4, Color(0.1, 0.3, 0.05, 0.8 * fade))
	draw_circle(Vector2.ZERO, WIDTH / 2, Color(0.4, 0.85, 0.2, 0.75 * fade))
	draw_circle(Vector2(-15, -10), WIDTH / 4, Color(0.7, 1.0, 0.4, 0.5 * fade))
	draw_set_transform(Vector2.ZERO)
