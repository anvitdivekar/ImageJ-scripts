// ============================================================
// Scratch Assay - Single Image Preview (no save)
// Plates 1 & 2
// Jo Lab / Dr. Clark
// ============================================================
// --- EDIT THESE THREE VARIABLES ---
var plate     = "1";        // "1" or "2"
var timepoint = "12hr";     // Plate 1: "12hr", "24hr_01", "36hr", "72hr", "108hr", "132hr"
                            // Plate 2: "12hr_01", "24hr_02", "36hr", "72hr", "108hr", "132hr"
var xy        = "01";       // "01" through "24"
// ============================================================
var baseDir  = "Y:\\jo-lab\\michaelclark\\data\\microscopy\\20260603_candidate_scratch_1\\";
var xyFolder = "XY" + xy;
var imgPath  = baseDir + "plate" + plate + "_" + timepoint + "\\" + xyFolder + "\\Imageq_" + xyFolder + "_CH4.tif";
if (!File.exists(imgPath)) {
    exit("Image not found:\n" + imgPath);
}
open(imgPath);
rename("Original");
run("Duplicate...", "title=Processed");
selectWindow("Processed");
run("Variance...", "radius=2");
setThreshold(25, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Fill Holes");
run("Set Measurements...", "area mean min area_fraction redirect=None decimal=3");
run("Measure");
var confluence = getResult("%Area", nResults - 1);
run("Clear Results");
selectWindow("Original");
selectWindow("Processed");
run("Tile");
Dialog.create("Confluence Result");
Dialog.addMessage("Plate: " + plate);
Dialog.addMessage("Timepoint: " + timepoint + " hr");
Dialog.addMessage("XY: " + xyFolder);
Dialog.addMessage("Confluence: " + confluence + "%");
Dialog.show();
