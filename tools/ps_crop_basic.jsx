/*
 * BASIC Photoshop Sprite Cropper
 * Processes current open document
 *
 * HOW TO USE:
 * 1. Open a sprite sheet image in Photoshop
 * 2. Run this script (File > Scripts > Browse)
 * 3. Enter number of columns when prompted
 * 4. Enter output folder name when prompted
 * 5. Enter sprite names (comma separated) when prompted
 */

#target photoshop

if (app.documents.length == 0) {
    alert("Please open a sprite sheet image first!");
} else {
    main();
}

function main() {
    var doc = app.activeDocument;

    // Get user input
    var cols = parseInt(prompt("How many sprites (columns)?", "4"));
    if (isNaN(cols) || cols < 1) {
        alert("Invalid number");
        return;
    }

    var folderName = prompt("Output folder name (e.g., 'ui' or 'shoes'):", "sprites");
    var namesStr = prompt("Sprite names (comma separated):", "sprite1,sprite2,sprite3,sprite4");
    var names = namesStr.split(",");

    // Setup
    app.preferences.rulerUnits = Units.PIXELS;

    // Unlock background
    try {
        doc.activeLayer.isBackgroundLayer = false;
        doc.activeLayer.name = "Layer 0";
    } catch(e) {}

    // Remove background - select white/gray at corner and delete
    try {
        // Magic wand at top-left
        selectColorAtPoint(5, 5, 30);
        doc.selection.similar(25, false);
        doc.selection.clear();
        doc.selection.deselect();
    } catch(e) {
        alert("Background removal skipped: " + e.message);
    }

    // Calculate dimensions
    var w = doc.width.value;
    var h = doc.height.value;
    var spriteW = Math.floor(w / cols);

    // Output folder
    var outputBase = Folder("C:/Users/zrina/OneDrive/Documents/wORK/App/Sidestep/sidestep_v2.5.2/sidestep/assets/sprites");
    var outFolder = new Folder(outputBase + "/" + folderName);
    if (!outFolder.exists) outFolder.create();

    // Extract sprites
    for (var i = 0; i < cols && i < names.length; i++) {
        var name = names[i].replace(/^\s+|\s+$/g, ''); // trim
        if (name == "" || name == "skip") continue;

        var x1 = i * spriteW;
        var x2 = x1 + spriteW;

        // Select region
        doc.selection.select([[x1, 0], [x2, 0], [x2, h], [x1, h]]);
        doc.selection.copy();

        // Create new doc
        var newDoc = app.documents.add(spriteW, h, 72, name, NewDocumentMode.RGB, DocumentFill.TRANSPARENT);
        newDoc.paste();

        // Flatten but keep transparency
        newDoc.mergeVisibleLayers();

        // Trim transparent edges
        try {
            newDoc.trim(TrimType.TRANSPARENT, true, true, true, true);
        } catch(e) {}

        // Save as PNG
        var outFile = new File(outFolder + "/" + name + ".png");
        var opts = new PNGSaveOptions();
        opts.compression = 6;
        newDoc.saveAs(outFile, opts, true);

        newDoc.close(SaveOptions.DONOTSAVECHANGES);
    }

    alert("Done! Saved " + names.length + " sprites to:\n" + outFolder.fsName);
}

function selectColorAtPoint(x, y, tolerance) {
    var desc = new ActionDescriptor();
    var ref = new ActionReference();
    ref.putProperty(charIDToTypeID("Chnl"), charIDToTypeID("fsel"));
    desc.putReference(charIDToTypeID("null"), ref);

    var posDesc = new ActionDescriptor();
    posDesc.putUnitDouble(charIDToTypeID("Hrzn"), charIDToTypeID("#Pxl"), x);
    posDesc.putUnitDouble(charIDToTypeID("Vrtc"), charIDToTypeID("#Pxl"), y);
    desc.putObject(charIDToTypeID("T   "), charIDToTypeID("Pnt "), posDesc);

    desc.putInteger(charIDToTypeID("Tlrn"), tolerance);
    desc.putBoolean(charIDToTypeID("AntA"), false);

    executeAction(charIDToTypeID("setd"), desc, DialogModes.NO);
}
