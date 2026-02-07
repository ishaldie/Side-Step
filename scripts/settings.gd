## Settings Screen
## Allows players to adjust game settings including audio and controls.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var _music_slider: HSlider = $Panel/VBoxContainer/MusicContainer/MusicSlider
@onready var _sfx_slider: HSlider = $Panel/VBoxContainer/SFXContainer/SFXSlider
@onready var _music_toggle: CheckButton = $Panel/VBoxContainer/MusicContainer/MusicToggle
@onready var _sfx_toggle: CheckButton = $Panel/VBoxContainer/SFXContainer/SFXToggle
@onready var _music_value_label: Label = $Panel/VBoxContainer/MusicContainer/MusicValue
@onready var _sfx_value_label: Label = $Panel/VBoxContainer/SFXContainer/SFXValue

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_load_current_settings()
	_connect_signals()


func _load_current_settings() -> void:
	_music_slider.value = AudioManager.get_music_volume() * 100
	_sfx_slider.value = AudioManager.get_sfx_volume() * 100
	_music_toggle.button_pressed = AudioManager.is_music_enabled()
	_sfx_toggle.button_pressed = AudioManager.is_sfx_enabled()
	_update_value_labels()


func _connect_signals() -> void:
	_music_slider.value_changed.connect(_on_music_slider_changed)
	_sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	_music_toggle.toggled.connect(_on_music_toggle_changed)
	_sfx_toggle.toggled.connect(_on_sfx_toggle_changed)


func _update_value_labels() -> void:
	_music_value_label.text = "%d%%" % int(_music_slider.value)
	_sfx_value_label.text = "%d%%" % int(_sfx_slider.value)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_music_slider_changed(value: float) -> void:
	AudioManager.set_music_volume(value / 100.0)
	_update_value_labels()


func _on_sfx_slider_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)
	_update_value_labels()
	# Play a test sound
	AudioManager.play_button()


func _on_music_toggle_changed(enabled: bool) -> void:
	AudioManager.set_music_enabled(enabled)
	_music_slider.editable = enabled


func _on_sfx_toggle_changed(enabled: bool) -> void:
	AudioManager.set_sfx_enabled(enabled)
	_sfx_slider.editable = enabled

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_back_button_pressed() -> void:
	AudioManager.play_button()
	GameManager.go_to_main_menu()


func _on_reset_settings_pressed() -> void:
	AudioManager.set_music_volume(AudioManager.DEFAULT_MUSIC_VOLUME)
	AudioManager.set_sfx_volume(AudioManager.DEFAULT_SFX_VOLUME)
	AudioManager.set_music_enabled(true)
	AudioManager.set_sfx_enabled(true)
	_load_current_settings()
	AudioManager.play_button()
