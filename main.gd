extends Node2D
## Runs one level: spawns everything from the level's settings (levels.gd), checks hits,
## tracks score and goals, and handles pause, level complete and game over.
##
## Anything you can hit is in the "targets" group and has:
##   contains(point) -> bool                   is this point inside me?
##   center() -> Vector2                       where lightning should strike me
##   take_hit(point, damage, breath) -> bool   I got hit; return true if that destroyed me
##   destroy(breath)                           play my death effects and go away
##   points                                    score for destroying me
##   freeze(seconds)                           (optional) what ice does to me
##
## Dragon shots are in the "breath" group and have:
##   kind, damage, already_hit(target), on_contact(target) -> bool (true = used up)

const Background = preload("res://background.gd")
const Hud = preload("res://hud.gd")
const Dragon = preload("res://dragon.gd")
const Fireball = preload("res://fireball.gd")
const IceShard = preload("res://ice_shard.gd")
const PoisonGlob = preload("res://poison_glob.gd")
const PoisonPool = preload("res://poison_pool.gd")
const Sheep = preload("res://sheep.gd")
const Archer = preload("res://archer.gd")
const Arrow = preload("res://arrow.gd")
const Structure = preload("res://structure.gd")
const Boss = preload("res://boss.gd")
const Helmet = preload("res://helmet.gd")

const COMBO_WINDOW := 2.0  # seconds you have to burn the next thing to keep a combo going
const FIRST_BOSS_SCORE := 60  # endless mode
const BOSS_SCORE_GAP := 150  # endless mode
const MAX_LIVES := 3
const EAT_DISTANCE := 65.0
const LIGHTNING_RANGE := 700.0
const LIGHTNING_CHAIN_RANGE := 260.0
const LIGHTNING_CHAINS := 3  # first strike plus two jumps
const FREEZE_SECONDS := 1.5
const KILL_NAMES := {
	sheep = "Burn sheep", archer = "Defeat archers", house = "Burn houses",
	tower = "Topple towers", building = "Destroy buildings",
}

var level: Dictionary
var level_index := 0
var endless := false
var state := "playing"  # playing, paused, complete, dead
var world: Node2D  # everything that freezes when the game is paused

var dragon: Node2D
var hud: Control
var boss: Node2D
var boss_level := 0
var boss_spawned := false
var next_boss_score := FIRST_BOSS_SCORE
var score := 0
var lives := MAX_LIVES
var combo := 0
var combo_timer := 0.0
var spawn_timer := 1.0
var structure_timer := 0.0
var elapsed := 0.0
var kills := {}
var eaten := 0
var _end_screen_ready := false  # keys on the end screen only work once it's showing


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Effects.clear()

	level_index = Progress.current
	level = Levels.get_level(level_index)
	endless = level.get("endless", false)
	lives = level.get("start_lives", MAX_LIVES)
	structure_timer = level.get("first_structure", 0.0)

	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	var background := Background.new()
	background.theme = Themes.ALL[level.theme]
	world.add_child(background)

	dragon = Dragon.new()
	dragon.position = Vector2(World.WIDTH / 2, 300)
	dragon.scale = Vector2(1.3, 1.3)
	dragon.unlocked = level.breaths
	dragon.shoot.connect(_on_dragon_shoot)
	world.add_child(dragon)
	background.dragon = dragon

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.breaths_unlocked = level.breaths
	hud.lives = lives
	hud.level_title = "ENDLESS  ·  BEST %d" % Progress.best(-1) if endless else "LEVEL %d: %s" % [level_index + 1, level.name.to_upper()]
	layer.add_child(hud)
	_update_goals()

	hud.banner("Endless" if endless else "Level %d: %s" % [level_index + 1, level.name], level.hint)
	if not endless and level_index > 0 and level.breaths > Levels.LIST[level_index - 1].breaths:
		get_tree().create_timer(3.2).timeout.connect(_announce_new_breath)


func _announce_new_breath() -> void:
	var breath: Dictionary = Breaths.LIST[level.breaths - 1]
	hud.banner("NEW BREATH: %s!" % breath.name, "Press %d to use it" % level.breaths)
	Sfx.play("victory", -8)


func _process(delta: float) -> void:
	_update_hud()
	if state != "playing":
		return
	elapsed += delta

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var every: Array = level.spawn_every
		# In endless mode creatures come faster the longer you last. Fewer come during a boss fight.
		var pace := clampf(1.0 - elapsed / 120.0, 0.35, 1.0) if endless else 1.0
		spawn_timer = randf_range(every[0], every[1]) * pace * (2.0 if _boss_alive() else 1.0)
		_spawn_creature()

	if level.has("structures"):
		structure_timer -= delta
		if structure_timer <= 0.0:
			structure_timer = randf_range(level.structure_every[0], level.structure_every[1])
			_spawn_structure()

	if not is_instance_valid(boss):
		if endless and score >= next_boss_score:
			_spawn_boss()
		elif not endless and not boss_spawned and level.get("boss_at", -1.0) >= 0.0 and elapsed >= level.boss_at:
			_spawn_boss()

	combo_timer -= delta
	if combo_timer <= 0.0:
		combo = 0

	_check_hits()
	if _update_goals():
		_complete()


func _update_hud() -> void:
	hud.score = score
	hud.lives = lives
	hud.combo = combo
	hud.combo_left = clampf(combo_timer / COMBO_WINDOW, 0.0, 1.0)
	hud.boss_hp = float(boss.hp) / boss.max_hp if _boss_alive() else -1.0
	if is_instance_valid(dragon):
		hud.energy = dragon.energy / dragon.ENERGY_MAX
		hud.energy_low = dragon.energy < dragon.breath().cost
		hud.breath_index = dragon.breath_index


func _boss_alive() -> bool:
	return is_instance_valid(boss) and not boss.dying


# --- Goals -----------------------------------------------------------------

## Refreshes the goal checklist; returns true once every goal is met.
func _update_goals() -> bool:
	var list := []
	var all_done: bool = not level.goals.is_empty()
	for goal in level.goals:
		var have := 0
		var need := 1
		match goal.type:
			"score":
				have = score
				need = goal.count
			"kill":
				have = kills.get(goal.what, 0)
				need = goal.count
			"eat":
				have = eaten
				need = goal.count
			"survive":
				have = int(elapsed)
				need = goal.seconds
		var done := have >= need
		all_done = all_done and done
		list.append({text = _goal_text(goal, mini(have, need), need), done = done})
	hud.goals = list
	return all_done


func _goal_text(goal: Dictionary, have: int, need: int) -> String:
	match goal.type:
		"score":
			return "Score %d / %d" % [have, need]
		"eat":
			return "Eat sheep or guards %d / %d" % [have, need]
		"survive":
			return "Survive %ds / %ds" % [have, need]
		"kill" when goal.what == "boss":
			return "Defeat the %s" % level.get("boss_title", "GRIFFIN KNIGHT").capitalize()
		"kill":
			return "%s %d / %d" % [KILL_NAMES[goal.what], have, need]
	return ""


func _kind_of(target: Node) -> String:
	if target == boss:
		return "boss"
	if target.get_script() == Structure:
		return target.kind
	return "sheep" if target.get_script() == Sheep else "archer"


# --- Spawning --------------------------------------------------------------

func _spawn_creature() -> void:
	var from_left := randf() < 0.5
	var archer_chance: float = level.archer_chance
	if endless:
		archer_chance = minf(archer_chance + elapsed / 200.0, 0.55)
	var creature: Node2D
	if randf() < archer_chance:
		creature = Archer.new()
		creature.shoot_arrow.connect(_on_shoot_arrow)
	else:
		creature = Sheep.new()
	creature.dragon = dragon
	creature.direction = 1.0 if from_left else -1.0
	creature.position = Vector2(-40.0 if from_left else World.WIDTH + 40.0, World.GROUND_Y - 20.0)
	creature.add_to_group("targets")
	world.add_child(creature)


func _spawn_structure() -> void:
	var existing := get_tree().get_nodes_in_group("structures")
	if existing.size() >= level.get("max_structures", 2):
		return
	# Find a spot that isn't on top of another building.
	for attempt in 10:
		var x := randf_range(160.0, World.WIDTH - 160.0)
		if existing.all(func(s): return absf(s.position.x - x) > 260.0):
			var structure := Structure.new()
			structure.setup(level.structures.pick_random())
			structure.dragon = dragon
			structure.position = Vector2(x, World.GROUND_Y)
			structure.shoot_arrow.connect(_on_shoot_arrow)
			structure.add_to_group("targets")
			structure.add_to_group("structures")
			world.add_child(structure)
			return


func _spawn_boss() -> void:
	boss_spawned = true
	boss = Boss.new()
	boss.setup(boss_level if endless else level.get("boss_level", 0), level.get("boss_title", "GRIFFIN KNIGHT"))
	boss.dragon = dragon
	boss.shoot_arrow.connect(_on_shoot_arrow)
	boss.add_to_group("targets")
	world.add_child(boss)
	hud.boss_title = boss.title
	next_boss_score = 1 << 30  # endless: don't spawn another until this one is beaten
	hud.banner("THE %s APPROACHES!" % boss.title)


# --- Pause, level complete, game over --------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: Key = event.physical_keycode
	match state:
		"playing":
			if key == KEY_ESCAPE or key == KEY_P:
				_pause(true)
		"paused":
			if key == KEY_ESCAPE or key == KEY_P:
				_pause(false)
			elif key == KEY_R:
				_restart()
			elif key == KEY_M:
				_to_menu()
		"complete", "dead":
			if not _end_screen_ready:
				return
			if key == KEY_R:
				_restart()
			elif key == KEY_M or key == KEY_ESCAPE:
				_to_menu()
			elif (key == KEY_ENTER or key == KEY_KP_ENTER) and state == "complete":
				_next_level()


func _pause(paused: bool) -> void:
	state = "paused" if paused else "playing"
	get_tree().paused = paused
	if paused:
		_show_overlay("PAUSED", Color.WHITE, ["Esc: resume    R: restart level    M: menu"])
	else:
		hud.overlay_title = ""


func _complete() -> void:
	state = "complete"
	dragon.invulnerable = 999.0
	var new_best := Progress.record(level_index, score)
	Progress.complete(level_index)
	Sfx.play("victory")
	hud.banner("LEVEL COMPLETE!")
	await _slow_motion(0.4, 1.2)
	var last := level_index == Levels.LIST.size() - 1
	var score_line := "Score: %d%s" % [score, "   NEW BEST!" if new_best else ""]
	if last:
		_show_overlay("YOU BEAT THE GAME!", Color(1, 0.85, 0.3), ["The Griffin King has fallen.", score_line, "Enter: menu    R: play again"])
	else:
		_show_overlay("LEVEL COMPLETE!", Color(1, 0.85, 0.3), [score_line, "Enter: next level    R: play again    M: menu"])


func _show_overlay(title: String, color: Color, lines: Array) -> void:
	hud.overlay_title = title
	hud.overlay_color = color
	hud.overlay_lines = lines
	_end_screen_ready = true


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _next_level() -> void:
	if level_index >= Levels.LIST.size() - 1:
		_to_menu()
		return
	Progress.current = level_index + 1
	_restart()


func _to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://menu.tscn")


# --- Collisions ------------------------------------------------------------

func _check_hits() -> void:
	var targets := get_tree().get_nodes_in_group("targets")
	var arrows := get_tree().get_nodes_in_group("arrows")

	for shot in get_tree().get_nodes_in_group("breath"):
		if shot.is_queued_for_deletion():
			continue
		# Breath hits creatures, buildings and bosses...
		for target in targets:
			if _gone(target) or shot.already_hit(target) or not target.contains(shot.position):
				continue
			_damage(target, shot.position, shot.kind, shot.damage)
			if shot.on_contact(target):
				break
		# ...and knocks arrows out of the air.
		for arrow in arrows:
			if _gone(arrow) or shot.is_queued_for_deletion():
				continue
			if shot.position.distance_to(arrow.position) < 24.0 * arrow.scale.x:
				Effects.explode(arrow.position, 0.4, shot.kind)
				Sfx.play("explode", -16, 1.6)
				arrow.queue_free()

	# Poison puddles hurt whatever is standing in them.
	for pool in get_tree().get_nodes_in_group("pools"):
		for target in targets:
			if not _gone(target) and pool.touches(target):
				pool.mark(target)
				_damage(target, Vector2(target.position.x, World.GROUND_Y - 15), "poison", 1)

	# Swoop onto a sheep or a guard to eat it.
	for target in targets:
		var edible: bool = target.get_script() == Sheep or target.get_script() == Archer
		if edible and not _gone(target) and target.position.distance_to(dragon.position) < EAT_DISTANCE:
			_eat(target)

	if dragon.invulnerable > 0.0:
		return
	for arrow in arrows:
		if not _gone(arrow) and arrow.position.distance_to(dragon.position) < 30.0 + 12.0 * arrow.scale.x:
			arrow.queue_free()
			_hurt_dragon()
			return
	if _boss_alive() and boss.contains(dragon.position):
		_hurt_dragon()


func _gone(node: Node) -> bool:
	return node.is_queued_for_deletion() or not (node.is_in_group("targets") or node.is_in_group("arrows"))


func _damage(target: Node2D, at: Vector2, breath: String, damage: int) -> void:
	if breath == "ice" and target.has_method("freeze"):
		target.freeze(FREEZE_SECONDS)
	if target.take_hit(at, damage, breath):
		_destroyed(target, at, breath)
	elif breath != "lightning":
		Effects.explode(at, 0.3, breath)


func _destroyed(target: Node2D, at: Vector2, breath: String) -> void:
	combo += 1
	combo_timer = COMBO_WINDOW
	var gained: int = target.points * combo
	score += gained
	Effects.text(at + Vector2(0, -30), "+%d" % gained, Color(1, 0.85, 0.3), 30 + mini(combo, 6) * 4)
	Effects.shake(4.0 + combo)
	if combo > 1:
		Sfx.play("coin", -12, 1.0 + 0.08 * mini(combo, 10))

	var kind := _kind_of(target)
	kills[kind] = kills.get(kind, 0) + 1
	if kind == "house" or kind == "tower":
		kills["building"] = kills.get("building", 0) + 1

	if target == boss:
		boss_level += 1
		next_boss_score = score + BOSS_SCORE_GAP
		hud.banner("%s DEFEATED!" % boss.title)
		Sfx.play("victory", -4)
		_slow_motion(0.3, 0.6)
	target.destroy(breath)


## Sheep are the safe snack. Guards are riskier to swoop on (they shoot back),
## so they're worth more points and refill all your energy.
func _eat(creature: Node2D) -> void:
	creature.remove_from_group("targets")
	creature.queue_free()
	var kind := _kind_of(creature)
	kills[kind] = kills.get(kind, 0) + 1
	score += creature.points
	eaten += 1
	dragon.mouth = 1.0
	Sfx.play("chomp", -2)
	if kind == "archer":
		dragon.energy = dragon.ENERGY_MAX
		Sfx.play("clank", -10, 0.8)
		var helmet := Helmet.new()
		helmet.position = dragon.to_global(dragon._mouth_pos())
		helmet.velocity = Vector2(dragon.facing * randf_range(120, 220), -320)
		world.add_child(helmet)
	else:
		dragon.energy = minf(dragon.energy + 40.0, dragon.ENERGY_MAX)
		for i in 10:
			Effects.smoke(creature.position, Vector2.from_angle(randf() * TAU) * randf_range(40, 140), 0.6, 8.0, Color.WHITE)
	if lives < MAX_LIVES:
		lives += 1
		Effects.text(creature.position + Vector2(0, -40), "+1 HEART", Color(1, 0.45, 0.55), 32)
		Sfx.play("heal", -6)
	else:
		Effects.text(creature.position + Vector2(0, -40), "CRUNCH!" if kind == "archer" else "YUM!", Color(1, 0.85, 0.3), 30)


func _hurt_dragon() -> void:
	if state != "playing":
		return
	lives -= 1
	combo = 0
	dragon.invulnerable = 1.5
	hud.flash = 1.0
	Effects.explode(dragon.position, 0.7)
	Effects.shake(18.0)
	Sfx.play("hurt", -4)

	if lives > 0:
		# A split-second freeze makes the hit land.
		_slow_motion(0.1, 0.12)
		return

	state = "dead"
	Effects.explode(dragon.position, 2.5)
	Effects.shake(30.0)
	Sfx.play("boom_big")
	dragon.queue_free()
	var new_best := Progress.record(level_index, score)
	await _slow_motion(0.3, 0.8)
	Sfx.play("gameover", -4)
	var score_line := "Score: %d%s" % [score, "   NEW BEST!" if new_best and endless else ""]
	_show_overlay("GAME OVER", Color(1, 0.5, 0.2), [score_line, "R: try again    M: menu"])


func _slow_motion(scale: float, seconds: float) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0


# --- Projectiles -----------------------------------------------------------

func _on_dragon_shoot(pos: Vector2, dir: Vector2, breath: String) -> void:
	var shot: Node2D
	match breath:
		"lightning":
			_lightning(pos, dir)
			return
		"ice":
			shot = IceShard.new()
			shot.velocity = dir * 1000.0
		"poison":
			shot = PoisonGlob.new()
			shot.velocity = dir * 620.0
			shot.splash.connect(_spawn_pool)
		_:
			shot = Fireball.new()
			shot.velocity = dir * 680.0
	shot.position = pos
	shot.add_to_group("breath")
	world.add_child(shot)


## Strikes the target nearest to where you're aiming, then jumps to nearby targets.
func _lightning(from: Vector2, dir: Vector2) -> void:
	var targets := get_tree().get_nodes_in_group("targets").filter(func(t): return not _gone(t))
	var current: Node2D = null
	var best := INF
	for target in targets:
		var to: Vector2 = target.center() - from
		var off_aim := absf(dir.angle_to(to))
		if to.length() < LIGHTNING_RANGE and off_aim < 0.45:
			var rank := to.length() * (1.0 + off_aim * 3.0)  # prefer close and on-target
			if rank < best:
				best = rank
				current = target
	Effects.shake(5.0)
	if current == null:
		Effects.bolt(from, from + dir * 450.0)
		return

	var point := from
	var struck: Array[Node2D] = []
	for i in LIGHTNING_CHAINS:
		var hit_at: Vector2 = current.center()
		Effects.bolt(point, hit_at)
		struck.append(current)
		_damage(current, hit_at, "lightning", 2)
		point = hit_at
		# Jump to the closest target not struck yet.
		var next: Node2D = null
		var nearest := LIGHTNING_CHAIN_RANGE
		for target in targets:
			if target in struck or _gone(target):
				continue
			var d: float = target.center().distance_to(point)
			if d < nearest:
				nearest = d
				next = target
		if next == null:
			return
		current = next


func _spawn_pool(x: float) -> void:
	var pool := PoisonPool.new()
	pool.position = Vector2(x, World.GROUND_Y)
	pool.add_to_group("pools")
	world.add_child(pool)


func _on_shoot_arrow(pos: Vector2, vel: Vector2, big: bool) -> void:
	if state == "dead":
		return
	var arrow := Arrow.new()
	arrow.position = pos
	arrow.velocity = vel
	arrow.big = big
	arrow.add_to_group("arrows")
	world.add_child(arrow)
