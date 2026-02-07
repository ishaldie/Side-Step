# 🧪 Side Step Test Suite

This project uses [GUT (Godot Unit Test)](https://github.com/bitwes/Gut) for testing.

## 📦 Installation (One-Time Setup)

### Step 1: Install GUT via Asset Library

1. Open the project in **Godot 4.2+**
2. Go to **AssetLib** tab (top of editor)
3. Search for "**GUT**"
4. Click **Download** → **Install**
5. Enable the plugin: **Project → Project Settings → Plugins → GUT → Enable**

### Step 2: Configure Test Directories ⚠️ IMPORTANT

After enabling GUT, you **must** tell it where your tests are located:

**Method A: Via GUT Panel (Recommended)**
1. Look for the **GUT** panel at the bottom of the editor
2. Click the **gear icon** (⚙️) to open Settings
3. Under **Directories**, click **Add** and enter:
   - `res://test/unit`
   - `res://test/integration`
4. Click **Save**

**Method B: Edit Config File Directly**
1. Close Godot
2. Open `.gut_editor_config.json` in the project root
3. Ensure it contains:
```json
{
    "directories": [
        "res://test/unit",
        "res://test/integration"
    ],
    "include_subdirectories": true,
    "prefix": "test_",
    "suffix": ".gd"
}
```
4. Reopen Godot

### Step 3: Verify Setup

The GUT panel should now show:
```
📁 res://test/unit
   📄 test_game_calculations.gd (35 tests)
   📄 test_game_configs.gd (18 tests)
   📄 test_obstacle_configs.gd (12 tests)
📁 res://test/integration
   📄 test_game_manager.gd (25 tests)
```

---

## 🚀 Running Tests

### Option 1: GUI (Recommended)

1. Open the **GUT** panel at the bottom of the editor
2. Click **Run All** to run all tests
3. Or double-click individual test files

### Option 2: Command Line

```bash
# With directory flags (most reliable)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gdir=res://test/integration

# macOS full path example
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gdir=res://test/integration
```

---

## 🔧 Troubleshooting

### "You do not have any directories set"
This is the most common issue! Fix it by:
1. Open GUT panel → click gear icon (⚙️)
2. Add `res://test/unit` and `res://test/integration`
3. Save and restart Godot

### "GUT not found" / No GUT panel visible
- Verify plugin is enabled: Project → Project Settings → Plugins → GUT ✓
- Restart Godot after enabling

### "Tests not discovered"
- Test **files** must start with `test_`
- Test **functions** must start with `test_`
- Test files must have `extends GutTest` at the top

### Tests fail with "Autoload not found"
- Integration tests need autoloads registered in project.godot
- Make sure GameManager, etc. are enabled as autoloads

---

## 📁 Test Structure

```
test/
├── unit/                           # Fast, isolated tests (no autoloads)
│   ├── test_game_calculations.gd   # Pure math/logic (35 tests)
│   ├── test_obstacle_configs.gd    # Obstacle validation (12 tests)
│   └── test_game_configs.gd        # Data validation (18 tests)
│
└── integration/                    # Tests requiring autoloads
    └── test_game_manager.gd        # State management (25 tests)
```

**Total: ~90 tests**

---

## ✍️ Writing New Tests

```gdscript
extends GutTest

func before_each():
    # Reset state before each test
    pass

func test_my_feature():
    # Arrange
    var input = 5
    
    # Act
    var result = GameCalculations.calculate_progress(input, 10)
    
    # Assert
    assert_eq(result, 0.5, "Should return 50% progress")
```

### Common Assertions

| Assertion | Description |
|-----------|-------------|
| `assert_eq(a, b)` | a equals b |
| `assert_ne(a, b)` | a not equal to b |
| `assert_true(x)` | x is true |
| `assert_false(x)` | x is false |
| `assert_gt(a, b)` | a > b |
| `assert_lt(a, b)` | a < b |
| `assert_has(arr, item)` | array contains item |
| `assert_almost_eq(a, b, 0.01)` | floats within tolerance |

---

## 📊 Expected Output

```
Running Tests
---------------------------------------------
* test_game_calculations.gd
  - test_calculate_progress_normal: PASSED
  - test_calculate_progress_zero_target: PASSED
  - test_is_level_complete: PASSED
  ... (32 more)

* test_game_configs.gd
  - test_shoes_array_exists: PASSED
  - test_all_worlds_have_required_fields: PASSED
  ... (16 more)

---------------------------------------------
90 passed, 0 failed
```
