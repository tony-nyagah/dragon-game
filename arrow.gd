extends Node2D

var velocity := Vector2.ZERO
var life := 4.0
var big := false  # the Griffin Knight's spears


func _ready() -> void:
	if big:
		scale = Vector2(1.6, 1.6)


func _process(delta: float) -> void:
	position += velocity * delta
	rotation = velocity.angle()
	life -= delta
	if life <= 0.0:
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-60, 0), Vector2(-20, 0), Color(1, 1, 1, 0.25), 2.0)
	draw_line(Vector2(-16, 0), Vector2(12, 0), Color(0.45, 0.3, 0.15), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(18, 0), Vector2(10, -5), Vector2(10, 5)]), Color(0.6, 0.6, 0.65))
	draw_line(Vector2(-16, 0), Vector2(-22, -5), Color.WHITE, 2.0)
	draw_line(Vector2(-16, 0), Vector2(-22, 5), Color.WHITE, 2.0)
