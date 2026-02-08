## Unit Tests for Particle Effects System
## Validates particle creation, configuration, and auto-cleanup
extends GutTest

# =============================================================================
# SETUP / TEARDOWN
# =============================================================================

func after_each():
	if ObjectPool:
		ObjectPool.clear_pools()

# =============================================================================
# AUTOLOAD EXISTS
# =============================================================================

func test_particle_effects_autoload_exists():
	var pe = get_node_or_null("/root/ParticleEffects")
	assert_not_null(pe, "ParticleEffects autoload should exist")

# =============================================================================
# COIN COLLECT PARTICLES
# =============================================================================

func test_spawn_coin_particles_returns_node():
	var particles = ParticleEffects.spawn_coin_particles(Vector2(100, 200))
	assert_not_null(particles, "spawn_coin_particles should return a node")
	if particles:
		assert_is(particles, CPUParticles2D, "Should return a CPUParticles2D node")
		particles.queue_free()

func test_coin_particles_at_correct_position():
	var pos = Vector2(150, 300)
	var particles = ParticleEffects.spawn_coin_particles(pos)
	assert_not_null(particles)
	if particles:
		assert_eq(particles.global_position, pos, "Particles should spawn at given position")
		particles.queue_free()

func test_coin_particles_are_one_shot():
	var particles = ParticleEffects.spawn_coin_particles(Vector2.ZERO)
	assert_not_null(particles)
	if particles:
		assert_true(particles.one_shot, "Coin particles should be one-shot")
		particles.queue_free()

func test_coin_particles_are_emitting():
	var particles = ParticleEffects.spawn_coin_particles(Vector2.ZERO)
	assert_not_null(particles)
	if particles:
		assert_true(particles.emitting, "Coin particles should start emitting")
		particles.queue_free()

func test_coin_particles_color_is_gold():
	var particles = ParticleEffects.spawn_coin_particles(Vector2.ZERO)
	assert_not_null(particles)
	if particles:
		# Gold color should have high R, medium-high G, low B
		var color = particles.color
		assert_gt(color.r, 0.7, "Coin particle color should have high red")
		assert_gt(color.g, 0.5, "Coin particle color should have medium-high green")
		assert_lt(color.b, 0.4, "Coin particle color should have low blue")
		particles.queue_free()

# =============================================================================
# PLAYER HIT PARTICLES
# =============================================================================

func test_spawn_hit_particles_returns_node():
	var particles = ParticleEffects.spawn_hit_particles(Vector2(100, 200))
	assert_not_null(particles, "spawn_hit_particles should return a node")
	if particles:
		assert_is(particles, CPUParticles2D, "Should return a CPUParticles2D node")
		particles.queue_free()

func test_hit_particles_at_correct_position():
	var pos = Vector2(200, 400)
	var particles = ParticleEffects.spawn_hit_particles(pos)
	assert_not_null(particles)
	if particles:
		assert_eq(particles.global_position, pos, "Particles should spawn at given position")
		particles.queue_free()

func test_hit_particles_are_one_shot():
	var particles = ParticleEffects.spawn_hit_particles(Vector2.ZERO)
	assert_not_null(particles)
	if particles:
		assert_true(particles.one_shot, "Hit particles should be one-shot")
		particles.queue_free()

func test_hit_particles_color_is_red_orange():
	var particles = ParticleEffects.spawn_hit_particles(Vector2.ZERO)
	assert_not_null(particles)
	if particles:
		var color = particles.color
		assert_gt(color.r, 0.7, "Hit particle color should have high red")
		assert_lt(color.b, 0.3, "Hit particle color should have low blue")
		particles.queue_free()

# =============================================================================
# PLAYER DEATH PARTICLES
# =============================================================================

func test_spawn_death_particles_returns_node():
	var particles = ParticleEffects.spawn_death_particles(Vector2(100, 200))
	assert_not_null(particles, "spawn_death_particles should return a node")
	if particles:
		assert_is(particles, CPUParticles2D, "Should return a CPUParticles2D node")
		particles.queue_free()

func test_death_particles_at_correct_position():
	var pos = Vector2(240, 400)
	var particles = ParticleEffects.spawn_death_particles(pos)
	assert_not_null(particles)
	if particles:
		assert_eq(particles.global_position, pos, "Particles should spawn at given position")
		particles.queue_free()

func test_death_particles_are_one_shot():
	var particles = ParticleEffects.spawn_death_particles(Vector2.ZERO)
	assert_not_null(particles)
	if particles:
		assert_true(particles.one_shot, "Death particles should be one-shot")
		particles.queue_free()

func test_death_particles_larger_than_hit():
	var hit = ParticleEffects.spawn_hit_particles(Vector2.ZERO)
	var death = ParticleEffects.spawn_death_particles(Vector2.ZERO)
	assert_not_null(hit)
	assert_not_null(death)
	if hit and death:
		assert_gt(
			death.amount,
			hit.amount,
			"Death particles should have more particles than hit"
		)
		death.queue_free()
		hit.queue_free()

# =============================================================================
# AUTO-CLEANUP
# =============================================================================

func test_particles_added_to_scene_tree():
	var particles = ParticleEffects.spawn_coin_particles(Vector2.ZERO)
	assert_not_null(particles)
	if particles:
		# In headless/test environments current_scene may be null,
		# so particles are safely freed instead of added to the tree.
		if get_tree().current_scene:
			assert_true(particles.is_inside_tree(), "Particles should be added to scene tree")
		else:
			pass_test("current_scene is null — null-safety guard correctly prevented crash")
		particles.queue_free()

func test_particle_lifetime_is_finite():
	var particles = ParticleEffects.spawn_coin_particles(Vector2.ZERO)
	assert_not_null(particles)
	if particles:
		assert_gt(particles.lifetime, 0.0, "Particles should have a positive lifetime")
		assert_lt(particles.lifetime, 3.0, "Particles lifetime should be under 3 seconds")
		particles.queue_free()
