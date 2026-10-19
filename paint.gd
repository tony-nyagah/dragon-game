class_name Paint
## Small drawing helpers shared by the hand-drawn characters.


## Filled polygon with a cartoon outline.
static func shape(canvas: CanvasItem, points: PackedVector2Array, fill: Color, outline: Color, width := 2.0) -> void:
	canvas.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, outline, width, true)


static func ellipse(center: Vector2, radii: Vector2, segments := 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		points.append(center + Vector2.from_angle(i * TAU / segments) * radii)
	return points
