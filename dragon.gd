extends Node2D
## The player. Flies with WASD/arrows, aims with the mouse, breathes fire (or ice,
## lightning or poison: see breaths.gd).

signal shoot(pos: Vector2, dir: Vector2, breath: String)

const SPEED := 440.0
const ENERGY_MAX := 100.0
const ENERGY_REGEN := 40.0  # per second, once you stop breathing
const TURN_STIFFNESS := 260.0  # how hard the body swings toward the new direction
const TURN_DAMPING := 16.0  # lower = more overshoot and wobble after turning
const NECK_PIVOT := Vector2(22, -4)  # the head and neck bend around this point
const MOUTH := Vector2(68, -18)

const BODY := Color(0.2, 0.62, 0.36)
const LINE := Color(0.05, 0.18, 0.12)
const BELLY := Color(0.98, 0.84, 0.42)
const WING := Color(0.27, 0.72, 0.45)
const WING_BACK := Color(0.14, 0.45, 0.3)

var velocity := Vector2.ZERO
var cooldown := 0.0
var flap := 0.0
var facing := 1.0  # which way the dragon wants to face: 1 = right, -1 = left
var turn := 1.0  # where its body actually is in the turn; springs toward `facing`
var turn_speed := 0.0
var head_angle := 0.0  # the neck bends to point the head at your aim
var invulnerable := 0.0
var mouth := 0.0  # 1 right after breathing fire, fades back to 0
var time := 0.0
var aim := Vector2.RIGHT
var smoke_timer := 0.0
var energy := ENERGY_MAX
var breath_index := 0
var unlocked := Breaths.LIST.size()  # how many breaths this level allows
var accent: Color = Breaths.LIST[0].color  # spines, horns and tail tip take the breath's color
var regen_delay := 0.0
var sputter_cooldown := 0.0


func _ready() -> void:
	z_index = 1


func breath() -> Dictionary:
	return Breaths.LIST[breath_index]


func _unhandled_input(event: InputEvent) -> void:
	var count := unlocked
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode < KEY_1 + count:
			_select_breath(event.physical_keycode - KEY_1)
		elif event.physical_keycode == KEY_Q:
			_select_breath((breath_index + count - 1) % count)
		elif event.physical_keycode == KEY_E:
			_select_breath((breath_index + 1) % count)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_breath((breath_index + count - 1) % count)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_breath((breath_index + 1) % count)


func _select_breath(index: int) -> void:
	if index == breath_index or index >= unlocked:
		return
	breath_index = index
	Sfx.play("switch", -10)
	Effects.text(position + Vector2(0, -70), breath().name, breath().color, 22)
	for i in 10:
		Effects.fire(to_global(_mouth_pos()), Vector2.from_angle(randf() * TAU) * 80.0, 0.3, 4.0, breath().id)


func _process(delta: float) -> void:
	time += delta
	accent = accent.lerp(breath().color, 1.0 - exp(-10.0 * delta))
	var input := Vector2(
		_key_axis([KEY_A, KEY_LEFT], [KEY_D, KEY_RIGHT]),
		_key_axis([KEY_W, KEY_UP], [KEY_S, KEY_DOWN])
	).normalized()

	# Ease toward the target speed so flying feels floaty.
	velocity = velocity.lerp(input * SPEED, 1.0 - exp(-8.0 * delta))
	position += velocity * delta
	position = position.clamp(Vector2(60, 50), Vector2(World.WIDTH - 60, World.GROUND_Y - 50))

	aim = get_global_mouse_position() - global_position
	# Only turn around once you aim clearly behind, so small mouse wiggles don't flip it.
	if absf(aim.x) > 30.0:
		facing = signf(aim.x)
	# The body swings around like a spring: quick, with a little overshoot that settles.
	turn_speed += (facing - turn) * TURN_STIFFNESS * delta
	turn_speed *= exp(-TURN_DAMPING * delta)
	turn = clampf(turn + turn_speed * delta, -1.1, 1.1)

	# Nose dips when diving and lifts when climbing, and rears up a little mid-turn.
	var mid_turn := 1.0 - minf(absf(turn), 1.0)
	rotation = lerp_angle(rotation, (velocity.y / SPEED * 0.3 - mid_turn * 0.2) * facing, 1.0 - exp(-10.0 * delta))

	# The head leads: it bends up or down toward the aim before the body follows.
	var local_aim := aim.rotated(-rotation)
	var head_target := clampf(Vector2(absf(local_aim.x), local_aim.y).angle(), -0.55, 0.45)
	head_angle = lerp_angle(head_angle, head_target, 1.0 - exp(-12.0 * delta))

	cooldown -= delta
	sputter_cooldown -= delta
	regen_delay -= delta
	if regen_delay <= 0.0:
		energy = minf(energy + ENERGY_REGEN * delta, ENERGY_MAX)
	mouth = maxf(mouth - delta * 4.0, 0.0)
	var b := breath()
	var firing := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_physical_key_pressed(KEY_SPACE)
	if firing and cooldown <= 0.0 and energy < b.cost and sputter_cooldown <= 0.0:
		# Not enough energy: just a sad puff of smoke.
		sputter_cooldown = 0.35
		Effects.smoke(to_global(_mouth_pos()), Vector2(facing * 60, -20), 0.6, 8.0, b.puff)
		Sfx.play("sputter", -6)
	elif firing and cooldown <= 0.0 and energy >= b.cost:
		cooldown = b.cooldown
		energy -= b.cost
		regen_delay = 0.35
		mouth = 1.0
		Sfx.play(b.sound, b.volume)
		var dir := aim.normalized() if aim.length() > 1.0 else Vector2(facing, 0)
		var muzzle := to_global(_mouth_pos())
		shoot.emit(muzzle, dir, b.id)
		for i in 6:
			Effects.fire(muzzle, dir.rotated(randf_range(-0.5, 0.5)) * randf_range(80, 220), randf_range(0.1, 0.25), randf_range(4, 8), b.id)

	# Little puffs of smoke from the nostrils.
	smoke_timer -= delta
	if smoke_timer <= 0.0:
		smoke_timer = randf_range(0.4, 1.0)
		Effects.smoke(to_global(_mouth_pos() + Vector2(-4 * facing, -4)), Vector2(20 * facing, -40), 0.9, 4.0, breath().puff)

	# Faster flapping while moving, and a few hard beats while turning.
	flap += delta * (7.0 + velocity.length() / 40.0 + absf(turn_speed) * 1.5)

	invulnerable -= delta
	modulate.a = 0.35 if invulnerable > 0.0 and int(invulnerable * 20.0) % 2 == 0 else 1.0
	queue_redraw()


func _key_axis(negative: Array, positive: Array) -> float:
	var value := 0.0
	if negative.any(func(k): return Input.is_physical_key_pressed(k)):
		value -= 1.0
	if positive.any(func(k): return Input.is_physical_key_pressed(k)):
		value += 1.0
	return value


func _bob() -> float:
	return sin(time * 3.0) * 3.0


## Where the mouth is, relative to the dragon, wherever the head is pointing.
func _mouth_pos() -> Vector2:
	return _body_transform() * (_head_transform() * MOUTH)


## Everything is drawn facing right, then this mirrors it by how far through a turn we are.
## Mid-turn the body narrows (as if swinging around toward the camera) and stretches a little
## taller, but never goes paper-thin: it flips over at 40% width, which reads as a body turning.
func _body_transform() -> Transform2D:
	var side := 1.0 if turn >= 0.0 else -1.0
	var width := side * lerpf(0.4, 1.0, minf(absf(turn), 1.0)) * maxf(absf(turn), 1.0)
	var tall := 1.0 + (1.0 - minf(absf(turn), 1.0)) * 0.12
	return Transform2D(Vector2(width, 0), Vector2(0, tall), Vector2(0, _bob()))


func _head_transform() -> Transform2D:
	return Transform2D(head_angle, NECK_PIVOT) * Transform2D(0.0, -NECK_PIVOT)


func _draw() -> void:
	var body := _body_transform()
	var head := body * _head_transform()
	draw_set_transform_matrix(body)

	_wing(Vector2(10, 0), sin(flap - 0.5) * 24.0, WING_BACK)
	_tail()

	# Legs
	_shape(PackedVector2Array([Vector2(-20, 10), Vector2(-10, 10), Vector2(-8, 26), Vector2(-20, 26)]), WING_BACK)
	_shape(PackedVector2Array([Vector2(8, 10), Vector2(18, 10), Vector2(20, 26), Vector2(8, 26)]), WING_BACK)

	# Spines peeking over the back
	for i in 5:
		var x := -26.0 + i * 10.0
		var y := -22.0 * sqrt(1.0 - pow(x / 36.0, 2))
		_shape(PackedVector2Array([Vector2(x - 5, y + 4), Vector2(x + 5, y + 4), Vector2(x - 1, y - 8)]), accent)

	# Neck (bends with the head), body and striped belly
	draw_set_transform_matrix(head)
	_shape(PackedVector2Array([Vector2(14, -14), Vector2(36, -34), Vector2(50, -20), Vector2(28, 4)]), BODY)
	draw_set_transform_matrix(body)
	_shape(Paint.ellipse(Vector2.ZERO, Vector2(36, 22)), BODY)
	_shape(Paint.ellipse(Vector2(6, 9), Vector2(24, 9)), BELLY)
	for i in 4:
		draw_line(Vector2(-8 + i * 8, 2), Vector2(-10 + i * 8, 16), BELLY.darkened(0.2), 1.5)

	draw_set_transform_matrix(head)
	_head()
	draw_set_transform_matrix(body)
	_wing(Vector2.ZERO, sin(flap) * 24.0, WING)

	draw_set_transform(Vector2.ZERO)


func _head() -> void:
	# Lower jaw swings open when breathing fire.
	var pivot := Vector2(48, -16)
	var jaw := PackedVector2Array()
	for p in [Vector2(48, -16), Vector2(68, -16), Vector2(64, -10), Vector2(46, -8)]:
		jaw.append(pivot + (p - pivot).rotated(mouth * 0.5))
	if mouth > 0.05:
		_shape(PackedVector2Array([pivot, Vector2(68, -16), jaw[1]]), Color(0.5, 0.05, 0.05))
		draw_circle(Vector2(66, -15), 9.0 * mouth, Color(breath().color, mouth))
	_shape(jaw, BODY)

	_shape(PackedVector2Array([Vector2(30, -34), Vector2(16, -50), Vector2(38, -38)]), accent)
	_shape(PackedVector2Array([Vector2(38, -36), Vector2(30, -54), Vector2(46, -38)]), BELLY)
	_shape(Paint.ellipse(Vector2(44, -24), Vector2(16, 14)), BODY)
	_shape(PackedVector2Array([Vector2(50, -34), Vector2(70, -24), Vector2(68, -16), Vector2(46, -16)]), BODY)

	# Eye looks toward where you're aiming.
	var local_aim := aim.rotated(-rotation)
	var look := Vector2(absf(local_aim.x), local_aim.y).normalized().rotated(-head_angle) * 1.8
	draw_circle(Vector2(48, -27), 5.5, Color.WHITE)
	draw_circle(Vector2(48, -27) + look, 2.6, Color.BLACK)
	draw_line(Vector2(42, -34), Vector2(54, -31), LINE, 2.5, true)
	draw_circle(Vector2(66, -22), 1.6, LINE)


## A bat-like wing: an arm bone with three fingers and a membrane between them.
func _wing(o: Vector2, wy: float, color: Color) -> void:
	var shoulder := o + Vector2(4, -14)
	var elbow := o + Vector2(-6, -52 + wy)
	var tip1 := o + Vector2(-46, -46 + wy * 0.9)
	var dip1 := o + Vector2(-34, -34 + wy * 0.75)
	var tip2 := o + Vector2(-40, -24 + wy * 0.6)
	var dip2 := o + Vector2(-26, -20 + wy * 0.5)
	var tip3 := o + Vector2(-22, -12 + wy * 0.2)
	_shape(PackedVector2Array([shoulder, elbow, tip1, dip1, tip2, dip2, tip3]), color)
	var bone := color.darkened(0.35)
	draw_line(shoulder, elbow, bone, 4.0, true)
	for tip in [tip1, tip2, tip3]:
		draw_line(elbow, tip, bone, 2.0, true)


## A tapering tail that swishes in a wave, ending in a spade.
func _tail() -> void:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in 8:
		var k := i / 7.0
		var x := -28.0 - k * 60.0
		# The tail whips harder while turning.
		var swish := 8.0 + minf(absf(turn_speed) * 2.5, 16.0)
		var y := 4.0 + sin(time * 4.0 - k * 3.0) * swish * k
		var half_width := lerpf(11.0, 2.0, k)
		top.append(Vector2(x, y - half_width))
		bottom.append(Vector2(x, y + half_width))
	var tip := top[7].lerp(bottom[7], 0.5)
	bottom.reverse()
	_shape(top + bottom, BODY)
	_shape(PackedVector2Array([tip + Vector2(4, 0), tip + Vector2(-8, -10), tip + Vector2(-18, 0), tip + Vector2(-8, 10)]), accent)


func _shape(points: PackedVector2Array, fill: Color) -> void:
	Paint.shape(self, points, fill, LINE)
