# Conductor Growth Experience (CGX)

**Track:** `cleanup_and_qa_20260208`
**Purpose:** Log observations during implementation for continuous improvement analysis.

---

## Frustrations & Friction

- [2026-02-11] Context window ran out mid-session during the first pass. Had to resume from summary, losing some granular context about which changes were from the linter vs manual edits.
- [2026-02-11] Windows `del` command not available in bash shell — had to use `rm` instead to delete result.gd.

---

## Patterns Observed

### Good Patterns (to encode)
- Reading ALL files before making changes gave a complete picture and prevented cascading issues
- Grouping fixes by priority (Critical > High > Medium) ensured the most impactful issues were addressed first
- Verifying save compatibility when changing encryption key derivation — split strings must concatenate to the exact same key

### Anti-Patterns (to prevent)
- CUSTOM_SPRITE_MAP and PRELOADED_CUSTOM were created as two parallel dictionaries with identical keys — should have been one from the start
- Tutorial and GameManager sharing a save file path created a coupling that made encryption migration harder
- Shoe speed values in SHOES array were all set to 220.0 (user/linter change noticed) — shoe "speed" stat differentiation may be broken

---

## Missing Capabilities

- Godot headless test runner doesn't provide a current_scene, making particle tests that depend on scene tree attachment inherently fragile

---

## Insights & Suggestions

- The codebase had good architectural patterns (object pooling, state machine, event bus) but accumulated technical debt in data redundancy and hardcoded values
- preload() vs load() is critical for mobile performance — should be enforced via a linting rule or code review checklist

---

## Improvement Candidates

### [Type: skill] preload-audit
- **Scope:** project
- **Rationale:** Automatically find runtime load() calls that could be preload() constants
- **Source:** Found 5 separate files with load() in loops during this cleanup pass
