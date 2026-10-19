class_name Levels
## The campaign. Each level sets the scenery, which breaths you have, what spawns,
## and the goals you need to complete.
##
## Spawning:
##   spawn_every      [min, max] seconds between sheep/archers
##   archer_chance    how many of those are archers (0..1)
##   structures       kinds to pick from (repeat a kind to make it more likely)
##   structure_every  [min, max] seconds between buildings; first_structure, max_structures
##   boss_at          seconds into the level the boss shows up (-1 = never)
## Goals (all must be met):
##   {type = "score", count}                  reach a score
##   {type = "kill", what, count}             what = sheep, archer, house, tower, building, boss
##   {type = "eat", count}                    eat sheep
##   {type = "survive", seconds}              stay alive

const LIST := [
	{
		name = "First Flight", theme = "day", breaths = 1,
		hint = "Burn the sheep! Or swoop down onto them to eat them.",
		spawn_every = [0.9, 1.6], archer_chance = 0.0,
		goals = [{type = "score", count = 15}],
	},
	{
		name = "Arrows Incoming", theme = "day", breaths = 1,
		hint = "Archers shoot back. Burn their arrows out of the sky!",
		spawn_every = [0.9, 1.5], archer_chance = 0.45,
		goals = [{type = "kill", what = "archer", count = 6}],
	},
	{
		name = "The Village", theme = "morning", breaths = 2,
		hint = "Houses take several hits.",
		spawn_every = [1.0, 1.7], archer_chance = 0.25,
		structures = ["house"], structure_every = [6.0, 10.0], first_structure = 2.0, max_structures = 2,
		goals = [{type = "kill", what = "house", count = 3}],
	},
	{
		name = "Watchtowers", theme = "sunset", breaths = 2,
		hint = "Ice stops tower archers from shooting.",
		spawn_every = [0.9, 1.5], archer_chance = 0.35,
		structures = ["tower", "tower", "house"], structure_every = [7.0, 11.0], first_structure = 2.0, max_structures = 2,
		goals = [{type = "kill", what = "tower", count = 2}, {type = "score", count = 100}],
	},
	{
		name = "The Griffin Knight", theme = "sunset", breaths = 3,
		hint = "Watch for the glint of its lance before it charges!",
		spawn_every = [1.0, 1.8], archer_chance = 0.3,
		structures = ["house"], structure_every = [12.0, 18.0], first_structure = 6.0, max_structures = 1,
		boss_at = 8.0, boss_level = 0,
		goals = [{type = "kill", what = "boss", count = 1}],
	},
	{
		name = "Night Raid", theme = "night", breaths = 3,
		hint = "Lightning jumps between targets that are close together.",
		spawn_every = [0.9, 1.5], archer_chance = 0.4,
		structures = ["house", "house", "tower"], structure_every = [6.0, 10.0], first_structure = 1.5, max_structures = 3,
		goals = [{type = "kill", what = "building", count = 6}],
	},
	{
		name = "Winter's Bite", theme = "winter", breaths = 4,
		hint = "Just stay alive. Poison puddles guard the ground for you.",
		spawn_every = [0.6, 1.1], archer_chance = 0.6,
		structures = ["tower"], structure_every = [12.0, 16.0], first_structure = 5.0, max_structures = 2,
		goals = [{type = "survive", seconds = 75}],
	},
	{
		name = "Famine", theme = "winter", breaths = 4, start_lives = 1,
		hint = "You're starving, down to one heart. Eat sheep, or guards if you dare!",
		spawn_every = [0.7, 1.3], archer_chance = 0.45,
		goals = [{type = "eat", count = 8}],
	},
	{
		name = "Siege", theme = "night", breaths = 4,
		hint = "Topple the towers. Their champion will come for you.",
		spawn_every = [0.8, 1.4], archer_chance = 0.45,
		structures = ["tower", "tower", "house"], structure_every = [6.0, 9.0], first_structure = 1.5, max_structures = 3,
		boss_at = 40.0, boss_level = 1,
		goals = [{type = "kill", what = "tower", count = 4}, {type = "kill", what = "boss", count = 1}],
	},
	{
		name = "Dragonfire", theme = "volcano", breaths = 4,
		hint = "The Griffin King himself. End this.",
		spawn_every = [0.7, 1.3], archer_chance = 0.5,
		structures = ["tower"], structure_every = [10.0, 14.0], first_structure = 3.0, max_structures = 2,
		boss_at = 4.0, boss_level = 2, boss_title = "GRIFFIN KING",
		goals = [{type = "kill", what = "boss", count = 1}],
	},
]

## No goals: survive as long as you can while it keeps getting harder.
const ENDLESS := {
	name = "Endless", theme = "sunset", breaths = 4, endless = true,
	hint = "How long can you last?",
	spawn_every = [0.8, 1.6], archer_chance = 0.2,
	structures = ["house", "house", "tower"], structure_every = [12.0, 20.0], first_structure = 6.0, max_structures = 2,
	goals = [],
}


## Level by index; -1 is endless mode.
static func get_level(index: int) -> Dictionary:
	return ENDLESS if index < 0 else LIST[index]
