extends SceneTree

func _init():
	print("\n=== Testing Sprite Asset Loading ===\n")

	var all_passed := true

	# Test shoe icons
	var shoe_paths := [
		"res://assets/sprites/shoes/barefoot.png",
		"res://assets/sprites/shoes/flip_flops.png",
		"res://assets/sprites/shoes/running_shoes.png",
		"res://assets/sprites/shoes/winged_shoes.png"
	]

	print("Shoe Icons:")
	for path in shoe_paths:
		var tex = load(path)
		if tex:
			print("  ✓ %s (%dx%d)" % [path.get_file(), tex.get_width(), tex.get_height()])
		else:
			print("  ✗ FAILED: %s" % path)
			all_passed = false

	# Test world icons
	var world_paths := [
		"res://assets/sprites/worlds/world_road.png",
		"res://assets/sprites/worlds/world_soccer.png",
		"res://assets/sprites/worlds/world_beach.png",
		"res://assets/sprites/worlds/world_underwater.png",
		"res://assets/sprites/worlds/world_volcano.png"
	]

	print("\nWorld Icons:")
	for path in world_paths:
		var tex = load(path)
		if tex:
			print("  ✓ %s (%dx%d)" % [path.get_file(), tex.get_width(), tex.get_height()])
		else:
			print("  ✗ FAILED: %s" % path)
			all_passed = false

	# Test UI icons
	var ui_paths := [
		"res://assets/sprites/ui/coin.png",
		"res://assets/sprites/ui/star_filled.png",
		"res://assets/sprites/ui/star_empty.png",
		"res://assets/sprites/ui/pause.png",
		"res://assets/sprites/ui/settings.png"
	]

	print("\nUI Icons:")
	for path in ui_paths:
		var tex = load(path)
		if tex:
			print("  ✓ %s (%dx%d)" % [path.get_file(), tex.get_width(), tex.get_height()])
		else:
			print("  ✗ FAILED: %s" % path)
			all_passed = false

	# Test obstacle sprites (sample)
	var obstacle_paths := [
		"res://assets/sprites/obstacles/road/cone.png",
		"res://assets/sprites/obstacles/soccer/soccer_ball.png",
		"res://assets/sprites/obstacles/beach/crab.png",
		"res://assets/sprites/obstacles/underwater/jellyfish.png",
		"res://assets/sprites/obstacles/volcano/meteor.png"
	]

	print("\nObstacle Sprites (sample):")
	for path in obstacle_paths:
		var tex = load(path)
		if tex:
			print("  ✓ %s (%dx%d)" % [path.get_file(), tex.get_width(), tex.get_height()])
		else:
			print("  ✗ FAILED: %s" % path)
			all_passed = false

	# Test app icon
	print("\nApp Icon:")
	var icon = load("res://assets/icon.png")
	if icon:
		print("  ✓ icon.png (%dx%d)" % [icon.get_width(), icon.get_height()])
	else:
		print("  ✗ FAILED: icon.png")
		all_passed = false

	print("\n=== Test Complete ===")
	if all_passed:
		print("All sprites loaded successfully!")
	else:
		print("Some sprites failed to load!")

	quit()
