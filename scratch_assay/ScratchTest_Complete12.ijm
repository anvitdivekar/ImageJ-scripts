// ============================================================
// Scratch Assay Confluence Quantification
// Plates 1 & 2 – Complete Media
// Jo Lab / Dr. Clark
// ============================================================

// --- Output setup ---
var baseDir = "Y:\\jo-lab\\michaelclark\\data\\microscopy\\20260603_candidate_scratch_1\\";
var outDir = baseDir + "results\\";
File.makeDirectory(outDir);
var outFile = outDir + "scratch_confluence_results_plates1_2.csv";
var f = File.open(outFile);
print(f, "Plate,Condition,Well,XY,Timepoint_hr,Confluence_pct");

// --- Plate 1 config (same layout as Plate 3) ---
var p1folders = newArray("plate1_12hr", "plate1_24hr_01", "plate1_36hr", "plate1_72hr", "plate1_108hr", "plate1_132hr");
var p1times   = newArray("12", "24", "36", "72", "108", "132");
var p1wells      = newArray("A1","A2","A3","A4","B1","B2","B3","B4","C1","C2","C3","C4");
var p1conditions = newArray("NT","EMPTY","ST","EMPTY","PLXNA2","PLXNKO","FRYL","ART4_i","ART4_o","GPRC5A","GPR162","CDH13");

// --- Plate 2 config (same layout as Plate 4) ---
var p2folders = newArray("plate2_12hr_01", "plate2_24hr_02", "plate2_36hr", "plate2_72hr", "plate2_108hr", "plate2_132hr");
var p2times   = newArray("12", "24", "36", "72", "108", "132");
var p2wells      = newArray("A1","A2","A3","A4","B1","B2","B3","B4","C1","C2","C3","C4");
var p2conditions = newArray("SLC44A2","SLC9A3R2","HEG1","MMRN2","CLEC14A","SEMA3C","SEMA6B","TNS1_OLD","GPRC5A_OLD","CDH13_OLD","GPRC135_OLD","EMPTY");

// ============================================================
// PROCESS PLATE 1
// ============================================================
for (var ti = 0; ti < p1folders.length; ti++) {
    var tpFolder = p1folders[ti];
    var tpHr     = p1times[ti];
    for (var xy = 1; xy <= 24; xy++) {
        var xyStr    = IJ.pad(xy, 2);
        var xyFolder = "XY" + xyStr;
        var imgPath  = baseDir + tpFolder + "\\" + xyFolder + "\\Imageq_" + xyFolder + "_CH4.tif";
        if (!File.exists(imgPath)) {
            print("MISSING: " + imgPath);
            continue;
        }
        var wellIdx   = Math.floor((xy - 1) / 2);
        var well      = p1wells[wellIdx];
        var condition = p1conditions[wellIdx];
        open(imgPath);
        run("Variance...", "radius=2");
        setThreshold(25, 255);
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Fill Holes");
        run("Set Measurements...", "area mean min area_fraction redirect=None decimal=3");
        run("Measure");
        var confluence = getResult("%Area", nResults - 1);
        print(f, "1," + condition + "," + well + "," + xyFolder + "," + tpHr + "," + confluence);
        close();
        run("Clear Results");
    }
}

// ============================================================
// PROCESS PLATE 2
// ============================================================
for (var ti = 0; ti < p2folders.length; ti++) {
    var tpFolder = p2folders[ti];
    var tpHr     = p2times[ti];
    for (var xy = 1; xy <= 24; xy++) {
        var xyStr    = IJ.pad(xy, 2);
        var xyFolder = "XY" + xyStr;
        var imgPath  = baseDir + tpFolder + "\\" + xyFolder + "\\Imageq_" + xyFolder + "_CH4.tif";
        if (!File.exists(imgPath)) {
            print("MISSING: " + imgPath);
            continue;
        }
        var wellIdx   = Math.floor((xy - 1) / 2);
        var well      = p2wells[wellIdx];
        var condition = p2conditions[wellIdx];
        open(imgPath);
        run("Variance...", "radius=2");
        setThreshold(25, 255);
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Fill Holes");
        run("Set Measurements...", "area mean min area_fraction redirect=None decimal=3");
        run("Measure");
        var confluence = getResult("%Area", nResults - 1);
        print(f, "2," + condition + "," + well + "," + xyFolder + "," + tpHr + "," + confluence);
        close();
        run("Clear Results");
    }
}

// ============================================================
File.close(f);
print("Done. Results saved to: " + outFile);
