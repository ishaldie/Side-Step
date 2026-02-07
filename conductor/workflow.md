# Development Workflow — Sidestep

## Methodology: TDD (Test-Driven Development)
1. Write failing test first
2. Implement minimum code to pass
3. Refactor if needed

## Commit Convention
```
conductor(phase): [Description]
conductor(task): [Description]
conductor(checkpoint): Phase [N] complete
conductor(revert): Revert [scope] - [reason]
```

## Versioning: Semantic (Major.Minor.Patch)
- **Major:** Breaking changes or overhauls
- **Minor:** New features, worlds, mechanics
- **Patch:** Bug fixes, polish, balance tweaks

### Version Bump Process
1. Update `config/version` in `project.godot`
2. Copy working directory to `sidestep_v<new>/sidestep_v<new>/`
3. Create zip archive of previous version in `_archive_versions/`
4. Update `CHANGELOG.md` with changes

## Code Standards
- **Variables/functions:** `snake_case`
- **Classes:** `PascalCase`
- **Signals:** Use `EventBus` for decoupled communication
- **Functions:** Single responsibility, keep focused
- **Object creation:** Use `ObjectPool` for frequently instantiated objects

## Testing Guidelines
- Framework: GUT (extends `GutTest`)
- Use `add_child_autofree()` for scene instances
- `await get_tree().process_frame` after adding nodes
- Always call `ObjectPool.clear_pools()` in `after_each()`
- Star thresholds: 70% = 1 star, 85% = 2 stars, 95% = 3 stars
- Do NOT reference `GameManager.calculate_score()` — use `GameCalculations` instead

## Track Workflow
1. Create track with spec and plan
2. Implement phase by phase
3. Each phase: write tests -> implement -> verify
4. Mark tasks complete as they pass
5. Checkpoint commit after each phase
6. Mark track complete when all phases done

## File Organization
- Autoloads in `autoload/`
- Scene scripts in `scripts/`
- Scene files in `scenes/`
- Tests in `test/unit/` and `test/integration/`
- Assets in `assets/` (subdirs: sprites, audio, ui, etc.)
