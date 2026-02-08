## EventBus Autoload
## Central hub for game-wide events. Decouples systems that need to react
## to game events without direct dependencies.
##
## Usage:
##   # Publishing
##   EventBus.ad_showing.emit("interstitial")
##
##   # Subscribing
##   func _ready():
##       EventBus.ad_closed.connect(_on_ad_closed)
extends Node

# =============================================================================
# AD EVENTS (used by AdManager)
# =============================================================================

## Emitted when an ad is about to show
## @param ad_type: String - "banner", "interstitial", "rewarded"
signal ad_showing(ad_type: String)

## Emitted when an ad is closed
## @param ad_type: String
signal ad_closed(ad_type: String)

## Emitted when a rewarded ad completes
## @param reward_type: String
## @param reward_amount: int
signal ad_reward_earned(reward_type: String, reward_amount: int)

# =============================================================================
# POWERUP EVENTS
# =============================================================================

## Emitted when a powerup is picked up by the player
## @param powerup_type: int (Powerup.Type enum value)
signal powerup_collected(powerup_type: int)

## Emitted when a powerup effect activates on the player
## @param powerup_type: int
## @param duration: float
signal powerup_activated(powerup_type: int, duration: float)

## Emitted when a powerup effect expires
## @param powerup_type: int
signal powerup_expired(powerup_type: int)
