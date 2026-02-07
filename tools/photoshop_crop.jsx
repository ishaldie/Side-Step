/*
 * Photoshop Sprite Cropping Script
 * Removes checkered backgrounds and crops individual sprites
 */

#target photoshop

// Configuration
var DOWNLOADS = "C:/Users/zrina/Downloads/";
var OUTPUT_BASE = "C:/Users/zrina/OneDrive/Documents/wORK/App/Sidestep/sidestep_v2.5.2/sidestep/assets/sprites/";

// Sprite sheet definitions: [filename, outputFolder, spriteNames, columns]
var SPRITE_SHEETS = [
    // UI Icons (skip first soccer ball reference)
    ["ChatGPT Image Jan 29, 2026, 02_54_26 PM.png", "ui/", ["_skip", "coin", "star_filled", "star_empty", "pause", "settings"], 6],

    // Shoe Icons
    ["ChatGPT Image Jan 29, 2026, 02_30_07 PM.png", "shoes/", ["barefoot", "flip_flops", "running_shoes", "winged_shoes"], 4],

    // World Icons
    ["ChatGPT Image Jan 29, 2026, 02_18_23 PM.png", "worlds/", ["world_meadow", "world_road", "world_soccer", "world_underwater", "world_volcano"], 5],

    // Road Obstacles 1
    ["ChatGPT Image Jan 29, 2026, 02_34_06 PM.png", "obstacles/road/", ["cone", "pothole", "manhole", "barrier"], 4],

    // Road Obstacles 2
    ["ChatGPT Image Jan 29, 2026, 02_22_30 PM.png", "obstacles/road/", ["spikes", "crate", "pillar", "warning_sign"], 4],

    // Soccer Obstacles
    ["ChatGPT Image Jan 29, 2026, 02_51_40 PM.png", "obstacles/soccer/", ["soccer_ball", "training_cone", "tackle_dummy", "goal_post"], 4],

    // Beach Obstacles
    ["ChatGPT Image Jan 29, 2026, 02_48_26 PM.png", "obstacles/beach/", ["beach_ball", "sand_castle", "crab", "surfboard"], 4],

    // Underwater Obstacles
    ["ChatGPT Image Jan 29, 2026, 02_44_07 PM.png", "obstacles/underwater/", ["jellyfish", "shark_fin", "anchor", "coral"], 4],

    // Volcano Obstacles
    ["ChatGPT Image Jan 29, 2026, 02_46_14 PM.png", "obstacles/volcano/", ["meteor", "lava_geyser", "obsidian_spike", "fire_bat"], 4],

    // Power-ups
    ["ChatGPT Image Jan 29, 2026, 02_23_44 PM.png", "powerups/", ["shield", "magnet", "speed_bolt"], 3]
];

// Single images (just remove background)
var SINGLE_IMAGES = [
    ["ChatGPT Image Jan 29, 2026, 02_36_16 PM.png", "worlds/", "world_beach"]
];

function main() {
    // Set units to pixels
    var originalUnits = app.preferences.rulerUnits;
    app.preferences.rulerUnits = Units.PIXELS;

    try {
        // Process sprite sheets
        for (var i = 0; i < SPRITE_SHEETS.length; i++) {
            var sheet = SPRITE_SHEETS[i];
            processSpriteSheet(sheet[0], sheet[1], sheet[2], sheet[3]);
        }

        // Process single images
        for (var j = 0; j < SINGLE_IMAGES.length; j++) {
            var single = SINGLE_IMAGES[j];
            processSingleImage(single[0], single[1], single[2]);
        }

        alert("Sprite cropping complete!");

    } catch (e) {
        alert("Error: " + e.message);
    } finally {
        app.preferences.rulerUnits = originalUnits;
    }
}

function processSpriteSheet(filename, outputFolder, spriteNames, columns) {
    var filePath = new File(DOWNLOADS + filename);

    if (!filePath.exists) {
        alert("File not found: " + filename);
        return;
    }

    // Open the file
    var doc = app.open(filePath);

    // Remove checkered background
    removeCheckeredBackground(doc);

    // Calculate sprite dimensions
    var spriteWidth = Math.floor(doc.width / columns);
    var spriteHeight = doc.height;

    // Ensure output folder exists
    var outputDir = new Folder(OUTPUT_BASE + outputFolder);
    if (!outputDir.exists) {
        outputDir.create();
    }

    // Extract each sprite
    for (var i = 0; i < spriteNames.length && i < columns; i++) {
        var spriteName = spriteNames[i];

        if (spriteName === "_skip") continue;

        // Select the sprite region
        var left = i * spriteWidth;
        var top = 0;
        var right = left + spriteWidth;
        var bottom = spriteHeight;

        // Create selection
        doc.selection.select([
            [left, top],
            [right, top],
            [right, bottom],
            [left, bottom]
        ]);

        // Copy and create new document
        doc.selection.copy();

        var spriteDoc = app.documents.add(spriteWidth, spriteHeight, 72, spriteName, NewDocumentMode.RGB, DocumentFill.TRANSPARENT);
        spriteDoc.paste();

        // Trim transparent pixels
        spriteDoc.trim(TrimType.TRANSPARENT, true, true, true, true);

        // Save as PNG
        var saveFile = new File(OUTPUT_BASE + outputFolder + spriteName + ".png");
        savePNG(spriteDoc, saveFile);

        // Close sprite document
        spriteDoc.close(SaveOptions.DONOTSAVECHANGES);
    }

    // Close original document
    doc.close(SaveOptions.DONOTSAVECHANGES);
}

function processSingleImage(filename, outputFolder, spriteName) {
    var filePath = new File(DOWNLOADS + filename);

    if (!filePath.exists) {
        alert("File not found: " + filename);
        return;
    }

    // Open the file
    var doc = app.open(filePath);

    // Remove checkered background
    removeCheckeredBackground(doc);

    // Trim transparent pixels
    doc.trim(TrimType.TRANSPARENT, true, true, true, true);

    // Ensure output folder exists
    var outputDir = new Folder(OUTPUT_BASE + outputFolder);
    if (!outputDir.exists) {
        outputDir.create();
    }

    // Save as PNG
    var saveFile = new File(OUTPUT_BASE + outputFolder + spriteName + ".png");
    savePNG(doc, saveFile);

    // Close document
    doc.close(SaveOptions.DONOTSAVECHANGES);
}

function removeCheckeredBackground(doc) {
    // Convert background to layer if needed
    try {
        doc.activeLayer.isBackgroundLayer = false;
    } catch (e) {
        // Already a regular layer
    }

    // Method 1: Use Color Range to select light gray (checkered pattern color ~204)
    // Select the light gray color of the checkered pattern
    var lightGray = new SolidColor();
    lightGray.rgb.red = 204;
    lightGray.rgb.green = 204;
    lightGray.rgb.blue = 204;

    try {
        // Select by color range - light gray
        selectByColorRange(doc, 204, 204, 204, 20);

        // Also add white to selection
        doc.selection.similar(32, false);

        // Expand selection slightly to catch anti-aliased edges
        doc.selection.expand(1);

        // Delete selected pixels
        doc.selection.clear();
        doc.selection.deselect();

    } catch (e) {
        // If color range fails, try magic wand on corners
        magicWandCorners(doc);
    }
}

function selectByColorRange(doc, r, g, b, tolerance) {
    // Use Color Range via action descriptor
    var desc = new ActionDescriptor();
    var ref = new ActionReference();
    ref.putProperty(charIDToTypeID("Chnl"), charIDToTypeID("fsel"));
    desc.putReference(charIDToTypeID("null"), ref);

    var colorDesc = new ActionDescriptor();
    colorDesc.putDouble(charIDToTypeID("Rd  "), r);
    colorDesc.putDouble(charIDToTypeID("Grn "), g);
    colorDesc.putDouble(charIDToTypeID("Bl  "), b);

    desc.putObject(charIDToTypeID("Clr "), charIDToTypeID("RGBC"), colorDesc);
    desc.putInteger(charIDToTypeID("Tlrn"), tolerance);

    executeAction(charIDToTypeID("setd"), desc, DialogModes.NO);
}

function magicWandCorners(doc) {
    // Use magic wand on corners to select background
    var magicWandTolerance = 32;

    // Select top-left corner
    doc.selection.select([[0,0], [1,0], [1,1], [0,1]]);

    // Use magic wand
    var desc = new ActionDescriptor();
    desc.putInteger(charIDToTypeID("Tlrn"), magicWandTolerance);
    desc.putBoolean(charIDToTypeID("AntA"), true);
    desc.putBoolean(charIDToTypeID("Cntg"), false); // Non-contiguous to get all similar colors

    var ref = new ActionReference();
    ref.putProperty(charIDToTypeID("Chnl"), charIDToTypeID("fsel"));
    desc.putReference(charIDToTypeID("null"), ref);

    var pointDesc = new ActionDescriptor();
    pointDesc.putUnitDouble(charIDToTypeID("Hrzn"), charIDToTypeID("#Pxl"), 5);
    pointDesc.putUnitDouble(charIDToTypeID("Vrtc"), charIDToTypeID("#Pxl"), 5);
    desc.putObject(charIDToTypeID("T   "), charIDToTypeID("Pnt "), pointDesc);

    try {
        executeAction(charIDToTypeID("setd"), desc, DialogModes.NO);
        doc.selection.similar(32, false);
        doc.selection.clear();
    } catch (e) {
        // Ignore errors
    }

    doc.selection.deselect();
}

function savePNG(doc, file) {
    var pngOptions = new PNGSaveOptions();
    pngOptions.compression = 6;
    pngOptions.interlaced = false;

    doc.saveAs(file, pngOptions, true, Extension.LOWERCASE);
}

// Run the script
main();
