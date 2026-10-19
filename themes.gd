class_name Themes
## Color schemes and weather for the background. Each level picks one by name.

const ALL := {
	day = {
		sky_top = Color(0.22, 0.42, 0.78), sky_mid = Color(0.55, 0.75, 0.95), horizon = Color(1.0, 0.8, 0.6),
		sun = Color(1, 0.96, 0.8), sun_glow = Color(1, 0.9, 0.6), sun_pos = Vector2(980, 170), sun_size = 48.0,
		mountains = Color(0.62, 0.55, 0.72), hills = Color(0.42, 0.62, 0.55), trees = Color(0.16, 0.4, 0.3),
		ground_top = Color(0.42, 0.7, 0.3), ground_bottom = Color(0.24, 0.48, 0.2), grass = Color(0.3, 0.55, 0.22),
		cloud = Color(1, 1, 1, 0.95), cloud_shade = Color(0.85, 0.8, 0.92, 0.9),
	},
	morning = {
		sky_top = Color(0.42, 0.55, 0.85), sky_mid = Color(0.85, 0.75, 0.88), horizon = Color(1.0, 0.75, 0.6),
		sun = Color(1, 0.92, 0.75), sun_glow = Color(1, 0.8, 0.65), sun_pos = Vector2(260, 330), sun_size = 54.0,
		mountains = Color(0.72, 0.62, 0.78), hills = Color(0.52, 0.66, 0.6), trees = Color(0.2, 0.42, 0.34),
		ground_top = Color(0.48, 0.72, 0.36), ground_bottom = Color(0.28, 0.5, 0.24), grass = Color(0.34, 0.58, 0.26),
		cloud = Color(1, 0.95, 0.95, 0.95), cloud_shade = Color(0.95, 0.78, 0.82, 0.9),
	},
	sunset = {
		sky_top = Color(0.25, 0.2, 0.5), sky_mid = Color(0.85, 0.45, 0.45), horizon = Color(1.0, 0.65, 0.3),
		sun = Color(1, 0.7, 0.35), sun_glow = Color(1, 0.5, 0.3), sun_pos = Vector2(900, 430), sun_size = 70.0,
		mountains = Color(0.45, 0.3, 0.45), hills = Color(0.33, 0.32, 0.4), trees = Color(0.15, 0.18, 0.22),
		ground_top = Color(0.36, 0.5, 0.26), ground_bottom = Color(0.2, 0.32, 0.15), grass = Color(0.26, 0.4, 0.2),
		cloud = Color(1, 0.78, 0.72, 0.95), cloud_shade = Color(0.75, 0.5, 0.6, 0.9),
	},
	night = {
		sky_top = Color(0.03, 0.05, 0.15), sky_mid = Color(0.08, 0.12, 0.3), horizon = Color(0.22, 0.22, 0.42),
		sun = Color(0.95, 0.95, 0.85), sun_glow = Color(0.6, 0.65, 0.9), sun_pos = Vector2(1000, 140), sun_size = 38.0,
		mountains = Color(0.12, 0.14, 0.26), hills = Color(0.1, 0.17, 0.2), trees = Color(0.05, 0.12, 0.12),
		ground_top = Color(0.13, 0.26, 0.16), ground_bottom = Color(0.06, 0.14, 0.08), grass = Color(0.1, 0.22, 0.12),
		cloud = Color(0.3, 0.32, 0.45, 0.8), cloud_shade = Color(0.18, 0.2, 0.32, 0.8),
		moon = true, stars = true, no_flowers = true,
	},
	winter = {
		sky_top = Color(0.5, 0.62, 0.8), sky_mid = Color(0.75, 0.82, 0.9), horizon = Color(0.93, 0.93, 0.96),
		sun = Color(1, 1, 0.95), sun_glow = Color(0.95, 0.95, 1.0), sun_pos = Vector2(300, 150), sun_size = 40.0,
		mountains = Color(0.62, 0.68, 0.8), hills = Color(0.8, 0.85, 0.92), trees = Color(0.2, 0.36, 0.36),
		ground_top = Color(0.96, 0.97, 1.0), ground_bottom = Color(0.78, 0.84, 0.92), grass = Color(0.55, 0.65, 0.62),
		cloud = Color(1, 1, 1, 0.95), cloud_shade = Color(0.8, 0.84, 0.92, 0.9),
		snow = true, snowcaps = true, no_flowers = true,
	},
	volcano = {
		sky_top = Color(0.12, 0.03, 0.05), sky_mid = Color(0.45, 0.1, 0.06), horizon = Color(1.0, 0.42, 0.1),
		sun = Color(0.95, 0.35, 0.15), sun_glow = Color(1, 0.3, 0.1), sun_pos = Vector2(640, 380), sun_size = 90.0,
		mountains = Color(0.18, 0.07, 0.08), hills = Color(0.24, 0.11, 0.09), trees = Color(0.12, 0.07, 0.06),
		ground_top = Color(0.32, 0.2, 0.14), ground_bottom = Color(0.14, 0.09, 0.07), grass = Color(0.42, 0.26, 0.14),
		cloud = Color(0.35, 0.24, 0.24, 0.85), cloud_shade = Color(0.2, 0.12, 0.12, 0.85),
		embers = true, lava = true, no_flowers = true,
	},
}
