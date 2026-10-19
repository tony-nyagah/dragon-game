extends Node2D
## Sky, sun or moon, mountains, clouds, hills, trees, grass and weather, colored by a theme
## from themes.gd. Far layers shift a little as the dragon moves, which gives a sense of depth.

const W := World.WIDTH
const H := World.HEIGHT
const GROUND_Y := World.GROUND_Y

var dragon: Node2D
var theme: Dictionary = Themes.ALL.day
var time := 0.0
var look := 0.0  # smoothed distance of the dragon from the screen center


func _ready() -> void:
	z_index = -10


func _process(delta: float) -> void:
	time += delta
	if is_instance_valid(dragon):
		look = lerpf(look, dragon.position.x - W / 2.0, 1.0 - exp(-3.0 * delta))
	queue_redraw()


func _draw() -> void:
	_draw_sky()
	if theme.get("stars"):
		_draw_stars()
	_draw_sun(theme.sun_pos - Vector2(look * 0.02, 0))
	var peaks: Array[float] = [90.0, 40.0, 18.0]
	var peak_freqs: Array[float] = [0.004, 0.011, 0.027]
	var mountains := _draw_ridge(look * 0.05, 460.0, peaks, peak_freqs, theme.mountains)
	if theme.get("snowcaps"):
		_draw_snowcaps(mountains, 385.0)
	if theme.get("lava"):
		_gradient_rect(Rect2(-60, 470, W + 120, GROUND_Y - 470), Color(1, 0.3, 0.05, 0.0), Color(1, 0.35, 0.05, 0.45))
	_draw_clouds()
	_draw_ridge(look * 0.12 + 300.0, 570.0, [35.0, 18.0, 8.0], [0.006, 0.017, 0.04], theme.hills)
	_draw_trees(look * 0.25)
	_draw_ground()
	_draw_dragon_shadow()
	if theme.get("snow"):
		_draw_falling(Color(1, 1, 1, 0.9), 1.0)
	if theme.get("embers"):
		_draw_falling(Color(1, 0.55, 0.15, 0.9), -1.0)


func _draw_sky() -> void:
	_gradient_rect(Rect2(-60, -60, W + 120, 400), theme.sky_top, theme.sky_mid)
	_gradient_rect(Rect2(-60, 340, W + 120, GROUND_Y - 330), theme.sky_mid, theme.horizon)


func _draw_stars() -> void:
	for i in 90:
		var p := Vector2(_hash(i + 3000) * W, _hash(i + 4000) * 420.0)
		var twinkle := 0.5 + 0.5 * sin(time * (1.0 + _hash(i) * 3.0) + i)
		draw_circle(p, 1.0 + _hash(i + 5000) * 1.2, Color(1, 1, 0.9, 0.3 + 0.6 * twinkle))


func _draw_sun(center: Vector2) -> void:
	var size: float = theme.sun_size
	for i in 4:
		draw_circle(center, size * 2.5 - i * size * 0.45, Color(theme.sun_glow, 0.08 + i * 0.04))
	draw_circle(center, size, theme.sun)
	if theme.get("moon"):
		# A second circle in the sky color carves out a crescent.
		draw_circle(center + Vector2(size * 0.45, -size * 0.2), size * 0.85, theme.sky_top.lerp(theme.sky_mid, 0.3))


## A wavy silhouette (mountains or hills) built from a few sine waves. Returns its outline.
func _draw_ridge(offset: float, base: float, amps: Array[float], freqs: Array[float], color: Color) -> PackedVector2Array:
	var points := PackedVector2Array()
	var x := -60.0
	while x <= W + 60.0:
		var y := base
		for i in amps.size():
			y -= amps[i] * (0.5 + 0.5 * sin((x + offset) * freqs[i] + i * 1.7))
		points.append(Vector2(x, y))
		x += 16.0
	var top := points.duplicate()
	points.append(Vector2(W + 60.0, GROUND_Y + 10.0))
	points.append(Vector2(-60.0, GROUND_Y + 10.0))
	draw_colored_polygon(points, color)
	return top


## Snow on the parts of a ridge higher than `snow_line`, thicker on taller peaks.
func _draw_snowcaps(ridge: PackedVector2Array, snow_line: float) -> void:
	var snow := Color(0.97, 0.98, 1.0)
	for i in ridge.size() - 1:
		var a := ridge[i]
		var b := ridge[i + 1]
		if a.y >= snow_line and b.y >= snow_line:
			continue
		var depth_a := clampf((snow_line - a.y) * 0.6, 0.0, 34.0)
		var depth_b := clampf((snow_line - b.y) * 0.6, 0.0, 34.0)
		draw_primitive(PackedVector2Array([a, b, b + Vector2(0, depth_b), a + Vector2(0, depth_a)]), PackedColorArray([snow, snow, snow, snow]), PackedVector2Array())


func _draw_clouds() -> void:
	for i in 6:
		var x := fposmod(i * 230.0 + time * (10.0 + i * 3.0) - look * 0.08, W + 400.0) - 200.0
		var y := 70.0 + (i % 3) * 55.0
		var s := 0.7 + ((i * 7) % 5) * 0.12
		for layer in 2:
			var color: Color = theme.cloud_shade if layer == 0 else theme.cloud
			var drop := 8.0 if layer == 0 else 0.0
			for j in 4:
				draw_circle(Vector2(x + j * 34.0 * s, y - (j % 2) * 16.0 * s + drop), 30.0 * s, color)


func _draw_trees(offset: float) -> void:
	var spacing := 64.0
	var snowy: bool = theme.get("snowcaps", false)
	for i in range(floori((offset - 80.0) / spacing), ceili((offset + W + 80.0) / spacing) + 1):
		if _hash(i + 1000) < 0.3:
			continue  # leave gaps so it looks like a natural tree line
		var r := _hash(i)
		var x := i * spacing - offset + (r - 0.5) * 30.0
		var height := 50.0 + r * 50.0
		var base := GROUND_Y + 4.0
		draw_rect(Rect2(x - 3, base - 12, 6, 12), Color(0.3, 0.22, 0.15))
		var color: Color = theme.trees.lerp(theme.trees.lightened(0.2), r)
		for k in 3:
			var half_width := (22.0 - k * 5.0) * (0.7 + r * 0.5)
			var y := base - 8.0 - k * height * 0.26
			var tip := Vector2(x, y - height * 0.45)
			draw_colored_polygon(PackedVector2Array([Vector2(x - half_width, y), Vector2(x + half_width, y), tip]), color)
			if snowy:
				draw_colored_polygon(PackedVector2Array([tip.lerp(Vector2(x - half_width, y), 0.4), tip.lerp(Vector2(x + half_width, y), 0.4), tip]), Color(0.97, 0.98, 1.0))


func _draw_ground() -> void:
	_gradient_rect(Rect2(-60, GROUND_Y, W + 120, 140), theme.ground_top, theme.ground_bottom)
	draw_rect(Rect2(-60, GROUND_Y, W + 120, 4), theme.ground_top.lightened(0.15))
	var flowers: bool = not theme.get("no_flowers", false)
	for i in 80:
		var r := _hash(i + 500)
		var base := Vector2(i * 17.0 + r * 12.0, GROUND_Y + 8.0 + _hash(i + 900) * 64.0)
		var sway := sin(time * 2.0 + base.x * 0.03) * 3.0
		var height := 7.0 + r * 9.0
		for dx in [-4.0, 0.0, 4.0]:
			draw_line(base + Vector2(dx, 0), base + Vector2(dx * 1.6 + sway, -height), theme.grass, 2.0, true)
		if flowers and r > 0.82:
			var petal: Color = [Color(1, 0.95, 0.5), Color(1, 0.6, 0.75), Color.WHITE][i % 3]
			draw_circle(base + Vector2(sway, -height - 2), 3.5, petal)


## Snowflakes (direction 1, falling) or embers (direction -1, rising), drifting with the wind.
func _draw_falling(color: Color, direction: float) -> void:
	for i in 110:
		var speed := 30.0 + _hash(i + 6000) * 50.0
		var x := fposmod(_hash(i + 7000) * W + sin(time * 0.8 + i) * 25.0 + time * 12.0, W)
		var y := fposmod(_hash(i + 8000) * H + time * speed * direction, H)
		draw_circle(Vector2(x, y), 1.5 + _hash(i + 9000) * 2.0, color)


func _draw_dragon_shadow() -> void:
	if not is_instance_valid(dragon):
		return
	var height := clampf((GROUND_Y - dragon.position.y) / 600.0, 0.0, 1.0)
	var s := lerpf(1.0, 0.45, height)
	draw_set_transform(Vector2(dragon.position.x, GROUND_Y + 10.0), 0.0, Vector2(s * 2.2, s * 0.35))
	draw_circle(Vector2.ZERO, 28.0, Color(0, 0, 0, 0.25 * s))
	draw_set_transform(Vector2.ZERO)


func _gradient_rect(r: Rect2, from: Color, to: Color) -> void:
	draw_polygon(
		PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([from, from, to, to])
	)


## Stable pseudo-random number in [0, 1) for a given index.
func _hash(i: int) -> float:
	return fposmod(sin(i * 12.9898) * 43758.5453, 1.0)
