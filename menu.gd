extends Node2D
## Title screen and level select. The dragon is flyable here too, just for fun.

const Background = preload("res://background.gd")
const Dragon = preload("res://dragon.gd")
const Fireball = preload("res://fireball.gd")

const GOLD := Color(1, 0.8, 0.3)


func _ready() -> void:
	Engine.time_scale = 1.0
	Effects.clear()

	var background := Background.new()
	background.theme = Themes.ALL.sunset
	add_child(background)

	var dragon := Dragon.new()
	dragon.position = Vector2(180, 560)
	dragon.scale = Vector2(1.3, 1.3)
	dragon.unlocked = 1
	dragon.shoot.connect(_on_dragon_shoot)
	add_child(dragon)
	background.dragon = dragon

	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.size = Vector2(World.WIDTH, World.HEIGHT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	ui.add_child(_label("DRAGON GAME", 88, GOLD, 40))
	ui.add_child(_label("Choose a level", 26, Color.WHITE, 150))

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.position = Vector2((World.WIDTH - (5 * 200 + 4 * 16)) / 2.0, 200)
	ui.add_child(grid)
	for i in Levels.LIST.size():
		var unlocked := i < Progress.unlocked
		var text := "%d\n%s" % [i + 1, Levels.LIST[i].name]
		if not unlocked:
			text = "%d\nLocked" % (i + 1)
		elif Progress.best(i) > 0:
			text += "\nBest: %d" % Progress.best(i)
		var button := _button(text, Vector2(200, 110), not unlocked)
		button.pressed.connect(_play.bind(i))
		grid.add_child(button)

	var endless := _button("ENDLESS\nBest: %d" % Progress.best(-1), Vector2(300, 80), false)
	endless.position = Vector2((World.WIDTH - 300) / 2.0, 470)
	endless.pressed.connect(_play.bind(-1))
	ui.add_child(endless)

	var next := mini(Progress.unlocked, Levels.LIST.size())
	ui.add_child(_label("Press Enter to play level %d    ·    Progress saves automatically" % next, 18, Color(1, 1, 1, 0.8), 676))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_KP_ENTER):
		_play(mini(Progress.unlocked, Levels.LIST.size()) - 1)


func _play(level: int) -> void:
	Progress.current = level
	get_tree().change_scene_to_file("res://main.tscn")


func _on_dragon_shoot(pos: Vector2, dir: Vector2, _breath: String) -> void:
	var fireball := Fireball.new()
	fireball.position = pos
	fireball.velocity = dir * 680.0
	add_child(fireball)


func _label(text: String, font_size: int, color: Color, y: float) -> Label:
	var label := Label.new()
	label.text = text
	label.size = Vector2(World.WIDTH, font_size * 1.4)
	label.position = Vector2(0, y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", maxi(font_size / 6, 6))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, button_size: Vector2, disabled: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = button_size
	button.size = button_size
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	button.add_theme_stylebox_override("normal", _box(Color(0.12, 0.07, 0.16, 0.85), GOLD.darkened(0.3)))
	button.add_theme_stylebox_override("hover", _box(Color(0.25, 0.12, 0.2, 0.92), GOLD))
	button.add_theme_stylebox_override("pressed", _box(Color(0.4, 0.18, 0.12, 0.95), GOLD))
	button.add_theme_stylebox_override("disabled", _box(Color(0.08, 0.06, 0.1, 0.6), Color(0.4, 0.4, 0.45, 0.5)))
	return button


func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(14)
	return box
