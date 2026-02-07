# Code Style Guides — Sidestep

## GDScript Style
Follow the GDScript style guide (Godot docs):

- `snake_case` for variables, functions, signals
- `PascalCase` for classes and node names
- `UPPER_SNAKE_CASE` for constants and enums
- Tabs for indentation (Godot default)
- Type hints where practical: `var speed: float = 200.0`
- `@onready` for node references: `@onready var sprite := $Sprite2D`
- `@export` for inspector-visible properties

## Project-Specific Conventions
- Use `EventBus` signals over direct node references
- Use `ObjectPool` for any object spawned frequently (obstacles, coins, particles)
- Keep autoload singletons focused on a single responsibility
- Scene scripts should attach to their root node only
- Test files prefixed with `test_` in appropriate test directory
