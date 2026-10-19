extends Node2D
## Ice breath: a fast crystal that pierces through up to three targets.

var velocity := Vector2.ZERO
var kind := "ice"
var damage := 1
var life := 0.9
var pierce := 3
var _hit: Array[Node] = []


func already_hit(target: Node) -> bool:
	return target in _hit


## Returns true when the shard is used up.
func on_contact(target: Node) -> bool:
	_hit.append(target)
	pierce -= 1
	if pierce > 0:
		return false
	Effects.explode(position, 0.3, "ice")
	queue_free()
	return true


func _process(delta: float) -> void:
	position += velocity * delta
	rotation = velocity.angle()
	life -= delta
	if randf() < 0.6:
		Effects.fire(position, -velocity * 0.05 + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.3, randf_range(2, 4), "ice")
	if position.y > World.GROUND_Y:
		Effects.explode(Vector2(position.x, World.GROUND_Y), 0.4, "ice")
		Sfx.play("shatter", -14)
		queue_free()
	elif life <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(0.6, 0.9, 1.0, 0.25))
	Paint.shape(self, PackedVector2Array([Vector2(24, 0), Vector2(2, -7), Vector2(-18, 0), Vector2(2, 7)]), Color(0.7, 0.92, 1.0), Color(0.2, 0.5, 0.85))
	draw_line(Vector2(-10, 0), Vector2(18, 0), Color(1, 1, 1, 0.9), 2.0)
