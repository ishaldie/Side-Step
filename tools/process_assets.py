"""
Asset Processing Script for Side Step
Splits sprite sheets into individual sprites and organizes them.
"""
from PIL import Image
import os
from pathlib import Path

# Base paths
DOWNLOADS = Path(r"C:\Users\zrina\Downloads")
ASSETS_DIR = Path(r"C:\Users\zrina\OneDrive\Documents\wORK\App\Sidestep\sidestep_v2.5.2\sidestep\assets\sprites")

def remove_checkered_background(img):
    """Remove checkered/transparent background pattern."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Detect checkered pattern (light gray ~204 and white ~255)
            if (r > 200 and g > 200 and b > 200) or (r == g == b and r > 180):
                # Check if it's part of the checkered pattern
                is_checker = (r > 200 and g > 200 and b > 200)
                if is_checker:
                    pixels[x, y] = (0, 0, 0, 0)  # Make transparent

    return img

def split_grid(img_path, output_dir, names, cols=4, padding=10):
    """Split an image into a grid of sprites."""
    img = Image.open(img_path).convert('RGBA')

    # Remove checkered background
    img = remove_checkered_background(img)

    width, height = img.size
    sprite_width = width // cols

    print(f"Processing {img_path.name}: {width}x{height}, {cols} columns")

    for i, name in enumerate(names):
        if i >= cols:
            break

        left = i * sprite_width
        right = (i + 1) * sprite_width

        sprite = img.crop((left, 0, right, height))

        # Find actual content bounds
        bbox = sprite.getbbox()
        if bbox:
            # Add padding
            pad_left = max(0, bbox[0] - padding)
            pad_top = max(0, bbox[1] - padding)
            pad_right = min(sprite.width, bbox[2] + padding)
            pad_bottom = min(sprite.height, bbox[3] + padding)
            sprite = sprite.crop((pad_left, pad_top, pad_right, pad_bottom))

            output_path = output_dir / f"{name}.png"
            sprite.save(output_path)
            print(f"  Saved: {name}.png ({sprite.width}x{sprite.height})")
        else:
            print(f"  Warning: No content found for {name}")

def copy_and_clean_image(img_path, output_path):
    """Copy, remove background, and optimize a single image."""
    img = Image.open(img_path).convert('RGBA')
    img = remove_checkered_background(img)

    # Crop to content
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    img.save(output_path)
    print(f"  Saved: {output_path.name} ({img.width}x{img.height})")

def process_all_assets():
    """Process all downloaded assets."""

    # Ensure directories exist
    for subdir in ["obstacles/road", "obstacles/soccer", "obstacles/beach",
                   "obstacles/underwater", "obstacles/volcano",
                   "powerups", "shoes", "ui", "worlds"]:
        (ASSETS_DIR / subdir).mkdir(parents=True, exist_ok=True)

    # === ROAD OBSTACLES ===
    print("\n=== Processing Road Obstacles ===")
    road_dir = ASSETS_DIR / "obstacles" / "road"

    # Road obstacles 1 (cone, pothole, manhole, barrier)
    road_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_34_06 PM.png"
    if road_img.exists():
        split_grid(road_img, road_dir,
            ["cone", "pothole", "manhole", "barrier"], cols=4)

    # Road obstacles 2 (spikes, crate, pillar, warning)
    road_img2 = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_22_30 PM.png"
    if road_img2.exists():
        split_grid(road_img2, road_dir,
            ["spikes", "crate", "pillar", "warning_sign"], cols=4)

    # === SOCCER OBSTACLES ===
    print("\n=== Processing Soccer Obstacles ===")
    soccer_dir = ASSETS_DIR / "obstacles" / "soccer"
    soccer_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_51_40 PM.png"
    if soccer_img.exists():
        split_grid(soccer_img, soccer_dir,
            ["soccer_ball", "training_cone", "tackle_dummy", "goal_post"], cols=4)

    # === BEACH OBSTACLES ===
    print("\n=== Processing Beach Obstacles ===")
    beach_dir = ASSETS_DIR / "obstacles" / "beach"
    beach_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_48_26 PM.png"
    if beach_img.exists():
        split_grid(beach_img, beach_dir,
            ["beach_ball", "sand_castle", "crab", "surfboard"], cols=4)

    # === UNDERWATER OBSTACLES ===
    print("\n=== Processing Underwater Obstacles ===")
    underwater_dir = ASSETS_DIR / "obstacles" / "underwater"
    underwater_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_44_07 PM.png"
    if underwater_img.exists():
        split_grid(underwater_img, underwater_dir,
            ["jellyfish", "shark_fin", "anchor", "coral"], cols=4)

    # === VOLCANO OBSTACLES ===
    print("\n=== Processing Volcano Obstacles ===")
    volcano_dir = ASSETS_DIR / "obstacles" / "volcano"
    volcano_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_46_14 PM.png"
    if volcano_img.exists():
        split_grid(volcano_img, volcano_dir,
            ["meteor", "lava_geyser", "obsidian_spike", "fire_bat"], cols=4)

    # === POWER-UPS ===
    print("\n=== Processing Power-ups ===")
    powerups_dir = ASSETS_DIR / "powerups"
    powerups_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_23_44 PM.png"
    if powerups_img.exists():
        split_grid(powerups_img, powerups_dir,
            ["shield", "magnet", "speed_bolt"], cols=3)

    # === SHOE ICONS ===
    print("\n=== Processing Shoe Icons ===")
    shoes_dir = ASSETS_DIR / "shoes"
    shoes_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_30_07 PM.png"
    if shoes_img.exists():
        split_grid(shoes_img, shoes_dir,
            ["barefoot", "flip_flops", "running_shoes", "winged_shoes"], cols=4)

    # === UI ICONS ===
    print("\n=== Processing UI Icons ===")
    ui_dir = ASSETS_DIR / "ui"
    ui_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_54_26 PM.png"
    if ui_img.exists():
        # This has 6 items: soccer ball reference, coin, star filled, star empty, pause, settings
        split_grid(ui_img, ui_dir,
            ["soccer_ref", "coin", "star_filled", "star_empty", "pause", "settings"], cols=6)

    # === WORLD ICONS ===
    print("\n=== Processing World Icons ===")
    worlds_dir = ASSETS_DIR / "worlds"
    worlds_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_18_23 PM.png"
    if worlds_img.exists():
        split_grid(worlds_img, worlds_dir,
            ["world_meadow", "world_road", "world_soccer", "world_underwater", "world_volcano"], cols=5)

    # Beach world icon (separate)
    beach_world_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_36_16 PM.png"
    if beach_world_img.exists():
        copy_and_clean_image(beach_world_img, worlds_dir / "world_beach.png")

    # === APP ICON ===
    print("\n=== Processing App Icon ===")
    app_icon_dir = ASSETS_DIR.parent  # assets folder
    app_icon_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_58_52 PM.png"
    if app_icon_img.exists():
        # Don't remove background for app icon - keep it as is
        img = Image.open(app_icon_img)
        # Resize to 1024x1024 for app store
        img_resized = img.resize((1024, 1024), Image.Resampling.LANCZOS)
        img_resized.save(app_icon_dir / "icon.png")
        print(f"  Saved: icon.png (1024x1024)")

    print("\n=== Asset processing complete! ===")

if __name__ == "__main__":
    process_all_assets()
