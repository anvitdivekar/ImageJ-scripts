// ============================================================
// Scratch Assay - Timepoint Viewer (display only)
// Jo Lab / Dr. Clark
// ============================================================

// --- EDIT THESE TWO VARIABLES ---
var activePlate = "1";      // "1", "2", "3", or "4"
var xy          = "06";     // "01" through "24"

var folders;

if (activePlate == "1") {
    folders = newArray("plate1_12hr", "plate1_24hr_01", "plate1_36hr", "plate1_72hr", "plate1_108hr", "plate1_132hr");
} else if (activePlate == "2") {
    folders = newArray("plate2_12hr_01", "plate2_24hr_02", "plate2_36hr", "plate2_72hr", "plate2_108hr", "plate2_132hr");
} else if (activePlate == "3") {
    folders = newArray("plate3_0hr", "plate3_24hr_01", "plate3_60hr", "plate3_96hr", "plate3_120hr");
} else if (activePlate == "4") {
    folders = newArray("plate4_0hr", "plate4_24hr", "plate4_60hr", "plate4_96hr", "plate4_120hr");
} else {
    exit("Invalid plate: " + activePlate + ". Must be 1, 2, 3, or 4.");
}

var baseDir  = "Y:\\jo-lab\\michaelclark\\data\\microscopy\\20260603_candidate_scratch_1\\";
var xyFolder = "XY" + xy;

for (var ti = 0; ti < folders.length; ti++) {
    var imgPath = baseDir + folders[ti] + "\\" + xyFolder + "\\Imageq_" + xyFolder + "_CH4.tif";
    if (!File.exists(imgPath)) {
        print("MISSING: " + imgPath);
        continue;
    }
    open(imgPath);
    rename(folders[ti]);
}

run("Tile");
