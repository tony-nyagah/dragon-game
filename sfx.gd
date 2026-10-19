extends Node
## Sound effects, synthesized from scratch at startup so the game needs no audio files.
## Autoloaded as `Sfx`. Use `Sfx.play("explode")`.

const RATE := 22050

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 16:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

	_sounds.fire = _whoosh(0.22, 0.35, 0.05, 140.0)
	_sounds.dash = _whoosh(0.5, 0.03, 0.4, 0.0, true)
	_sounds.explode = _boom(0.6, 6.0)
	_sounds.boom_big = _boom(1.6, 2.2)
	_sounds.collapse = _collapse()
	_sounds.rise = _rumble(0.6)
	_sounds.baa = _baa()
	_sounds.twang = _pluck(196.0, 0.4)
	_sounds.clank = _clank()
	_sounds.hurt = _sweep(700.0, 120.0, 0.35)
	_sounds.sputter = _sputter()
	_sounds.coin = _notes([988.0, 1319.0], 0.07)
	_sounds.heal = _notes([784.0, 1047.0, 1319.0], 0.06)
	_sounds.chomp = _chomp()
	_sounds.freeze = _freeze()
	_sounds.shatter = _shatter()
	_sounds.zap = _zap()
	_sounds.glob = _glob()
	_sounds.splat = _splat()
	_sounds.switch = _notes([660.0, 990.0], 0.04)
	_sounds.roar = _roar()
	_sounds.victory = _notes([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.12)
	_sounds.gameover = _notes([523.0, 415.0, 349.0, 262.0], 0.24)


func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _sounds[sound]
	player.volume_db = volume_db
	player.pitch_scale = pitch * randf_range(0.95, 1.05)
	player.play()


# --- Synthesis -------------------------------------------------------------

## Filtered noise that sweeps from one brightness to another (fire, wind).
func _whoosh(length: float, bright_from: float, bright_to: float, thump_hz: float, swell := false) -> AudioStreamWAV:
	var out := _buffer(length)
	var lowpass := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var k := t / length
		lowpass += (randf_range(-1, 1) - lowpass) * lerpf(bright_from, bright_to, k)
		var env := minf(t / 0.015, 1.0) * (sin(PI * k) if swell else pow(1.0 - k, 2.0))
		phase += TAU * lerpf(thump_hz, thump_hz * 0.4, k) / RATE
		out[i] = lowpass * env * 1.5 + sin(phase) * env * 0.3
	return _stream(out)


## Deep rumbling noise with a low thump (explosions).
func _boom(length: float, decay: float) -> AudioStreamWAV:
	var out := _buffer(length)
	var brown := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		brown = (brown + 0.04 * randf_range(-1, 1)) / 1.02
		phase += TAU * lerpf(90.0, 30.0, t / length) / RATE
		var env := minf(t / 0.005, 1.0) * exp(-t * decay)
		out[i] = brown * env * 4.0 + sin(phase) * exp(-t * decay * 1.3)
	return _stream(out)


func _rumble(length: float) -> AudioStreamWAV:
	var out := _buffer(length)
	var brown := 0.0
	for i in out.size():
		brown = (brown + 0.04 * randf_range(-1, 1)) / 1.02
		out[i] = brown * 4.0 * sin(PI * i / out.size())
	return _stream(out)


## Rumble plus random crackles, like timber falling apart.
func _collapse() -> AudioStreamWAV:
	var out := _buffer(1.2)
	var brown := 0.0
	var crackle := 0.0
	for i in out.size():
		var t := float(i) / RATE
		brown = (brown + 0.04 * randf_range(-1, 1)) / 1.02
		if randf() < 0.0015:
			crackle = 1.0
		crackle *= 0.993
		out[i] = brown * 4.0 * exp(-t * 2.5) + randf_range(-1, 1) * crackle * 0.4 * exp(-t * 1.5)
	return _stream(out)


## A wobbly, nasal sawtooth: a sheep's "baa".
func _baa() -> AudioStreamWAV:
	var length := 0.5
	var out := _buffer(length)
	var phase := 0.0
	var lowpass := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var pitch := 330.0 * (1.0 + 0.05 * sin(TAU * 8.0 * t)) * minf(0.85 + t * 3.0, 1.0)
		phase = fposmod(phase + pitch / RATE, 1.0)
		lowpass += (phase * 2.0 - 1.0 - lowpass) * 0.25
		var env := minf(t / 0.04, 1.0) * minf((length - t) / 0.15, 1.0)
		out[i] = lowpass * env
	return _stream(out)


## Plucked string (Karplus-Strong): a bow being fired.
func _pluck(hz: float, length: float) -> AudioStreamWAV:
	var out := _buffer(length)
	var ring := PackedFloat32Array()
	ring.resize(int(RATE / hz))
	for i in ring.size():
		ring[i] = randf_range(-1, 1)
	var index := 0
	for i in out.size():
		var next := (index + 1) % ring.size()
		out[i] = ring[index]
		ring[index] = (ring[index] + ring[next]) * 0.5 * 0.995
		index = next
	return _stream(out)


## Metallic hit: a few clashing tones that die away fast.
func _clank() -> AudioStreamWAV:
	var out := _buffer(0.35)
	var tones := [[620.0, 12.0], [1530.0, 18.0], [2470.0, 25.0], [3900.0, 30.0]]
	for i in out.size():
		var t := float(i) / RATE
		var v := randf_range(-1, 1) * maxf(1.0 - t / 0.006, 0.0)
		for tone in tones:
			v += sin(TAU * tone[0] * t) * exp(-t * tone[1]) * 0.4
		out[i] = v
	return _stream(out)


## Glassy chime that rises slightly: an ice shard.
func _freeze() -> AudioStreamWAV:
	var out := _buffer(0.3)
	for i in out.size():
		var t := float(i) / RATE
		var rise := 1.0 + t * 0.8
		var tone := sin(TAU * 1800.0 * rise * t) * 0.5 + sin(TAU * 2700.0 * rise * t) * 0.3
		out[i] = (tone + randf_range(-1, 1) * 0.3 * exp(-t * 40.0)) * exp(-t * 12.0)
	return _stream(out)


## Crackly high noise plus little tinkles: ice breaking.
func _shatter() -> AudioStreamWAV:
	var out := _buffer(0.45)
	var last := 0.0
	var tinkles := []
	for k in 6:
		tinkles.append([randf_range(2500.0, 5000.0), randf_range(0.0, 0.2)])
	for i in out.size():
		var t := float(i) / RATE
		var white := randf_range(-1, 1)
		var v := (white - last) * 0.5 * exp(-t * 14.0)  # difference = high-passed noise
		last = white
		for tinkle in tinkles:
			if t >= tinkle[1]:
				v += sin(TAU * tinkle[0] * (t - tinkle[1])) * 0.25 * exp(-(t - tinkle[1]) * 20.0)
		out[i] = v
	return _stream(out)


## Buzzing hum with random crackles: lightning.
func _zap() -> AudioStreamWAV:
	var out := _buffer(0.4)
	var crackle := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		if randf() < 0.004:
			crackle = 1.0
		crackle *= 0.998
		phase = fposmod(phase + randf_range(70.0, 110.0) / RATE, 1.0)
		var buzz := 0.4 if phase < 0.5 else -0.4
		out[i] = (randf_range(-1, 1) * (0.4 + crackle) + buzz) * exp(-t * 6.0) * minf(t / 0.003, 1.0)
	return _stream(out)


## A rising "bloop": spitting a poison glob.
func _glob() -> AudioStreamWAV:
	var out := _buffer(0.2)
	var phase := 0.0
	for i in out.size():
		var k := float(i) / out.size()
		phase += TAU * lerpf(180.0, 520.0, k) / RATE
		out[i] = sin(phase) * sin(PI * k)
	return _stream(out)


## A wet, falling "splat".
func _splat() -> AudioStreamWAV:
	var out := _buffer(0.35)
	var lowpass := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lowpass += (randf_range(-1, 1) - lowpass) * 0.15
		phase += TAU * lerpf(260.0, 70.0, t / 0.35) / RATE
		out[i] = (lowpass * 1.5 + sin(phase) * 0.8) * exp(-t * 10.0)
	return _stream(out)


## Two quick crunchy bites.
func _chomp() -> AudioStreamWAV:
	var out := _buffer(0.3)
	var lowpass := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var bite := fposmod(t, 0.14)
		lowpass += (randf_range(-1, 1) - lowpass) * 0.3
		out[i] = (lowpass + sin(TAU * 110.0 * t) * 0.6) * exp(-bite * 30.0) if t < 0.28 else 0.0
	return _stream(out)


## Square wave sliding in pitch: an "ouch".
func _sweep(hz_from: float, hz_to: float, length: float) -> AudioStreamWAV:
	var out := _buffer(length)
	var phase := 0.0
	for i in out.size():
		var k := float(i) / out.size()
		phase = fposmod(phase + lerpf(hz_from, hz_to, k) / RATE, 1.0)
		out[i] = (0.5 if phase < 0.5 else -0.5) * (1.0 - k)
	return _stream(out)


## Three weak puffs: trying to breathe fire with an empty tank.
func _sputter() -> AudioStreamWAV:
	var out := _buffer(0.25)
	var lowpass := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lowpass += (randf_range(-1, 1) - lowpass) * 0.1
		var puff := fposmod(t, 0.08)
		out[i] = lowpass * 2.0 * maxf(1.0 - puff / 0.04, 0.0)
	return _stream(out)


## Low growl with a high screech on top: the griffin arriving.
func _roar() -> AudioStreamWAV:
	var length := 1.4
	var out := _buffer(length)
	var growl := 0.0
	var screech := 0.0
	var lowpass := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var k := t / length
		growl = fposmod(growl + (70.0 + 20.0 * sin(TAU * 3.0 * t)) / RATE, 1.0)
		lowpass += (growl * 2.0 - 1.0 + randf_range(-0.6, 0.6) - lowpass) * 0.08
		screech += TAU * (lerpf(1800.0, 1100.0, k) + 60.0 * sin(TAU * 30.0 * t)) / RATE
		var env := minf(t / 0.25, 1.0) * minf((length - t) / 0.5, 1.0)
		out[i] = (lowpass * 1.4 + sin(screech) * 0.25 * sin(PI * k)) * env
	return _stream(out)


## A short tune of triangle-wave notes.
func _notes(freqs: Array, note_length: float) -> AudioStreamWAV:
	var out := _buffer(note_length * (freqs.size() + 2))
	var per_note := int(note_length * RATE)
	for i in out.size():
		var note := mini(i / per_note, freqs.size() - 1)
		var t := float(i - note * per_note) / RATE
		var hz: float = freqs[note]
		var tri := absf(fposmod(t * hz, 1.0) * 4.0 - 2.0) - 1.0
		var decay := 4.0 if note == freqs.size() - 1 else 12.0
		out[i] = tri * 0.6 * exp(-t * decay)
	return _stream(out)


func _buffer(length: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(length * RATE))
	return out


func _stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.001
	for v in samples:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(samples[i] / peak * 0.9 * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream
