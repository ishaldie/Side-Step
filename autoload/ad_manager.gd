## AdManager Autoload
## Handles all advertising functionality for monetization.
## This is a stub implementation - requires AdMob plugin for actual ads.
##
## Setup:
##   1. Install Godot AdMob plugin from Asset Library
##   2. Replace PROD_*_ID constants with your AdMob IDs
##   (TEST_MODE auto-detects debug vs release builds)
extends Node

# =============================================================================
# CONFIGURATION
# =============================================================================

## Automatically uses test ads in debug builds, real ads in release exports.
var TEST_MODE: bool = OS.is_debug_build()

## Test Ad Unit IDs (safe for development - Google's official test IDs)
const TEST_BANNER_ID: String = "ca-app-pub-3940256099942544/6300978111"
const TEST_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"

## Production Ad Unit IDs - REPLACE THESE WITH YOUR OWN!
const PROD_BANNER_ID: String = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
const PROD_INTERSTITIAL_ID: String = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
const PROD_REWARDED_ID: String = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"

## How many games between interstitial ads
const GAMES_BETWEEN_INTERSTITIALS: int = 3

## Minimum seconds between interstitials
const MIN_SECONDS_BETWEEN_ADS: float = 60.0

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when interstitial ad closes
signal interstitial_closed

## Emitted when rewarded ad gives reward
signal rewarded_ad_completed(reward_type: String, reward_amount: int)

## Emitted when rewarded ad fails to show
signal rewarded_ad_failed

## Emitted when any ad fails to load
signal ad_failed_to_load(ad_type: String)

## Emitted when banner is shown/hidden
signal banner_visibility_changed(is_visible: bool)

# =============================================================================
# STATE
# =============================================================================

var _admob = null  # AdMob singleton (if available)
var _is_initialized: bool = false
var _interstitial_loaded: bool = false
var _rewarded_loaded: bool = false
var _banner_visible: bool = false

var _games_since_interstitial: int = 0
var _last_interstitial_time: float = 0.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_try_initialize_admob()


func _try_initialize_admob() -> void:
	# Check if AdMob plugin is installed
	if Engine.has_singleton("AdMob"):
		_admob = Engine.get_singleton("AdMob")
		_initialize_admob()
	else:
		push_warning("[AdManager] AdMob plugin not found - ads disabled")
		push_warning("[AdManager] Install from: https://github.com/poing-studios/godot-admob-plugin")


func _initialize_admob() -> void:
	if not _admob:
		return
	
	var config := {
		"is_test": TEST_MODE,
		"is_for_child_directed_treatment": false,
		"max_ad_content_rating": "G",
		"is_real": not TEST_MODE
	}
	
	# Connect signals
	if _admob.has_signal("initialization_completed"):
		_admob.initialization_completed.connect(_on_init_complete)
		_admob.interstitial_loaded.connect(_on_interstitial_loaded)
		_admob.interstitial_closed.connect(_on_interstitial_closed)
		_admob.interstitial_failed_to_load.connect(_on_interstitial_failed)
		_admob.rewarded_ad_loaded.connect(_on_rewarded_loaded)
		_admob.rewarded_ad_earned_reward.connect(_on_reward_earned)
		_admob.rewarded_ad_closed.connect(_on_rewarded_closed)
		_admob.rewarded_ad_failed_to_load.connect(_on_rewarded_failed)
	
	_admob.initialize(config)
	print("[AdManager] Initializing (test_mode=%s)" % TEST_MODE)


func _on_init_complete(_status: int) -> void:
	_is_initialized = true
	print("[AdManager] Initialized successfully")
	
	# Preload ads
	load_interstitial()
	load_rewarded()

# =============================================================================
# BANNER ADS
# =============================================================================

## Shows a banner ad at the specified position
## @param position: "TOP" or "BOTTOM"
func show_banner(position: String = "BOTTOM") -> void:
	if not _admob:
		print("[AdManager] Banner requested but AdMob not available")
		return
	
	var ad_id := TEST_BANNER_ID if TEST_MODE else PROD_BANNER_ID
	
	_admob.load_banner({
		"ad_unit_id": ad_id,
		"position": position,
		"size": "BANNER"
	})
	
	_banner_visible = true
	banner_visibility_changed.emit(true)
	print("[AdManager] Banner shown at %s" % position)


## Hides the banner ad (can be shown again)
func hide_banner() -> void:
	if _admob:
		_admob.hide_banner()
		_banner_visible = false
		banner_visibility_changed.emit(false)


## Destroys the banner ad (must reload to show again)
func destroy_banner() -> void:
	if _admob:
		_admob.destroy_banner()
		_banner_visible = false
		banner_visibility_changed.emit(false)


## Returns whether banner is currently visible
func is_banner_visible() -> bool:
	return _banner_visible

# =============================================================================
# INTERSTITIAL ADS
# =============================================================================

## Preloads an interstitial ad
func load_interstitial() -> void:
	if not _admob:
		return
	
	var ad_id := TEST_INTERSTITIAL_ID if TEST_MODE else PROD_INTERSTITIAL_ID
	_admob.load_interstitial(ad_id)
	print("[AdManager] Loading interstitial...")


## Shows interstitial if loaded
## @return: true if ad was shown
func show_interstitial() -> bool:
	if not _admob or not _interstitial_loaded:
		print("[AdManager] Interstitial not ready")
		return false
	
	_admob.show_interstitial()
	_last_interstitial_time = Time.get_ticks_msec() / 1000.0
	EventBus.ad_showing.emit("interstitial")
	print("[AdManager] Showing interstitial")
	return true


## Shows interstitial if frequency cap allows
## Call this at natural break points (death, level complete)
func show_interstitial_if_ready() -> void:
	_games_since_interstitial += 1
	
	# Check frequency cap
	if _games_since_interstitial < GAMES_BETWEEN_INTERSTITIALS:
		return
	
	# Check time cap
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_interstitial_time < MIN_SECONDS_BETWEEN_ADS:
		return
	
	if show_interstitial():
		_games_since_interstitial = 0


## Returns whether interstitial is loaded
func is_interstitial_ready() -> bool:
	return _interstitial_loaded


func _on_interstitial_loaded() -> void:
	_interstitial_loaded = true
	print("[AdManager] Interstitial loaded")


func _on_interstitial_closed() -> void:
	_interstitial_loaded = false
	interstitial_closed.emit()
	EventBus.ad_closed.emit("interstitial")
	# Preload next one
	load_interstitial()


func _on_interstitial_failed(_error_code: int) -> void:
	_interstitial_loaded = false
	ad_failed_to_load.emit("interstitial")
	print("[AdManager] Interstitial failed to load: %d" % _error_code)

# =============================================================================
# REWARDED ADS
# =============================================================================

## Preloads a rewarded ad
func load_rewarded() -> void:
	if not _admob:
		return
	
	var ad_id := TEST_REWARDED_ID if TEST_MODE else PROD_REWARDED_ID
	_admob.load_rewarded_ad(ad_id)
	print("[AdManager] Loading rewarded ad...")


## Shows rewarded ad if loaded
## Connect to rewarded_ad_completed signal to receive reward
## @return: true if ad was shown
func show_rewarded() -> bool:
	if not _admob or not _rewarded_loaded:
		print("[AdManager] Rewarded ad not ready")
		rewarded_ad_failed.emit()
		return false
	
	_admob.show_rewarded_ad()
	EventBus.ad_showing.emit("rewarded")
	print("[AdManager] Showing rewarded ad")
	return true


## Returns whether rewarded ad is loaded
func is_rewarded_ready() -> bool:
	return _rewarded_loaded


func _on_rewarded_loaded() -> void:
	_rewarded_loaded = true
	print("[AdManager] Rewarded ad loaded")


func _on_reward_earned(reward_type: String, reward_amount: int) -> void:
	print("[AdManager] Reward earned: %s x%d" % [reward_type, reward_amount])
	rewarded_ad_completed.emit(reward_type, reward_amount)
	EventBus.ad_reward_earned.emit(reward_type, reward_amount)


func _on_rewarded_closed() -> void:
	_rewarded_loaded = false
	EventBus.ad_closed.emit("rewarded")
	# Preload next one
	load_rewarded()


func _on_rewarded_failed(_error_code: int) -> void:
	_rewarded_loaded = false
	rewarded_ad_failed.emit()
	ad_failed_to_load.emit("rewarded")
	print("[AdManager] Rewarded ad failed to load: %d" % _error_code)
