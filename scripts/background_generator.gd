## BackgroundGenerator
## Generates themed background decorations for each world.
## Extracted from game.gd to improve code organization.
class_name BackgroundGenerator
extends RefCounted

# =============================================================================
# CONSTANTS
# =============================================================================

const CIRCLE_SEGMENTS: int = 16

const BACKGROUND_IMAGES: Array[String] = [
	"res://assets/backgrounds/city.png",        # World 0: Road
	"res://assets/backgrounds/soccer_field.png", # World 1: Soccer
	"res://assets/backgrounds/beach.png",         # World 2: Beach
	"res://assets/backgrounds/underwater.png",   # World 3: Underwater
	"res://assets/backgrounds/volcano.png"       # World 4: Volcano
]

# =============================================================================
# PRIVATE STATE
# =============================================================================

var _parent: Node2D

# =============================================================================
# PUBLIC API
# =============================================================================

func _init(parent: Node2D) -> void:
	_parent = parent


## Creates background decorations for the specified world.
func create_background(world_index: int, world_data: Dictionary) -> void:
	# Try to load background image first
	if world_index < BACKGROUND_IMAGES.size() and ResourceLoader.exists(BACKGROUND_IMAGES[world_index]):
		var bg_texture: Texture2D = load(BACKGROUND_IMAGES[world_index])
		if bg_texture:
			var bg_sprite := Sprite2D.new()
			bg_sprite.texture = bg_texture
			bg_sprite.z_index = -100
			# Center the background and scale to fit screen
			bg_sprite.position = Vector2(240, 400)  # Center of 480x800 screen
			# Scale to cover the screen
			var scale_x: float = 480.0 / bg_texture.get_width()
			var scale_y: float = 800.0 / bg_texture.get_height()
			var scale_factor: float = max(scale_x, scale_y)
			bg_sprite.scale = Vector2(scale_factor, scale_factor)
			_parent.add_child(bg_sprite)
			return  # Use image background, skip procedural

	# Fallback to procedural backgrounds
	_create_sky_gradient(world_data)

	match world_index:
		0: _create_road_background()
		1: _create_soccer_background()
		2: _create_beach_background()
		3: _create_underwater_background()
		4: _create_volcano_background()


## Creates tiled ground sprites for the specified world.
func create_tiled_ground(world_index: int, ground_y: float) -> void:
	var ground_texture_path: String
	match world_index:
		0: ground_texture_path = "res://assets/kenney/ground/grassMid.png"
		1: ground_texture_path = "res://assets/kenney/ground/grassMid.png"
		2: ground_texture_path = "res://assets/kenney/ground/sandMid.png"
		3: ground_texture_path = "res://assets/kenney/ground/stoneMid.png"
		4: ground_texture_path = "res://assets/kenney/ground/dirtMid.png"
		_: ground_texture_path = "res://assets/kenney/ground/grassMid.png"

	if not ResourceLoader.exists(ground_texture_path):
		push_warning("[BackgroundGenerator] Ground texture not found: %s" % ground_texture_path)
		return
	var ground_tex: Texture2D = load(ground_texture_path)
	if not ground_tex:
		return

	var tex_width: float = ground_tex.get_width()
	var num_tiles: int = ceili(480.0 / tex_width) + 1

	for i in range(num_tiles):
		var tile := Sprite2D.new()
		tile.texture = ground_tex
		tile.position = Vector2(i * tex_width + tex_width / 2.0, ground_y + ground_tex.get_height() / 2.0)
		tile.z_index = 0
		_parent.add_child(tile)

# =============================================================================
# SKY GRADIENT
# =============================================================================

func _create_sky_gradient(world_data: Dictionary) -> void:
	var top_color: Color = world_data.get("sky_gradient_top", world_data.bg_color.darkened(0.2))
	var bottom_color: Color = world_data.get("sky_gradient_bottom", world_data.bg_color)

	var gradient := Gradient.new()
	gradient.set_color(0, top_color)
	gradient.set_color(1, bottom_color)

	var gradient_tex := GradientTexture2D.new()
	gradient_tex.gradient = gradient
	gradient_tex.width = 1
	gradient_tex.height = 256
	gradient_tex.fill_from = Vector2(0, 0)
	gradient_tex.fill_to = Vector2(0, 1)

	var tex_rect := TextureRect.new()
	tex_rect.texture = gradient_tex
	tex_rect.position = Vector2.ZERO
	tex_rect.size = Vector2(480, 670)
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.z_index = -10
	_parent.add_child(tex_rect)

# =============================================================================
# ROAD WORLD BACKGROUND
# =============================================================================

func _create_road_background() -> void:
	# Distant mountains/hills
	_add_polygon([
		Vector2(0, 350), Vector2(80, 280), Vector2(150, 320), Vector2(220, 260),
		Vector2(300, 300), Vector2(380, 240), Vector2(480, 290), Vector2(480, 400), Vector2(0, 400)
	], Color(0.35, 0.4, 0.5, 0.6), -9)

	# City skyline - back layer
	_create_city_skyline(380, 0.3, Color(0.3, 0.35, 0.45, 0.7))

	# City skyline - front layer
	_create_city_skyline(450, 0.5, Color(0.25, 0.28, 0.38, 0.85))

	# Clouds
	_add_layered_cloud(60, 90, 1.0)
	_add_layered_cloud(280, 60, 0.7)
	_add_layered_cloud(420, 110, 0.85)

	# Street lamps
	_add_street_lamp(80)
	_add_street_lamp(280)
	_add_street_lamp(440)

	# Road markings
	_add_road_markings()

	# Sidewalk
	_add_polygon([
		Vector2(0, 655), Vector2(480, 655), Vector2(480, 670), Vector2(0, 670)
	], Color(0.5, 0.48, 0.45, 0.8), -1)


func _create_city_skyline(base_y: float, alpha: float, color: Color) -> void:
	var x: float = 0
	while x < 500:
		var width: float = randf_range(40, 80)
		var height: float = randf_range(80, 200)
		var building_y: float = base_y - height

		_add_polygon([
			Vector2(x, building_y), Vector2(x + width, building_y),
			Vector2(x + width, base_y), Vector2(x, base_y)
		], color, -8)

		var win_color := Color(0.95, 0.9, 0.6, alpha * 0.7)
		var rows: int = int(height / 25)
		var cols: int = int(width / 18)
		for row in range(rows):
			for col in range(cols):
				if randf() > 0.3:
					var wx: float = x + 6 + col * 16
					var wy: float = building_y + 10 + row * 22
					_add_polygon([
						Vector2(wx, wy), Vector2(wx + 10, wy),
						Vector2(wx + 10, wy + 14), Vector2(wx, wy + 14)
					], win_color, -7)

		x += width + randf_range(5, 20)


func _add_street_lamp(x: float) -> void:
	_add_polygon([
		Vector2(x - 3, 500), Vector2(x + 3, 500),
		Vector2(x + 2, 650), Vector2(x - 2, 650)
	], Color(0.25, 0.25, 0.28), -2)

	_add_polygon([
		Vector2(x - 12, 495), Vector2(x + 12, 495),
		Vector2(x + 8, 510), Vector2(x - 8, 510)
	], Color(0.3, 0.3, 0.32), -2)

	_add_circle(x, 502, 20, Color(1, 0.95, 0.7, 0.15), -3)


func _add_road_markings() -> void:
	for i in range(10):
		_add_polygon([
			Vector2(i * 55, 657), Vector2(i * 55 + 35, 657),
			Vector2(i * 55 + 35, 661), Vector2(i * 55, 661)
		], Color(1, 1, 1, 0.6), -1)

# =============================================================================
# SOCCER WORLD BACKGROUND
# =============================================================================

func _create_soccer_background() -> void:
	_add_polygon([
		Vector2(0, 150), Vector2(480, 150), Vector2(480, 300), Vector2(0, 300)
	], Color(0.35, 0.35, 0.4, 0.5), -9)

	_add_polygon([
		Vector2(0, 280), Vector2(480, 280), Vector2(480, 450), Vector2(0, 450)
	], Color(0.4, 0.4, 0.45, 0.6), -8)

	_create_crowd()

	_add_stadium_light(60, 100)
	_add_stadium_light(420, 100)

	_add_goal_net(380)
	_add_field_markings()

	_add_layered_cloud(150, 50, 0.6)
	_add_layered_cloud(350, 70, 0.5)


func _create_crowd() -> void:
	var crowd_colors := [
		Color(0.9, 0.2, 0.2, 0.6), Color(0.2, 0.4, 0.9, 0.6),
		Color(1, 0.9, 0.2, 0.6), Color(0.2, 0.8, 0.3, 0.6),
		Color(1, 1, 1, 0.5)
	]
	for i in range(80):
		var x: float = randf_range(10, 470)
		var y: float = randf_range(160, 420)
		_add_circle(x, y, randf_range(3, 6), crowd_colors[randi() % crowd_colors.size()], -7)


func _add_stadium_light(x: float, y: float) -> void:
	_add_polygon([
		Vector2(x - 8, y), Vector2(x + 8, y),
		Vector2(x + 4, y + 200), Vector2(x - 4, y + 200)
	], Color(0.4, 0.4, 0.42), -6)

	_add_polygon([
		Vector2(x - 25, y - 10), Vector2(x + 25, y - 10),
		Vector2(x + 20, y + 15), Vector2(x - 20, y + 15)
	], Color(0.5, 0.5, 0.52), -6)

	_add_circle(x, y, 35, Color(1, 1, 0.9, 0.12), -5)


func _add_goal_net(x: float) -> void:
	_add_polygon([
		Vector2(x, 520), Vector2(x + 6, 520), Vector2(x + 6, 650), Vector2(x, 650)
	], Color(1, 1, 1, 0.8), -2)
	_add_polygon([
		Vector2(x + 80, 520), Vector2(x + 86, 520), Vector2(x + 86, 650), Vector2(x, 650)
	], Color(1, 1, 1, 0.8), -2)

	_add_polygon([
		Vector2(x, 515), Vector2(x + 86, 515), Vector2(x + 86, 522), Vector2(x, 522)
	], Color(1, 1, 1, 0.8), -2)

	for i in range(8):
		_add_polygon([
			Vector2(x + 8 + i * 10, 522), Vector2(x + 10 + i * 10, 522),
			Vector2(x + 10 + i * 10, 650), Vector2(x + 8 + i * 10, 650)
		], Color(1, 1, 1, 0.2), -3)


func _add_field_markings() -> void:
	_add_polygon([
		Vector2(238, 550), Vector2(242, 550), Vector2(242, 670), Vector2(238, 670)
	], Color(1, 1, 1, 0.4), -1)

	_add_circle_outline(240, 620, 50, Color(1, 1, 1, 0.4), -1)

	_add_polygon([
		Vector2(0, 580), Vector2(100, 580), Vector2(100, 584), Vector2(0, 584)
	], Color(1, 1, 1, 0.3), -1)

# =============================================================================
# BEACH WORLD BACKGROUND
# =============================================================================

func _create_beach_background() -> void:
	# Sun with glow layers
	_add_circle(400, 100, 60, Color(1, 0.98, 0.8, 0.15), -10)
	_add_circle(400, 100, 45, Color(1, 0.95, 0.6, 0.3), -9)
	_add_circle(400, 100, 32, Color(1, 0.9, 0.4, 0.9), -8)

	# Ocean layers
	_add_polygon([
		Vector2(0, 380), Vector2(480, 380), Vector2(480, 550), Vector2(0, 550)
	], Color(0.15, 0.45, 0.65, 0.7), -7)

	_add_polygon([
		Vector2(0, 420), Vector2(480, 420), Vector2(480, 550), Vector2(0, 550)
	], Color(0.12, 0.4, 0.6, 0.6), -6)

	_create_ocean_waves()

	_add_detailed_palm(40, 450)
	_add_detailed_palm(430, 480)

	_add_beach_umbrella(150, 520, Color(1, 0.3, 0.3))
	_add_beach_umbrella(320, 540, Color(0.3, 0.5, 1))

	_add_layered_cloud(100, 80, 0.9)
	_add_layered_cloud(250, 60, 0.7)

	_add_seagull(180, 150)
	_add_seagull(300, 120)
	_add_seagull(220, 180)


func _create_ocean_waves() -> void:
	for wave in range(4):
		var y: float = 450 + wave * 30
		var points: PackedVector2Array = []
		for i in range(25):
			var x: float = i * 20
			var wave_y: float = y + sin(i * 0.8 + wave) * 8
			points.append(Vector2(x, wave_y))
		points.append(Vector2(480, y + 40))
		points.append(Vector2(0, y + 40))
		_add_polygon(points, Color(1, 1, 1, 0.15 - wave * 0.03), -5 + wave)


func _add_detailed_palm(x: float, y: float) -> void:
	for i in range(6):
		var seg_y: float = y + i * 25
		var width: float = 14 - i * 1.5
		_add_polygon([
			Vector2(x - width/2, seg_y), Vector2(x + width/2, seg_y),
			Vector2(x + width/2 - 1, seg_y + 28), Vector2(x - width/2 + 1, seg_y + 28)
		], Color(0.55 - i * 0.03, 0.35 - i * 0.02, 0.2), -4)

	var frond_angles := [-1.2, -0.7, -0.2, 0.3, 0.8, 1.3]
	for angle in frond_angles:
		_add_palm_frond(x, y - 10, angle)


func _add_palm_frond(x: float, y: float, angle: float) -> void:
	var frond := Polygon2D.new()
	var points: PackedVector2Array = [Vector2(0, 0)]
	for i in range(12):
		var t: float = i / 11.0
		var fx: float = t * 80
		var fy: float = -sin(t * PI) * 15 + t * 20
		points.append(Vector2(fx, fy))
	for i in range(11, -1, -1):
		var t: float = i / 11.0
		var fx: float = t * 80
		var fy: float = -sin(t * PI) * 15 + t * 20 + 6
		points.append(Vector2(fx, fy))
	frond.polygon = points
	frond.color = Color(0.2, 0.55, 0.25, 0.9)
	frond.position = Vector2(x, y)
	frond.rotation = angle
	frond.z_index = -3
	_parent.add_child(frond)


func _add_beach_umbrella(x: float, y: float, color: Color) -> void:
	_add_polygon([
		Vector2(x - 2, y), Vector2(x + 2, y),
		Vector2(x + 2, y + 60), Vector2(x - 2, y + 60)
	], Color(0.6, 0.5, 0.4), -4)

	_add_polygon([
		Vector2(x - 35, y + 5), Vector2(x + 35, y + 5),
		Vector2(x + 25, y - 20), Vector2(x - 25, y - 20)
	], color.darkened(0.1), -3)
	_add_polygon([
		Vector2(x - 30, y), Vector2(x + 30, y),
		Vector2(x + 20, y - 25), Vector2(x - 20, y - 25)
	], color, -2)


func _add_seagull(x: float, y: float) -> void:
	_add_polygon([
		Vector2(x - 12, y), Vector2(x - 4, y - 6), Vector2(x, y),
		Vector2(x + 4, y - 6), Vector2(x + 12, y), Vector2(x, y + 2)
	], Color(0.95, 0.95, 0.95, 0.8), -4)

# =============================================================================
# UNDERWATER WORLD BACKGROUND
# =============================================================================

func _create_underwater_background() -> void:
	_create_light_shafts()

	_add_rock_formation(30, 500, 0.4)
	_add_rock_formation(400, 480, 0.5)

	for i in range(8):
		_add_bg_kelp(i * 65 + randf_range(-10, 10), 670, randf_range(150, 250))

	for i in range(15):
		var bx: float = randf_range(20, 460)
		var by: float = randf_range(100, 550)
		var size: float = randf_range(5, 18)
		_add_bubble_detailed(bx, by, size)

	_add_fish_school(100, 200, 8)
	_add_fish_school(350, 350, 6)

	_create_caustics()


func _create_light_shafts() -> void:
	for i in range(5):
		var x: float = 50 + i * 100 + randf_range(-30, 30)
		var width_top: float = randf_range(30, 50)
		var width_bottom: float = width_top + randf_range(40, 80)
		_add_polygon([
			Vector2(x - width_top/2, 0), Vector2(x + width_top/2, 0),
			Vector2(x + width_bottom/2, 670), Vector2(x - width_bottom/2, 670)
		], Color(0.4, 0.7, 0.9, 0.06), -8)


func _add_rock_formation(x: float, y: float, alpha: float) -> void:
	_add_polygon([
		Vector2(x, y), Vector2(x + 30, y - 80), Vector2(x + 50, y - 60),
		Vector2(x + 70, y - 100), Vector2(x + 100, y - 50),
		Vector2(x + 120, y), Vector2(x + 120, y + 200), Vector2(x, y + 200)
	], Color(0.15, 0.2, 0.3, alpha), -7)


func _add_bg_kelp(x: float, y: float, height: float) -> void:
	var points: PackedVector2Array = []
	for i in range(12):
		var t: float = i / 11.0
		var kx: float = sin(t * 3 + x * 0.01) * 15
		points.append(Vector2(x + kx - 4, y - t * height))
	for i in range(11, -1, -1):
		var t: float = i / 11.0
		var kx: float = sin(t * 3 + x * 0.01) * 15
		points.append(Vector2(x + kx + 4, y - t * height))
	_add_polygon(points, Color(0.1, 0.35, 0.2, 0.5), -5)


func _add_bubble_detailed(x: float, y: float, radius: float) -> void:
	_add_circle(x, y, radius, Color(0.6, 0.85, 1, 0.2), -4)
	_add_circle(x - radius * 0.3, y - radius * 0.3, radius * 0.25, Color(1, 1, 1, 0.4), -3)


func _add_fish_school(x: float, y: float, count: int) -> void:
	for i in range(count):
		var fx: float = x + randf_range(-40, 40)
		var fy: float = y + randf_range(-25, 25)
		_add_polygon([
			Vector2(fx - 8, fy), Vector2(fx + 5, fy - 3),
			Vector2(fx + 5, fy + 3)
		], Color(0.5, 0.6, 0.8, 0.4), -4)


func _create_caustics() -> void:
	for i in range(6):
		var x: float = randf_range(50, 430)
		var y: float = randf_range(600, 660)
		_add_circle(x, y, randf_range(20, 40), Color(0.5, 0.8, 1, 0.08), -2)

# =============================================================================
# VOLCANO WORLD BACKGROUND
# =============================================================================

func _create_volcano_background() -> void:
	_add_polygon([
		Vector2(0, 400), Vector2(100, 200), Vector2(180, 280),
		Vector2(250, 120), Vector2(320, 200), Vector2(400, 150),
		Vector2(480, 300), Vector2(480, 670), Vector2(0, 670)
	], Color(0.08, 0.04, 0.02, 0.8), -9)

	_create_lava_glow()
	_create_volcanic_smoke()
	_create_ash_particles()
	_create_ember_field()

	_add_lava_stream(150, 400)
	_add_lava_stream(350, 450)

	_add_circle(250, 130, 50, Color(1, 0.4, 0.1, 0.2), -8)
	_add_circle(250, 130, 30, Color(1, 0.6, 0.2, 0.3), -7)


func _create_lava_glow() -> void:
	_add_polygon([
		Vector2(0, 580), Vector2(480, 580), Vector2(480, 670), Vector2(0, 670)
	], Color(1, 0.3, 0.05, 0.15), -3)
	_add_polygon([
		Vector2(0, 620), Vector2(480, 620), Vector2(480, 670), Vector2(0, 670)
	], Color(1, 0.4, 0.1, 0.2), -2)
	_add_polygon([
		Vector2(0, 650), Vector2(480, 650), Vector2(480, 670), Vector2(0, 670)
	], Color(1, 0.5, 0.15, 0.3), -1)


func _create_volcanic_smoke() -> void:
	for i in range(5):
		var x: float = randf_range(50, 430)
		var y: float = randf_range(80, 250)
		var size: float = randf_range(50, 100)
		_add_smoke_cloud(x, y, size)


func _add_smoke_cloud(x: float, y: float, size: float) -> void:
	for j in range(4):
		var ox: float = randf_range(-size * 0.3, size * 0.3)
		var oy: float = randf_range(-size * 0.3, size * 0.3)
		var r: float = size * randf_range(0.3, 0.6)
		_add_circle(x + ox, y + oy, r, Color(0.2, 0.15, 0.15, 0.4), -6)


func _create_ash_particles() -> void:
	for i in range(30):
		var x: float = randf_range(0, 480)
		var y: float = randf_range(50, 600)
		var size: float = randf_range(2, 5)
		_add_circle(x, y, size, Color(0.3, 0.25, 0.25, 0.5), -4)


func _create_ember_field() -> void:
	for i in range(20):
		var x: float = randf_range(20, 460)
		var y: float = randf_range(200, 600)
		var size: float = randf_range(3, 7)
		var brightness: float = randf_range(0.7, 1.0)
		_add_circle(x, y, size, Color(1, 0.5 * brightness, 0.1, 0.8), -3)
		_add_circle(x, y, size * 1.5, Color(1, 0.4, 0.1, 0.2), -4)


func _add_lava_stream(x: float, y: float) -> void:
	var points: PackedVector2Array = []
	for i in range(8):
		var t: float = i / 7.0
		var lx: float = x + sin(t * 2) * 20
		points.append(Vector2(lx - 8, y + t * 220))
	for i in range(7, -1, -1):
		var t: float = i / 7.0
		var lx: float = x + sin(t * 2) * 20
		points.append(Vector2(lx + 8, y + t * 220))
	_add_polygon(points, Color(1, 0.5, 0.15, 0.6), -2)

	for i in range(4):
		var gy: float = y + i * 60
		_add_circle(x + sin(i * 0.7) * 15, gy, 25, Color(1, 0.4, 0.1, 0.15), -3)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _add_polygon(points: PackedVector2Array, color: Color, z: int) -> void:
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	poly.z_index = z
	_parent.add_child(poly)


func _add_circle(x: float, y: float, radius: float, color: Color, z: int) -> void:
	var circle := Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(CIRCLE_SEGMENTS):
		var angle: float = i * TAU / CIRCLE_SEGMENTS
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	circle.polygon = points
	circle.color = color
	circle.position = Vector2(x, y)
	circle.z_index = z
	_parent.add_child(circle)


func _add_circle_outline(x: float, y: float, radius: float, color: Color, z: int) -> void:
	var segments: int = 24
	for i in range(segments):
		var angle1: float = i * TAU / segments
		var angle2: float = (i + 1) * TAU / segments
		_add_polygon([
			Vector2(x + cos(angle1) * radius, y + sin(angle1) * radius),
			Vector2(x + cos(angle2) * radius, y + sin(angle2) * radius),
			Vector2(x + cos(angle2) * (radius - 3), y + sin(angle2) * (radius - 3)),
			Vector2(x + cos(angle1) * (radius - 3), y + sin(angle1) * (radius - 3))
		], color, z)


func _add_layered_cloud(x: float, y: float, scale: float) -> void:
	var base_color := Color(1, 1, 1, 0.6 * scale)
	_add_circle(x, y, 30 * scale, base_color, -5)
	_add_circle(x - 25 * scale, y + 5, 22 * scale, base_color, -5)
	_add_circle(x + 28 * scale, y + 3, 25 * scale, base_color, -5)
	_add_circle(x + 10 * scale, y - 8, 20 * scale, base_color, -5)
	_add_circle(x - 10 * scale, y - 5, 18 * scale, base_color, -5)
