# Conductor Growth Experience (CGX)

**Track:** `fix_the_boundaries_on_each_obstacle_to_match_the_visual_20260207`

---

## Frustrations & Friction

- [2026-02-07] CLAUDE.md says project is at `sidestep_v2.7.7/sidestep_v2.7.7/` but that dir is empty. Actual project files are at `Sidestep/` root. Wasted time discovering this.

---

## Patterns Observed

### Good Patterns (to encode)
- [2026-02-07] Math-first audit before writing tests — computed collision vs visual mismatch for 5 representative obstacles to confirm the bug pattern.

### Anti-Patterns (to prevent)
- [2026-02-07] `_setup_collision` takes raw config width/height but the visual sprite is scaled from texture dimensions — two independent sizing systems that diverge for non-square textures.

---

## Missing Capabilities

- A Godot headless test runner accessible from CLI would let us verify tests fail/pass without the editor.

---

## Insights & Suggestions

- [2026-02-07] Collision should derive from rendered sprite size, not config size. Config width/height is the target visual size input; collision flows from rendered dimensions.

---

## Improvement Candidates

### [Type: skill] verify-project-path
- **Scope:** project
- **Rationale:** Auto-detect Godot project root by finding project.godot
- **Source:** Empty sidestep_v2.7.7/ dir confusion
