extends Node2D
## A guard's helmet, spat out after the dragon eats them. Tumbles, bounces and fades away.

const LINE := Color(0.12, 0.08, 0.06)

var velocity := Vector2.ZERO
var spin := 12.0
var life := 2.5
var bounces := 0


func _process(delta: float) -> void:
	velocity.y += 900.0 * delta
	position += velocity * delta
	rotation += spin * delta
	if position.y > World.GROUND_Y - 6.0 and velocity.y > 0.0:
		position.y = World.GROUND_Y - 6.0
		velocity *= Vector2(0.6, -0.45)
		spin *= 0.5
		if bounces < 2:
			Sfx.play("clank", -14, 1.3)
		bounces += 1
	life -= delta
	modulate.a = clampf(life, 0.0, 1.0)
	if life <= 0.0:
		queue_free()


func _draw() -> void:
	var dome := PackedVector2Array()
	for i in 9:
		dome.append(Vector2.from_angle(PI + i * PI / 8.0) * 11.0)
	Paint.shape(self, dome, Color(0.65, 0.67, 0.72), LINE)
	Paint.shape(self, PackedVector2Array([Vector2(-2, -10), Vector2(-14, -17), Vector2(-12, -9)]), Color(0.95, 0.3, 0.2), LINE)
