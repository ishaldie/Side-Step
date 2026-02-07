# Side Step - Apple App Store Review Recommendations

**Reviewer:** Senior iOS App Review Specialist  
**Date:** January 2026  
**Overall Assessment:** Significant improvements needed before App Store submission

---

## Executive Summary

Side Step shows promise as a casual auto-runner game with solid core mechanics. However, the app requires substantial work in several critical areas before it can compete effectively on the App Store and meet Apple's quality guidelines. The recommendations below are prioritized by impact on user experience, retention, and monetization potential.

---

## 🚨 CRITICAL ISSUES (Must Fix Before Submission)

### 1. No Visual Assets - Placeholder Graphics Only

**Current State:** The entire game uses procedurally-generated Polygon2D shapes for all visual elements including player, obstacles, coins, UI, and backgrounds.

**Impact:** 
- App will likely be rejected under App Store Review Guideline 4.0 (Design) for minimum functionality
- Zero visual appeal in App Store screenshots
- Cannot compete with polished competitors
- No brand identity or memorable characters

**Recommendations:**
- [ ] Hire a 2D artist or purchase asset packs for:
  - Player character with running, jumping, ducking, death animations
  - Obstacle sprites for all 65+ obstacle types
  - Coin and collectible animations
  - Background parallax layers for all 5 worlds
  - UI elements (buttons, panels, icons)
- [ ] Create app icon (1024x1024) that stands out in search results
- [ ] Design splash/launch screen
- [ ] Add particle effects for:
  - Coin collection
  - Player death
  - Dash ability
  - Double jump
  - Level completion celebration

### 2. Missing App Store Required Elements

**Current State:** No privacy policy, no App Store metadata, missing required configurations.

**Recommendations:**
- [ ] Create Privacy Policy URL (required for all apps)
- [ ] Prepare App Store Connect metadata:
  - App description (4000 chars max)
  - Keywords (100 chars)
  - What's New text
  - Support URL
  - Marketing URL
- [ ] Create screenshots for all required device sizes:
  - 6.7" (iPhone 15 Pro Max)
  - 6.5" (iPhone 11 Pro Max)
  - 5.5" (iPhone 8 Plus)
  - iPad Pro 12.9"
- [ ] Design app preview videos (optional but highly recommended)
- [ ] Configure App Store age rating questionnaire
- [ ] Set up App Privacy "nutrition labels"

### 3. No Tutorial or Onboarding

**Current State:** Players are dropped into gameplay with no instruction on controls or mechanics.

**Impact:**
- High early churn rate
- Negative reviews from confused users
- Poor retention metrics

**Recommendations:**
- [ ] Add first-time user tutorial showing:
  - Tap to jump
  - Hold bottom of screen to duck
  - Swipe right to dash (when unlocked)
  - Double-tap for double jump (when unlocked)
  - Coin collection goals
  - Star rating system
- [ ] Show contextual tooltips when new mechanics unlock
- [ ] Add a "How to Play" section in settings

---

## ⚠️ HIGH PRIORITY (Significant Impact on Success)

### 4. Monetization Strategy Incomplete

**Current State:** 
- Ad framework stubbed but not implemented
- No In-App Purchases configured
- Rewarded ads offer no actual rewards in code
- No "Remove Ads" purchase option

**Impact:**
- Zero revenue potential
- Missing opportunity for ethical monetization
- No way to convert engaged users to paying customers

**Recommendations:**
- [ ] Implement StoreKit 2 for In-App Purchases:
  - "Remove Ads" - $2.99 (one-time)
  - "Coin Doubler" - $1.99 (one-time)
  - Coin packs: 500/$0.99, 2000/$2.99, 5000/$4.99
  - "Starter Bundle" (coins + shoes) - $4.99
- [ ] Complete AdMob integration:
  - Banner ads in menus (not during gameplay)
  - Interstitial after every 3rd death
  - Rewarded video for:
    - Continue after death (keep coins)
    - Double coin bonus at level end
    - Free daily coins
- [ ] Add "Watch Ad" button that actually grants rewards
- [ ] Implement receipt validation for purchases
- [ ] Handle interrupted purchases and restore purchases

### 5. Accessibility Not Implemented

**Current State:** No accessibility features whatsoever.

**Impact:**
- Excludes users with disabilities
- May face App Store rejection in some regions
- Missing iOS accessibility API integration

**Recommendations:**
- [ ] Add VoiceOver support for all menus
- [ ] Implement Dynamic Type for text scaling
- [ ] Add colorblind mode (affects coin colors, obstacles)
- [ ] Support "Reduce Motion" system preference
- [ ] Add haptic feedback options (currently forced on)
- [ ] Implement switch control support
- [ ] Add audio cues for visual events
- [ ] Support one-handed play mode

### 6. No Social Features or Engagement Hooks

**Current State:** Single-player only, no leaderboards, no sharing, no achievements.

**Impact:**
- Low viral coefficient
- No competitive motivation
- Missing retention mechanics

**Recommendations:**
- [ ] Integrate Game Center:
  - Global leaderboards (total stars, total coins, best distance)
  - Per-world leaderboards
  - 20+ achievements (first level, first star, all shoes, etc.)
- [ ] Add share functionality:
  - Share score card to social media
  - Challenge friends via Messages
- [ ] Daily challenges with bonus rewards
- [ ] Weekly events with special obstacles
- [ ] Streak bonuses for consecutive daily play

### 7. Audio Assets Severely Limited

**Current State:** Only one music track, all sound effects are generated programmatically (likely silent or glitchy).

**Impact:**
- Poor audio experience
- Missing satisfying feedback sounds
- No audio variety across 25 levels

**Recommendations:**
- [ ] Add sound effects for:
  - Jump (with variation)
  - Land
  - Coin collect (satisfying "ding")
  - Death/hit
  - Dash whoosh
  - Duck
  - Level complete fanfare
  - Star earned
  - Shop purchase
  - Button clicks
  - World unlock
- [ ] Add 5 unique music tracks (one per world):
  - Road: Upbeat electronic
  - Soccer: Stadium anthem style
  - Beach: Tropical/chill
  - Underwater: Ambient/mysterious
  - Volcano: Intense/dramatic
- [ ] Implement audio ducking during important events
- [ ] Add ambient sound layers per world

---

## 📋 MEDIUM PRIORITY (Polish & Quality of Life)

### 8. Performance & Technical Debt

**Current Issues:**
- `game.gd` is 1100+ lines (should be split)
- `obstacle.gd` is 900+ lines with 65+ obstacle configs inline
- No loading screens for scene transitions
- Object pooling exists but needs stress testing

**Recommendations:**
- [ ] Refactor large scripts into smaller, focused classes
- [ ] Move obstacle configs to resource files (.tres)
- [ ] Add loading indicator for scene transitions
- [ ] Profile and optimize for older devices (iPhone 8 minimum)
- [ ] Implement proper error handling and crash reporting
- [ ] Add TestFlight for beta testing
- [ ] Set up Firebase Crashlytics or similar

### 9. Missing User Experience Features

**Recommendations:**
- [ ] Add pause menu with:
  - Resume button
  - Restart level
  - Settings access
  - Return to menu
- [ ] Show coin collection progress during gameplay
- [ ] Add distance remaining indicator
- [ ] Implement "Rate This App" prompt (after positive moments)
- [ ] Add offline mode indicator
- [ ] Support background audio from other apps
- [ ] Handle phone calls gracefully
- [ ] Add battery-saving mode option

### 10. Localization Not Implemented

**Current State:** English only, hardcoded strings throughout.

**Recommendations:**
- [ ] Extract all strings to localization files
- [ ] Prioritize translations for:
  - Spanish (largest iOS market after English)
  - Chinese Simplified
  - Japanese
  - German
  - French
  - Portuguese (Brazil)
- [ ] Localize App Store metadata
- [ ] Support RTL languages (Arabic, Hebrew)

### 11. Analytics Integration Incomplete

**Current State:** Analytics autoload exists but is mostly stubbed.

**Recommendations:**
- [ ] Implement Firebase Analytics or similar:
  - Track level starts/completions
  - Track deaths and failure points
  - Track shop views and purchases
  - Track ad impressions and engagement
  - Track session length and retention
- [ ] Set up conversion funnels:
  - Install → First Level Complete
  - First Level → First Purchase
  - Day 1 → Day 7 Retention
- [ ] Implement A/B testing framework
- [ ] Add remote config for tuning without updates

---

## 📝 LOW PRIORITY (Nice to Have)

### 12. Content & Engagement

- [ ] Add more shoe types with unique abilities
- [ ] Implement daily login rewards
- [ ] Add seasonal events (Halloween, Christmas, etc.)
- [ ] Create "Endless Mode" after completing all worlds
- [ ] Add boss battles at end of each world
- [ ] Implement pet/companion system
- [ ] Add customizable player skins

### 13. Technical Enhancements

- [ ] Support iPad multitasking (Split View, Slide Over)
- [ ] Add Apple Watch companion app for notifications
- [ ] Implement Shortcuts app integration
- [ ] Support external controllers
- [ ] Add replay system for sharing clips

---

## App Store Optimization (ASO) Recommendations

### Keywords to Target
- endless runner
- side scroller
- obstacle course
- jump game
- casual game
- one tap game
- arcade game
- running game

### Competitor Analysis Needed
- Research top 100 in Arcade category
- Analyze successful auto-runners (Subway Surfers, Temple Run, etc.)
- Study pricing strategies
- Review 1-star reviews for common complaints to avoid

---

## Estimated Timeline to App Store Ready

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Art & Audio | 4-6 weeks | All visual assets, 5 music tracks, 20+ SFX |
| Critical Features | 2-3 weeks | Tutorial, IAP, Ads, Accessibility basics |
| Polish | 2 weeks | Performance, localization setup, analytics |
| Testing | 2 weeks | Beta testing, crash fixes, balancing |
| Submission | 1 week | App Store assets, review response |

**Total: 11-14 weeks minimum**

---

## Conclusion

Side Step has solid gameplay foundations with well-implemented state machines, touch controls, and progression systems. However, the complete absence of visual assets, missing monetization implementation, and lack of accessibility features make it unsuitable for App Store submission in its current state.

The recommended path forward is to prioritize visual assets and core monetization before any public release, as these directly impact first impressions and revenue potential. The game's systems are well-architected for adding these features without major refactoring.

**Recommendation: Do not submit to App Store until at least all CRITICAL and HIGH priority items are addressed.**

---

*This review was conducted against Apple's App Store Review Guidelines (2024) and iOS Human Interface Guidelines.*
