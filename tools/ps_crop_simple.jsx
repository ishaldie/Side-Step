/*
 * Simple Photoshop Sprite Cropper
 * Run this script in Photoshop: File > Scripts > Browse
 */

#target photoshop

app.preferences.rulerUnits = Units.PIXELS;

var inputFolder = Folder("C:/Users/zrina/Downloads");
var outputBase = Folder("C:/Users/zrina/OneDrive/Documents/wORK/App/Sidestep/sidestep_v2.5.2/sidestep/assets/sprites");

// Process each sprite sheet one at a time
var jobs = [
    {
        file: "ChatGPT Image Jan 29, 2026, 02_54_26 PM.png",
        output: "ui",
        names: ["skip", "coin", "star_filled", "star_empty", "pause", "settings"],
        cols: 6
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_30_07 PM.png",
        output: "shoes",
        names: ["barefoot", "flip_flops", "running_shoes", "winged_shoes"],
        cols: 4
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_18_23 PM.png",
        output: "worlds",
        names: ["world_meadow", "world_road", "world_soccer", "world_underwater", "world_volcano"],
        cols: 5
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_34_06 PM.png",
        output: "obstacles/road",
        names: ["cone", "pothole", "manhole", "barrier"],
        cols: 4
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_22_30 PM.png",
        output: "obstacles/road",
        names: ["spikes", "crate", "pillar", "warning_sign"],
        cols: 4
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_51_40 PM.png",
        output: "obstacles/soccer",
        names: ["soccer_ball", "training_cone", "tackle_dummy", "goal_post"],
        cols: 4
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_48_26 PM.png",
        output: "obstacles/beach",
        names: ["beach_ball", "sand_castle", "crab", "surfboard"],
        cols: 4
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_44_07 PM.png",
        output: "obstacles/underwater",
        names: ["jellyfish", "shark_fin", "anchor", "coral"],
        cols: 4
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_46_14 PM.png",
        output: "obstacles/volcano",
        names: ["meteor", "lava_geyser", "obsidian_spike", "fire_bat"],
        cols: 4
    },
    {
        file: "ChatGPT Image Jan 29, 2026, 02_23_44 PM.png",
        output: "powerups",
        names: ["shield", "magnet", "speed_bolt"],
        cols: 3
    }
];

function processJob(job) {
    var srcFile = new File(inputFolder + "/" + job.file);

    if (!srcFile.exists) {
        alert("File not found: " + job.file);
        return;
    }

    var doc = app.open(srcFile);

    // Unlock background layer
    try {
        doc.activeLayer.isBackgroundLayer = false;
    } catch(e) {}

    // Remove checkered background using magic wand
    removeBackground(doc);

    var w = doc.width.value;
    var h = doc.height.value;
    var spriteW = Math.floor(w / job.cols);

    // Create output folder
    var outFolder = new Folder(outputBase + "/" + job.output);
    if (!outFolder.exists) outFolder.create();

    // Extract each sprite
    for (var i = 0; i < job.names.length; i++) {
        if (job.names[i] == "skip") continue;

        var x1 = i * spriteW;
        var x2 = x1 + spriteW;

        // Select region
        doc.selection.select([[x1, 0], [x2, 0], [x2, h], [x1, h]]);
        doc.selection.copy();

        // New document
        var newDoc = app.documents.add(spriteW, h, 72, job.names[i], NewDocumentMode.RGB, DocumentFill.TRANSPARENT);
        newDoc.paste();
        newDoc.flatten();

        // Convert to have transparency
        try {
            newDoc.activeLayer.isBackgroundLayer = false;
        } catch(e) {}

        // Trim
        newDoc.trim(TrimType.TRANSPARENT, true, true, true, true);

        // Save
        var outFile = new File(outFolder + "/" + job.names[i] + ".png");
        var pngOpts = new PNGSaveOptions();
        pngOpts.compression = 6;
        newDoc.saveAs(outFile, pngOpts, true);

        newDoc.close(SaveOptions.DONOTSAVECHANGES);
    }

    doc.close(SaveOptions.DONOTSAVECHANGES);
}

function removeBackground(doc) {
    // Select white/light gray using Color Range
    try {
        // Magic wand at corner with tolerance
        var x = 5;
        var y = 5;

        // Use action to select by color
        var idsetd = charIDToTypeID("setd");
        var desc = new ActionDescriptor();
        var idnull = charIDToTypeID("null");
        var ref = new ActionReference();
        var idChnl = charIDToTypeID("Chnl");
        var idfsel = charIDToTypeID("fsel");
        ref.putProperty(idChnl, idfsel);
        desc.putReference(idnull, ref);

        var idT = charIDToTypeID("T   ");
        var desc2 = new ActionDescriptor();
        var idHrzn = charIDToTypeID("Hrzn");
        var idPxl = charIDToTypeID("#Pxl");
        desc2.putUnitDouble(idHrzn, idPxl, x);
        var idVrtc = charIDToTypeID("Vrtc");
        desc2.putUnitDouble(idVrtc, idPxl, y);
        var idPnt = charIDToTypeID("Pnt ");
        desc.putObject(idT, idPnt, desc2);

        var idTlrn = charIDToTypeID("Tlrn");
        desc.putInteger(idTlrn, 32);
        var idAntA = charIDToTypeID("AntA");
        desc.putBoolean(idAntA, false);

        executeAction(idsetd, desc, DialogModes.NO);

        // Grow selection to catch similar colors
        doc.selection.similar(20, false);

        // Delete background
        doc.selection.clear();
        doc.selection.deselect();

    } catch(e) {
        // If magic wand fails, continue without removing background
    }
}

// Main
var count = 0;
for (var j = 0; j < jobs.length; j++) {
    try {
        processJob(jobs[j]);
        count++;
    } catch(e) {
        alert("Error processing " + jobs[j].file + ": " + e.message);
    }
}

alert("Done! Processed " + count + " sprite sheets.");
