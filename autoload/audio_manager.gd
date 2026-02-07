## AudioManager Autoload
## Manages all game audio including sound effects and background music.
## Provides volume control and audio pooling for efficient playback.
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const SFX_POOL_SIZE: int = 8
const DEFAULT_MUSIC_VOLUME: float = 0.7
const DEFAULT_SFX_VOLUME: float = 0.6  # Reduced from 1.0 for softer sounds
const MUSIC_VOLUME_MULTIPLIER: float = 0.5  # Background music plays quieter
const AUDIO_SAVE_PATH: String = "user://audio_settings.cfg"

# iOS-compatible audio settings
const SAMPLE_RATE: int = 44100  # Standard rate for iOS compatibility
const AUDIO_FORMAT: int = AudioStreamWAV.FORMAT_16_BITS  # 16-bit for iOS

# Audio bus names
const MASTER_BUS: String = "Master"
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"

# =============================================================================
# SIGNALS
# =============================================================================

signal volume_changed(bus_name: String, volume: float)

# =============================================================================
# STATE
# =============================================================================

var _music_volume: float = DEFAULT_MUSIC_VOLUME
var _sfx_volume: float = DEFAULT_SFX_VOLUME
var _music_enabled: bool = true
var _sfx_enabled: bool = true

var _current_music: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx_index: int = 0
var _background_music: AudioStream = null
var _music_available: bool = false

const MUSIC_PATH: String = "res://assets/audio/High_Score_Heart.ogg"

# =============================================================================
# SOUND DEFINITIONS
# =============================================================================

enum SFX {
	JUMP,
	DOUBLE_JUMP,
	DUCK,
	COIN,
	HIT,
	DEATH,
	LEVEL_COMPLETE,
	BUTTON,
	PURCHASE,
	EQUIP
}

# SFX configuration: [duration, frequency] - tuned for softer, more pleasant sounds
const SFX_CONFIG: Dictionary = {
	SFX.JUMP: [0.12, 440.0],        # Softer, lower frequency
	SFX.DOUBLE_JUMP: [0.15, 550.0], # Slightly longer, softer
	SFX.DUCK: [0.1, 220.0],         # Deeper, softer
	SFX.COIN: [0.15, 660.0],        # Lower freq, longer for pleasant chime
	SFX.HIT: [0.12, 150.0],         # Shorter, deeper
	SFX.DEATH: [0.35, 100.0],       # Deeper, more subdued
	SFX.LEVEL_COMPLETE: [0.5, 520.0], # Longer, triumphant but softer
	SFX.BUTTON: [0.06, 480.0],      # Softer click
	SFX.PURCHASE: [0.25, 580.0],    # Softer purchase sound
	SFX.EQUIP: [0.15, 440.0]        # Softer equip
}

# SFX pitch ranges: [min, max]
const SFX_PITCH: Dictionary = {
	SFX.JUMP: [0.95, 1.05],
	SFX.DOUBLE_JUMP: [1.1, 1.2],
	SFX.DUCK: [0.7, 0.8],
	SFX.COIN: [1.2, 1.4],
	SFX.HIT: [0.8, 0.9],
	SFX.DEATH: [0.6, 0.7]
}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_setup_audio_buses()
	_create_sfx_pool()
	_create_music_player()
	_load_music()
	_load_settings()
	
	# iOS: Ensure audio starts properly after user interaction
	if OS.get_name() == "iOS":
		get_tree().create_timer(0.1).timeout.connect(_ios_audio_warmup)


## Sets up audio buses for proper volume control
func _setup_audio_buses() -> void:
	# Create Music bus if it doesn't exist
	if AudioServer.get_bus_index(MUSIC_BUS) == -1:
		var music_idx := AudioServer.bus_count
		AudioServer.add_bus(music_idx)
		AudioServer.set_bus_name(music_idx, MUSIC_BUS)
		AudioServer.set_bus_send(music_idx, MASTER_BUS)
	
	# Create SFX bus if it doesn't exist
	if AudioServer.get_bus_index(SFX_BUS) == -1:
		var sfx_idx := AudioServer.bus_count
		AudioServer.add_bus(sfx_idx)
		AudioServer.set_bus_name(sfx_idx, SFX_BUS)
		AudioServer.set_bus_send(sfx_idx, MASTER_BUS)


## iOS audio warmup - plays silent audio to initialize audio session
func _ios_audio_warmup() -> void:
	# Create a very short, silent audio to "wake up" iOS audio system
	var warmup := AudioStreamPlayer.new()
	add_child(warmup)
	var silent := AudioStreamWAV.new()
	silent.format = AUDIO_FORMAT
	silent.mix_rate = SAMPLE_RATE
	silent.stereo = false
	var data := PackedByteArray()
	data.resize(1000)  # Very short
	data.fill(0)
	silent.data = data
	warmup.stream = silent
	warmup.volume_db = -80  # Nearly silent
	warmup.play()
	await warmup.finished
	warmup.queue_free()


## Safely loads background music with error handling.
func _load_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		push_warning("[AudioManager] Background music not found: " + MUSIC_PATH)
		push_warning("[AudioManager] Music playback will be disabled")
		_music_available = false
		return
	
	_background_music = load(MUSIC_PATH)
	if _background_music:
		_music_available = true
		print("[AudioManager] Background music loaded successfully")
	else:
		push_warning("[AudioManager] Failed to load background music")
		_music_available = false


func _create_sfx_pool() -> void:
	var sfx_bus_idx := AudioServer.get_bus_index(SFX_BUS)
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		if sfx_bus_idx != -1:
			player.bus = SFX_BUS
		add_child(player)
		_sfx_pool.append(player)


func _create_music_player() -> void:
	_current_music = AudioStreamPlayer.new()
	_current_music.process_mode = Node.PROCESS_MODE_ALWAYS  # Play during pause
	var music_bus_idx := AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus_idx != -1:
		_current_music.bus = MUSIC_BUS
	add_child(_current_music)
	_current_music.finished.connect(_on_music_finished)


func _on_music_finished() -> void:
	if _music_enabled and _current_music.stream:
		_current_music.play()

# =============================================================================
# SOUND EFFECTS
# =============================================================================

## Plays a sound effect by type.
func play_sfx(sfx_type: SFX) -> void:
	if not _sfx_enabled:
		return
	
	if _sfx_pool.is_empty():
		return
	
	var player := _get_next_sfx_player()
	if not player:
		return
	
	var stream := _create_sfx_stream(sfx_type)
	if not stream:
		return
	
	player.stream = stream
	player.volume_db = linear_to_db(_sfx_volume)
	player.pitch_scale = _get_sfx_pitch(sfx_type)
	player.play()


func _get_next_sfx_player() -> AudioStreamPlayer:
	var player := _sfx_pool[_next_sfx_index]
	_next_sfx_index = (_next_sfx_index + 1) % SFX_POOL_SIZE
	return player


func _create_sfx_stream(sfx_type: SFX) -> AudioStreamWAV:
	var config: Array = SFX_CONFIG.get(sfx_type, [0.1, 440.0])
	var duration: float = config[0]
	var frequency: float = config[1]
	var num_samples: int = int(SAMPLE_RATE * duration)

	var audio := AudioStreamWAV.new()
	audio.format = AUDIO_FORMAT  # 16-bit for iOS compatibility
	audio.mix_rate = SAMPLE_RATE
	audio.stereo = false

	# 16-bit audio uses 2 bytes per sample
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / num_samples

		# Exponential decay envelope for smoother, less harsh sound
		var envelope: float = exp(-progress * 4.0) * (1.0 - progress * 0.3)

		# Soft attack (first 5% of sound)
		var attack: float = minf(progress * 20.0, 1.0)
		envelope *= attack

		# Combine sine with slight harmonic for warmer tone
		var sample: float = sin(t * frequency * TAU) * 0.8
		sample += sin(t * frequency * TAU * 2.0) * 0.15  # Soft overtone
		sample *= envelope * 0.7  # Overall volume reduction

		# Convert to 16-bit signed integer (-32768 to 32767)
		var sample_int: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		
		# Store as little-endian 16-bit
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	audio.data = data
	return audio


func _get_sfx_pitch(sfx_type: SFX) -> float:
	if SFX_PITCH.has(sfx_type):
		var pitch_range: Array = SFX_PITCH[sfx_type]
		return randf_range(pitch_range[0], pitch_range[1])
	return 1.0

# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

## Plays the jump sound effect.
func play_jump() -> void:
	play_sfx(SFX.JUMP)

## Plays the double jump sound effect.
func play_double_jump() -> void:
	play_sfx(SFX.DOUBLE_JUMP)

## Plays the duck sound effect.
func play_duck() -> void:
	play_sfx(SFX.DUCK)

## Plays the coin collection sound effect.
func play_coin() -> void:
	play_sfx(SFX.COIN)

## Plays the hit/damage sound effect.
func play_hit() -> void:
	play_sfx(SFX.HIT)

## Plays the death sound effect.
func play_death() -> void:
	play_sfx(SFX.DEATH)

## Plays the level complete sound effect.
func play_level_complete() -> void:
	play_sfx(SFX.LEVEL_COMPLETE)

## Plays the button click sound effect.
func play_button() -> void:
	play_sfx(SFX.BUTTON)

## Plays the purchase sound effect.
func play_purchase() -> void:
	play_sfx(SFX.PURCHASE)

## Plays the equip sound effect.
func play_equip() -> void:
	play_sfx(SFX.EQUIP)

# =============================================================================
# MUSIC
# =============================================================================

## Starts playing background music.
func play_music() -> void:
	if not _music_available or not _music_enabled:
		return
	if _current_music.playing:
		return
	if not _background_music:
		return
	
	_current_music.stream = _background_music
	_current_music.volume_db = linear_to_db(_music_volume * MUSIC_VOLUME_MULTIPLIER)
	_current_music.play()


## Starts the game music (alias for play_music).
func start_game_music() -> void:
	play_music()


## Stops the background music.
func stop_music() -> void:
	if _current_music:
		_current_music.stop()


## Pauses the background music.
func pause_music() -> void:
	if _current_music:
		_current_music.stream_paused = true


## Resumes the background music if enabled.
func resume_music() -> void:
	if _music_available and _music_enabled and _current_music and _current_music.stream:
		_current_music.stream_paused = false

# =============================================================================
# VOLUME CONTROL
# =============================================================================

## Sets the music volume (0.0 to 1.0).
func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	_current_music.volume_db = linear_to_db(_music_volume * MUSIC_VOLUME_MULTIPLIER)
	volume_changed.emit("Music", _music_volume)
	_save_settings()


## Returns the current music volume.
func get_music_volume() -> float:
	return _music_volume


## Sets the SFX volume (0.0 to 1.0).
func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	volume_changed.emit("SFX", _sfx_volume)
	_save_settings()


## Returns the current SFX volume.
func get_sfx_volume() -> float:
	return _sfx_volume


## Enables or disables music playback.
func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		stop_music()
	_save_settings()


## Returns whether music is enabled.
func is_music_enabled() -> bool:
	return _music_enabled


## Enables or disables SFX playback.
func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	_save_settings()


## Returns whether SFX is enabled.
func is_sfx_enabled() -> bool:
	return _sfx_enabled

# =============================================================================
# SETTINGS PERSISTENCE
# =============================================================================

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", _music_volume)
	config.set_value("audio", "sfx_volume", _sfx_volume)
	config.set_value("audio", "music_enabled", _music_enabled)
	config.set_value("audio", "sfx_enabled", _sfx_enabled)
	config.save(AUDIO_SAVE_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(AUDIO_SAVE_PATH) != OK:
		return
	
	_music_volume = config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)
	_sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)
	_music_enabled = config.get_value("audio", "music_enabled", true)
	_sfx_enabled = config.get_value("audio", "sfx_enabled", true)
