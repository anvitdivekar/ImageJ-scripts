// ============================================================
// SCRATCH ASSAY - DEBUG VERSION (all 3 timepoints, XY04)
// Prints density profile + front detection comparison per image
// ============================================================

// --- USER-CONFIGURABLE VARIABLES ---
basePath = "Y:\\jo-lab\\anvitdivekar\\20260727_candidate_scratch_primary\\FRYL_i\\";
condition = "FRYL_i";
xyPosition = 4;
channel = "CH4";

timepoints = newArray("t0hr", "t24hr", "t48hr");

sliceSize = 0.05;
minDensityThreshold = 20;
particleSizeMin = 10;
particleSizeMax = 200;
circularityMin = 0.3;
bgSigma = 30;
minMigrationDistance = 0.2;

// ============================================================
xyString = "" + xyPosition;
if (xyPosition < 10) {
    xyString = "0" + xyString;
}

for (t = 0; t < timepoints.length; t++) {
    tp = timepoints[t];
    filePath = basePath + condition + "_" + tp + "\\XY" + xyString + "\\Imageq_XY" + xyString + "_" + channel + ".tif";

    if (!File.exists(filePath)) {
        print("WARNING: File not found, skipping: " + filePath);
        continue;
    }

    open(filePath);
    originalImg = getTitle();

    run("Duplicate...", "title=processing");
    selectWindow("processing");

    run("Duplicate...", "title=background");
    run("Gaussian Blur...", "sigma=" + bgSigma);
    selectWindow("processing");
    imageCalculator("Subtract", "processing", "background");
    close("background");

    run("Enhance Contrast...", "saturated=0.35 normalize");

    run("8-bit");
    setAutoThreshold("Triangle dark");
    run("Convert to Mask");

    run("Open", "");

    run("Set Measurements...", "area centroid redirect=None decimal=3");
    run("Analyze Particles...", "size=" + particleSizeMin + "-" + particleSizeMax +
        " circularity=" + circularityMin + "-1.00 pixel display clear");

    if (nResults == 0) {
        print("No particles detected for " + originalImg + ". Skipping.");
        selectWindow("processing");
        close();
        close(originalImg);
        continue;
    }

    yValues = newArray(nResults);
    for (i = 0; i < nResults; i++) {
        yValues[i] = getResult("Y", i);
    }
    yValuesSorted = Array.copy(yValues);
    Array.sort(yValuesSorted);

    minY = yValuesSorted[0];
    maxY = yValuesSorted[nResults - 1];

    numSlices = Math.ceil((maxY - minY) / sliceSize);
    sliceStarts = newArray(numSlices);
    sliceCounts = newArray(numSlices);

    for (s = 0; s < numSlices; s++) {
        sliceStarts[s] = minY + (s * sliceSize);
        sliceCounts[s] = 0;
    }

    for (i = 0; i < nResults; i++) {
        y = getResult("Y", i);
        sliceIndex = floor((y - minY) / sliceSize);
        if (sliceIndex >= 0 && sliceIndex < numSlices) {
            sliceCounts[sliceIndex] = sliceCounts[sliceIndex] + 1;
        }
    }

    // --- PRINT FULL DENSITY PROFILE TO LOG ---
    print("============================================================");
    print("DENSITY PROFILE FOR: " + tp + " (XY" + xyString + ")");
    print("Total particles: " + nResults);
    print("minY=" + minY + "  maxY=" + maxY + "  numSlices=" + numSlices);
    print("------------------------------------------------------------");
    print("SliceIndex\tY_position\tCellCount");
    for (s = 0; s < numSlices; s++) {
        print(s + "\t" + sliceStarts[s] + "\t" + sliceCounts[s]);
    }
    print("============================================================");

    // TOP-DOWN logic
    topDownIndex = -1;
    for (s = numSlices - 1; s >= 0; s--) {
        distanceFromEdge = sliceStarts[s] - minY;
        if (sliceCounts[s] >= minDensityThreshold && distanceFromEdge >= minMigrationDistance) {
            topDownIndex = s;
            s = -1;
        }
    }
    if (topDownIndex == -1) {
        fallbackIndex = Math.ceil(minMigrationDistance / sliceSize);
        if (fallbackIndex >= numSlices) fallbackIndex = numSlices - 1;
        topDownIndex = fallbackIndex;
    }

    // BOTTOM-UP logic
    bottomUpIndex = -1;
    for (s = 0; s < numSlices; s++) {
        distanceFromTop = sliceStarts[s] - minY;
        if (sliceCounts[s] >= minDensityThreshold && distanceFromTop >= minMigrationDistance) {
            bottomUpIndex = s;
            s = numSlices;
        }
    }
    if (bottomUpIndex == -1) {
        fallbackIndex = numSlices - 1 - Math.ceil(minMigrationDistance / sliceSize);
        if (fallbackIndex < 0) fallbackIndex = 0;
        bottomUpIndex = fallbackIndex;
    }

    print("RESULT for " + tp + ":");
    print("  TOP-DOWN logic would pick:    index=" + topDownIndex + "  Y=" + sliceStarts[topDownIndex] + "  count=" + sliceCounts[topDownIndex]);
    print("  BOTTOM-UP logic would pick:   index=" + bottomUpIndex + "  Y=" + sliceStarts[bottomUpIndex] + "  count=" + sliceCounts[bottomUpIndex]);
    print("============================================================");

    selectWindow("processing");
    close();
    close(originalImg);
}

print("DEBUG RUN COMPLETE FOR XY" + xyString);
