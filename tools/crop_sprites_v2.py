"""
Improved Sprite Cropping Script v2
Uses OpenCV for better sprite detection and cropping.
"""
import cv2
import numpy as np
from PIL import Image
from pathlib import Path

DOWNLOADS = Path(r"C:\Users\zrina\Downloads")
ASSETS_DIR = Path(r"C:\Users\zrina\OneDrive\Documents\wORK\App\Sidestep\sidestep_v2.5.2\sidestep\assets\sprites")

def load_image_rgba(path):
    """Load image as RGBA numpy array."""
    img = Image.open(path).convert('RGBA')
    return np.array(img)

def remove_checkered_background(img_array):
    """
    Remove checkered/transparent background more accurately.
    Uses color clustering to identify background colors.
    """
    height, width = img_array.shape[:2]

    # Sample corners to identify background colors
    corner_samples = []
    sample_size = 20

    # Top-left corner
    corner_samples.extend(img_array[0:sample_size, 0:sample_size].reshape(-1, 4).tolist())
    # Top-right corner
    corner_samples.extend(img_array[0:sample_size, width-sample_size:width].reshape(-1, 4).tolist())
    # Bottom-left corner
    corner_samples.extend(img_array[height-sample_size:height, 0:sample_size].reshape(-1, 4).tolist())
    # Bottom-right corner
    corner_samples.extend(img_array[height-sample_size:height, width-sample_size:width].reshape(-1, 4).tolist())

    # Find most common colors (background colors)
    corner_samples = np.array(corner_samples)

    # Background is typically light gray (204, 204, 204) or white (255, 255, 255) in checkered pattern
    # Create mask for background pixels
    result = img_array.copy()

    for y in range(height):
        for x in range(width):
            r, g, b, a = img_array[y, x]

            # Check if pixel is part of checkered background
            # Light gray: ~204, White: ~255, with some tolerance
            is_light_gray = (abs(r - 204) < 15 and abs(g - 204) < 15 and abs(b - 204) < 15)
            is_white = (r > 245 and g > 245 and b > 245)
            is_near_white = (r > 230 and g > 230 and b > 230 and abs(r-g) < 10 and abs(g-b) < 10)

            if is_light_gray or is_white or is_near_white:
                result[y, x] = [0, 0, 0, 0]  # Make transparent

    return result

def find_sprite_regions(img_array, min_area=500, expected_count=None):
    """
    Find individual sprite regions using contour detection.
    Returns list of (x, y, w, h) bounding boxes sorted left to right.
    """
    # Get alpha channel
    if img_array.shape[2] == 4:
        alpha = img_array[:, :, 3]
    else:
        # Convert to grayscale and threshold
        gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
        _, alpha = cv2.threshold(gray, 250, 255, cv2.THRESH_BINARY_INV)

    # Threshold alpha channel
    _, binary = cv2.threshold(alpha, 10, 255, cv2.THRESH_BINARY)

    # Dilate to connect nearby components
    kernel = np.ones((5, 5), np.uint8)
    binary = cv2.dilate(binary, kernel, iterations=2)

    # Find contours
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Get bounding boxes for significant contours
    boxes = []
    for contour in contours:
        area = cv2.contourArea(contour)
        if area > min_area:
            x, y, w, h = cv2.boundingRect(contour)
            boxes.append((x, y, w, h))

    # Sort by x position (left to right)
    boxes.sort(key=lambda b: b[0])

    # If we expect a specific count and have too many, merge nearby boxes
    if expected_count and len(boxes) > expected_count:
        boxes = merge_nearby_boxes(boxes, img_array.shape[1] // (expected_count * 2))

    return boxes

def merge_nearby_boxes(boxes, threshold):
    """Merge boxes that are close together."""
    if not boxes:
        return boxes

    merged = [boxes[0]]
    for box in boxes[1:]:
        last = merged[-1]
        # Check if boxes overlap or are close
        if box[0] < last[0] + last[2] + threshold:
            # Merge
            new_x = min(last[0], box[0])
            new_y = min(last[1], box[1])
            new_right = max(last[0] + last[2], box[0] + box[2])
            new_bottom = max(last[1] + last[3], box[1] + box[3])
            merged[-1] = (new_x, new_y, new_right - new_x, new_bottom - new_y)
        else:
            merged.append(box)

    return merged

def crop_sprite(img_array, box, padding=5):
    """Crop a sprite from the image with padding."""
    x, y, w, h = box
    height, width = img_array.shape[:2]

    # Add padding
    x1 = max(0, x - padding)
    y1 = max(0, y - padding)
    x2 = min(width, x + w + padding)
    y2 = min(height, y + h + padding)

    return img_array[y1:y2, x1:x2]

def save_sprite(sprite_array, output_path):
    """Save sprite array as PNG."""
    img = Image.fromarray(sprite_array, 'RGBA')
    img.save(output_path)
    print(f"  Saved: {output_path.name} ({img.width}x{img.height})")

def process_sprite_sheet(img_path, output_dir, names, expected_count=None):
    """Process a sprite sheet and extract individual sprites."""
    print(f"\nProcessing: {img_path.name}")

    # Load and remove background
    img_array = load_image_rgba(img_path)
    img_clean = remove_checkered_background(img_array)

    # Find sprite regions
    count = expected_count or len(names)
    boxes = find_sprite_regions(img_clean, min_area=500, expected_count=count)

    print(f"  Found {len(boxes)} sprite regions (expected {len(names)})")

    # If we don't have enough boxes, fall back to grid splitting
    if len(boxes) < len(names):
        print(f"  Warning: Using grid fallback")
        width = img_array.shape[1]
        sprite_width = width // len(names)
        boxes = [(i * sprite_width, 0, sprite_width, img_array.shape[0]) for i in range(len(names))]

    # Extract and save each sprite
    output_dir.mkdir(parents=True, exist_ok=True)

    for i, name in enumerate(names):
        if i >= len(boxes):
            print(f"  Warning: No region for {name}")
            continue

        sprite = crop_sprite(img_clean, boxes[i], padding=10)

        # Trim transparent edges
        sprite_img = Image.fromarray(sprite, 'RGBA')
        bbox = sprite_img.getbbox()
        if bbox:
            sprite_img = sprite_img.crop(bbox)
            sprite = np.array(sprite_img)

        save_sprite(sprite, output_dir / f"{name}.png")

def process_single_image(img_path, output_path):
    """Process a single image (remove background and trim)."""
    print(f"\nProcessing single: {img_path.name}")

    img_array = load_image_rgba(img_path)
    img_clean = remove_checkered_background(img_array)

    # Trim transparent edges
    img = Image.fromarray(img_clean, 'RGBA')
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    img.save(output_path)
    print(f"  Saved: {output_path.name} ({img.width}x{img.height})")

def main():
    print("=" * 50)
    print("IMPROVED SPRITE CROPPING v2")
    print("=" * 50)

    # Ensure directories exist
    for subdir in ["obstacles/road", "obstacles/soccer", "obstacles/beach",
                   "obstacles/underwater", "obstacles/volcano",
                   "powerups", "shoes", "ui", "worlds"]:
        (ASSETS_DIR / subdir).mkdir(parents=True, exist_ok=True)

    # === UI ICONS ===
    # The UI image has: soccer ball (ref), coin, star filled, star empty, pause, gear
    # We only want: coin, star_filled, star_empty, pause, settings
    ui_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_54_26 PM.png"
    if ui_img.exists():
        process_sprite_sheet(ui_img, ASSETS_DIR / "ui",
            ["_skip", "coin", "star_filled", "star_empty", "pause", "settings"],
            expected_count=6)
        # Remove the skip file
        skip_file = ASSETS_DIR / "ui" / "_skip.png"
        if skip_file.exists():
            skip_file.unlink()

    # === SHOE ICONS ===
    shoes_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_30_07 PM.png"
    if shoes_img.exists():
        process_sprite_sheet(shoes_img, ASSETS_DIR / "shoes",
            ["barefoot", "flip_flops", "running_shoes", "winged_shoes"],
            expected_count=4)

    # === WORLD ICONS ===
    worlds_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_18_23 PM.png"
    if worlds_img.exists():
        process_sprite_sheet(worlds_img, ASSETS_DIR / "worlds",
            ["world_meadow", "world_road", "world_soccer", "world_underwater", "world_volcano"],
            expected_count=5)

    # Beach world (single image)
    beach_world_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_36_16 PM.png"
    if beach_world_img.exists():
        process_single_image(beach_world_img, ASSETS_DIR / "worlds" / "world_beach.png")

    # === ROAD OBSTACLES ===
    road_img1 = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_34_06 PM.png"
    if road_img1.exists():
        process_sprite_sheet(road_img1, ASSETS_DIR / "obstacles" / "road",
            ["cone", "pothole", "manhole", "barrier"],
            expected_count=4)

    road_img2 = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_22_30 PM.png"
    if road_img2.exists():
        process_sprite_sheet(road_img2, ASSETS_DIR / "obstacles" / "road",
            ["spikes", "crate", "pillar", "warning_sign"],
            expected_count=4)

    # === SOCCER OBSTACLES ===
    soccer_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_51_40 PM.png"
    if soccer_img.exists():
        process_sprite_sheet(soccer_img, ASSETS_DIR / "obstacles" / "soccer",
            ["soccer_ball", "training_cone", "tackle_dummy", "goal_post"],
            expected_count=4)

    # === BEACH OBSTACLES ===
    beach_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_48_26 PM.png"
    if beach_img.exists():
        process_sprite_sheet(beach_img, ASSETS_DIR / "obstacles" / "beach",
            ["beach_ball", "sand_castle", "crab", "surfboard"],
            expected_count=4)

    # === UNDERWATER OBSTACLES ===
    underwater_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_44_07 PM.png"
    if underwater_img.exists():
        process_sprite_sheet(underwater_img, ASSETS_DIR / "obstacles" / "underwater",
            ["jellyfish", "shark_fin", "anchor", "coral"],
            expected_count=4)

    # === VOLCANO OBSTACLES ===
    volcano_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_46_14 PM.png"
    if volcano_img.exists():
        process_sprite_sheet(volcano_img, ASSETS_DIR / "obstacles" / "volcano",
            ["meteor", "lava_geyser", "obsidian_spike", "fire_bat"],
            expected_count=4)

    # === POWER-UPS ===
    powerups_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_23_44 PM.png"
    if powerups_img.exists():
        process_sprite_sheet(powerups_img, ASSETS_DIR / "powerups",
            ["shield", "magnet", "speed_bolt"],
            expected_count=3)

    # === APP ICON ===
    # Don't process - keep original with background
    app_icon_img = DOWNLOADS / "ChatGPT Image Jan 29, 2026, 02_58_52 PM.png"
    if app_icon_img.exists():
        img = Image.open(app_icon_img)
        img_resized = img.resize((1024, 1024), Image.Resampling.LANCZOS)
        img_resized.save(ASSETS_DIR.parent / "icon.png")
        print(f"\n  Saved: icon.png (1024x1024)")

    print("\n" + "=" * 50)
    print("CROPPING COMPLETE")
    print("=" * 50)

if __name__ == "__main__":
    main()
