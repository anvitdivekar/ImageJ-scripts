// ============================================================
// SCRATCH ASSAY - MULTI-TIMEPOINT MIGRATION FRONT PANEL
// Jo Lab / Anvit Divekar
// Processes t0hr, t24hr, t48hr for one XY position and tiles
// them side-by-side with the red migration front line drawn.
// ============================================================

// --- USER-CONFIGURABLE VARIABLES ---
basePath = "Y:\\jo-lab\\anvitdivekar\\20260727_candidate_scratch_primary\\FRYL_i\\";
condition = "FRYL_i";
xyPosition = 1;             // Change this: 1-36 (will be zero-padded to 01, 02, ... 36)
channel = "CH4";

timepoints = newArray("t0hr", "t24hr", "t48hr");

// --- ANALYSIS VARIABLES (same as single-image pipeline) ---
sliceSize = 0.05;
minDensityThreshold = 20;
particleSizeMin = 10;
particleSizeMax = 200;
circularityMin = 0.3;
bgSigma = 30;
lineWidth = 3;
minMigrationDistance = 0.2;

// --- PANEL LAYOUT VARIABLES ---
panelGap = 10;               // Pixel gap between panels in the tiled output
labelHeight = 30;            // Space reserved above each panel for its label

// ============================================================
// BOUNDS CHECKING
// ============================================================
if (xyPosition < 1 || xyPosition > 36) {
    exit("ERROR: xyPosition must be between 1 and 36. You entered: " + xyPosition);
}

xyString = "" + xyPosition;
if (xyPosition < 10) {
    xyString = "0" + xyString;
}

// ============================================================
// PROCESS EACH TIMEPOINT
// ============================================================
processedTitles = newArray(timepoints.length);
panelWidth = 0;
panelHeight = 0;

for (t = 0; t < timepoints.length; t++) {
    tp = timepoints[t];
    filePath = basePath + condition + "_" + tp + "\\XY" + xyString + "\\Imageq_XY" + xyString + "_" + channel + ".tif";

    if (!File.exists(filePath)) {
        print("WARNING: File not found, skipping: " + filePath);
        continue;
    }

    open(filePath);
    originalImg = getTitle();

    result = processImage(originalImg, sliceSize, minDensityThreshold, particleSizeMin,
                           particleSizeMax, circularityMin, bgSigma, lineWidth, minMigrationDistance);

    annotatedTitle = "panel_" + tp;
    rename(annotatedTitle);
    processedTitles[t] = annotatedTitle;

    panelWidth = getWidth();
    panelHeight = getHeight();

    print("============================================================");
    print("Timepoint: " + tp + " | XY" + xyString);
    print("Migration front Y (micron): " + result);
    print("============================================================");

    // Close leftover windows from this iteration except the annotated panel
    closeIfOpen(originalImg);
    closeIfOpen("processing");
}

// ============================================================
// BUILD COMBINED PANEL CANVAS
// ============================================================
validCount = 0;
for (t = 0; t < processedTitles.length; t++) {
    if (processedTitles[t] != "") validCount++;
}

if (validCount == 0) {
    exit("No images were successfully processed. Check file paths.");
}

canvasWidth = (panelWidth * validCount) + (panelGap * (validCount + 1));
canvasHeight = panelHeight + labelHeight + panelGap;

newImage("Migration_Panel_XY" + xyString, "RGB white", canvasWidth, canvasHeight, 1);
panelCanvas = getTitle();

xOffset = panelGap;
for (t = 0; t < timepoints.length; t++) {
    if (processedTitles[t] == "") continue;

    selectWindow(processedTitles[t]);
    run("Select All");
    run("Copy");

    selectWindow(panelCanvas);
    makeRectangle(xOffset, labelHeight, panelWidth, panelHeight);
    run("Paste");
    run("Select None");

    // Draw label above this panel
    setColor(0, 0, 0);
    setFont("SansSerif", 16, "bold");
    drawString(timepoints[t] + "  (XY" + xyString + ")", xOffset, labelHeight - 8);

    xOffset = xOffset + panelWidth + panelGap;

    close(processedTitles[t]);
}

selectWindow(panelCanvas);
run("Select None");

print("============================================================");
print("PANEL COMPLETE: " + panelCanvas);
print("============================================================");

// ============================================================
// HELPER FUNCTIONS
// ============================================================

function closeIfOpen(title) {
    if (isOpen(title)) {
        selectWindow(title);
        close();
    }
}

function processImage(originalImg, sliceSize, minDensityThreshold, particleSizeMin,
                       particleSizeMax, circularityMin, bgSigma, lineWidth, minMigrationDistance) {

    selectWindow(originalImg);
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
        print("WARNING: No particles detected for " + originalImg + ". Skipping line draw.");
        selectWindow("processing");
        close();
        selectWindow(originalImg);
        run("Duplicate...", "title=temp_fallback");
        run("RGB Color");
        return -1;
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

    migrationFrontSliceIndex = -1;
    for (s = numSlices - 1; s >= 0; s--) {
        distanceFromTop = sliceStarts[s] - minY;
        if (sliceCounts[s] >= minDensityThreshold && distanceFromTop >= minMigrationDistance) {
            migrationFrontSliceIndex = s;
            s = -1;
        }
    }

    if (migrationFrontSliceIndex == -1) {
        fallbackIndex = Math.ceil(minMigrationDistance / sliceSize);
        if (fallbackIndex >= numSlices) fallbackIndex = numSlices - 1;
        migrationFrontSliceIndex = fallbackIndex;
    }

    frontCellYValues = newArray(0);
    for (i = 0; i < nResults; i++) {
        y = getResult("Y", i);
        sliceIndex = floor((y - minY) / sliceSize);
        if (sliceIndex == migrationFrontSliceIndex) {
            frontCellYValues = appendArray(frontCellYValues, y);
        }
    }

    avgMigrationY = 0;
    for (i = 0; i < frontCellYValues.length; i++) {
        avgMigrationY = avgMigrationY + frontCellYValues[i];
    }
    if (frontCellYValues.length > 0) {
        avgMigrationY = avgMigrationY / frontCellYValues.length;
    }

    selectWindow(originalImg);
    run("Duplicate...", "title=temp_fallback");
    run("RGB Color");

    dummyX = 0;
    avgMigrationY_px = avgMigrationY;
    toUnscaled(dummyX, avgMigrationY_px);

    makeLine(0, avgMigrationY_px, getWidth(), avgMigrationY_px);
    Overlay.addSelection("red", lineWidth);
    Overlay.show();
    run("Select None");

    selectWindow("processing");
    close();

    return avgMigrationY;
}

function appendArray(arr, value) {
    newArr = newArray(arr.length + 1);
    for (i = 0; i < arr.length; i++) {
        newArr[i] = arr[i];
    }
    newArr[arr.length] = value;
    return newArr;
}
