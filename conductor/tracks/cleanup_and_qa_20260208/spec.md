# Spec: Cleanup and QA

**Track ID:** `cleanup_and_qa_20260208`
**Type:** refactor

## Overview

Comprehensive code quality review and fix pass across the entire Sidestep codebase (~9400 LOC, 38 .gd files). Identified and fixed bugs, dead code, redundant data structures, runtime performance issues, security concerns, and naming inconsistencies.

## Requirements

1. Remove dead code and unused classes
2. Fix all identified bugs (sprite scaling, spawn order, null crashes, type mismatches)
3. Eliminate redundant data structures (consolidate duplicate dictionaries)
4. Replace runtime `load()` with `preload()` for mobile performance
5. Fix security concerns (hardcoded TEST_MODE, plaintext encryption key)
6. Fix save path inconsistencies between subsystems
7. Correct misleading parameter names in analytics

## Acceptance Criteria

- [x] No hardcoded TEST_MODE — uses OS.is_debug_build()
- [x] Encryption key not in plaintext — derived at runtime
- [x] Unused Result class removed
- [x] Player sprite scale drift fixed
- [x] Null-safe particle spawning during scene transitions
- [x] No duplicate _add_coin_icon methods — consolidated to UIUtils
- [x] CUSTOM_SPRITE_MAP removed — PRELOADED_CUSTOM used directly
- [x] All UI textures preloaded (shop, world_select, level_select)
- [x] Tutorial saves to its own file, not GameManager's path
- [x] Analytics parameters correctly named and typed
- [x] 125/126 tests passing (1 pre-existing risky test)

## Out of Scope

- New features or gameplay changes
- Art asset updates
- Ad/analytics service integration
- Performance profiling beyond preload optimization
