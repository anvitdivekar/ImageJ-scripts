// ============================================================
// Scratch Assay Confluence Quantification
// Plates 3 & 4 – Complete Media
// Jo Lab / Dr. Clark
// ============================================================

// --- Output setup ---
var baseDir = "Y:\\jo-lab\\michaelclark\\data\\microscopy\\20260603_candidate_scratch_1\\";
var outDir = baseDir + "results\\";
File.makeDirectory(outDir);
var outFile = outDir + "scratch_confluence_results.csv";

var f = File.open(outFile);
print(f, "Plate,Condition,Well,XY,Timepoint_hr,Confluence_pct");

// --- Plate 3 config ---
var p3folders = newArray("plate3_0hr", "plate3_24hr_01", "plate3_60hr", "plate3_96hr", "plate3_120hr");
var p3times   = newArray("0", "24", "60", "96", "120");

var p3wells      = newArray("A1","A2","A3","A4","B1","B2","B3","B4","C1","C2","C3","C4");
var p3conditions = newArray("NT","EMPTY","ST","EMPTY","PLXNA2","PLXNKO","FRYL","ART4_i","ART4_o","GPRC5A","GPR162","CDH13");

// --- Plate 4 config ---
var p4folders = newArray("plate4_0hr", "plate4_24hr", "plate4_60hr", "plate4_96hr", "plate4_120hr");
var p4times   = newArray("0", "24", "60", "96", "120");

var p4wells      = newArray("A1","A2","A3","A4","B1","B2","B3","B4","C1","C2","C3","C4");
var p4conditions = newArray("SLC44A2","SLC9A3R2","HEG1","MMRN2","CLEC14A","SEMA3C","SEMA6B","TNS1_OLD","GPRC5A_OLD","CDH13_OLD","GPRC135_OLD","EMPTY");

// ============================================================
// PROCESS PLATE 3
// ============================================================
for (var ti = 0; ti < p3folders.length; ti++) {
    var tpFolder = p3folders[ti];
    var tpHr     = p3times[ti];

    for (var xy = 1; xy <= 24; xy++) {
        var xyStr    = IJ.pad(xy, 2);
        var xyFolder = "XY" + xyStr;
        var imgPath  = baseDir + tpFolder + "\\" + xyFolder + "\\Imageq_" + xyFolder + "_CH4.tif";

        if (!File.exists(imgPath)) {
            print("MISSING: " + imgPath);
            continue;
        }

        var wellIdx   = Math.floor((xy - 1) / 2);
        var well      = p3wells[wellIdx];
        var condition = p3conditions[wellIdx];

        open(imgPath);
        run("Variance...", "radius=3");
        setAutoThreshold("Huang dark no-reset");
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Fill Holes");
        run("Open");
        run("Close-");
        run("Set Measurements...", "area mean min area_fraction redirect=None decimal=3");
        run("Measure");

        var confluence = getResult("%Area", nResults - 1);
        print(f, "3," + condition + "," + well + "," + xyFolder + "," + tpHr + "," + confluence);

        close();
        run("Clear Results");
    }
}

// ============================================================
// PROCESS PLATE 4
// ============================================================
for (var ti = 0; ti < p4folders.length; ti++) {
    var tpFolder = p4folders[ti];
    var tpHr     = p4times[ti];

    for (var xy = 1; xy <= 24; xy++) {
        var xyStr    = IJ.pad(xy, 2);
        var xyFolder = "XY" + xyStr;
        var imgPath  = baseDir + tpFolder + "\\" + xyFolder + "\\Imageq_" + xyFolder + "_CH4.tif";

        if (!File.exists(imgPath)) {
            print("MISSING: " + imgPath);
            continue;
        }

        var wellIdx   = Math.floor((xy - 1) / 2);
        var well      = p4wells[wellIdx];
        var condition = p4conditions[wellIdx];

        open(imgPath);
        run("Variance...", "radius=3");
        setAutoThreshold("Huang dark no-reset");
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Fill Holes");
        run("Open");
        run("Close-");
        run("Set Measurements...", "area mean min area_fraction redirect=None decimal=3");
        run("Measure");

        var confluence = getResult("%Area", nResults - 1);
        print(f, "4," + condition + "," + well + "," + xyFolder + "," + tpHr + "," + confluence);

        close();
        run("Clear Results");
    }
}

// ============================================================
File.close(f);
print("Done. Results saved to: " + outFile);
