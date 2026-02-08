# Spec: Positioning Review & Obstacle Classification

## Overview
Review and correct the positioning of the player character, the floor, and all obstacle types. Ensure each obstacle is classified and configured as either a jumping obstacle or a duck obstacle, with correct placement and collision alignment.

## Requirements
1. Audit player character position relative to floor and obstacle lanes across gameplay scenes.
2. Audit floor placement and collision alignment to ensure consistent ground level.
3. Audit all obstacle scenes for correct position, collision shape, and lane alignment.
4. Classify each obstacle as `jump` or `duck` and enforce this in obstacle configuration.
5. Ensure spawning positions respect obstacle classification (e.g., duck obstacles aligned to upper lane, jump obstacles aligned to ground lane).
6. Provide a single source of truth for obstacle positioning offsets and classification.

## Acceptance Criteria
- Player stands on the floor with no visible sinking or floating across all worlds.
- Floor collision and visual sprite alignment are consistent.
- Every obstacle is explicitly marked `jump` or `duck`.
- Jump obstacles require jumping to avoid; duck obstacles require ducking to avoid.
- Obstacle spawn positions align with their classification and match collision shapes.
- No regressions to existing gameplay flow.

## Out of Scope
- New obstacle art or animation changes
- Changes to obstacle behavior beyond positioning and classification
- Gameplay balance adjustments unrelated to placement
