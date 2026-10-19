class_name Breaths
## The dragon's breath types. Switch with 1-4, Q/E or the mouse wheel.
## `cost` is energy per shot; `color` tints the dragon's spines, horns and mouth glow.

const LIST := [
	{id = "fire", name = "FIRE", cost = 7.0, cooldown = 0.15, sound = "fire", volume = -12.0,
		color = Color(0.95, 0.55, 0.2), puff = Color(0.3, 0.27, 0.27)},
	{id = "ice", name = "ICE", cost = 9.0, cooldown = 0.2, sound = "freeze", volume = -10.0,
		color = Color(0.5, 0.85, 1.0), puff = Color(0.85, 0.95, 1.0)},
	{id = "lightning", name = "LIGHTNING", cost = 22.0, cooldown = 0.45, sound = "zap", volume = -6.0,
		color = Color(1.0, 0.92, 0.35), puff = Color(0.75, 0.7, 1.0)},
	{id = "poison", name = "POISON", cost = 14.0, cooldown = 0.35, sound = "glob", volume = -8.0,
		color = Color(0.55, 0.95, 0.3), puff = Color(0.45, 0.6, 0.35)},
]
