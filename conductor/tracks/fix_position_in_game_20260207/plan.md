# Plan: Positioning Review & Obstacle Classification

## Phase 1: Discovery & Tests
- [x] 52bcd1f **1.1 Locate positioning sources** — Identify player, floor, and obstacle placement logic (scenes/scripts/configs)
- [x] 6dce4ac **1.2 Add/extend tests** — Failing tests for obstacle classification, spawn lane alignment, and floor/player alignment assumptions (RED phase)

## Phase 2: Classification & Data
- [x] d353acf **2.1 Define obstacle type field** — Add `jump`/`duck` classification in obstacle config or script
- [x] 9d49e80 **2.2 Centralize positioning offsets** — Single source of truth for lane heights and obstacle offsets
- [x] 17afcd0 **2.3 Update obstacle scenes** — Align sprites/collision shapes to classification

## Phase 3: Spawn & Alignment
- [x] bfc0719 **3.1 Enforce spawn rules** — Spawn positions respect `jump`/`duck`
- [x] bfc0719 **3.2 Player & floor alignment fix** — Adjust placement to match floor collision consistently
- [x] bfc0719 **3.3 Verify in tests** — New + existing tests green
[checkpoint: abf7230]

## Phase 4: Verification
- [ ] **4.1 Manual review checklist** — Validate in at least one level per world
- [ ] **4.2 Update changelog** — Document positioning/classification fixes
