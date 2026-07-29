// ============================================================
// SCRATCH ASSAY MIGRATION FRONT DETECTION MACRO
// Density-based front detection + visual line (overlay, RGB)
// ============================================================

// --- USER-CONFIGURABLE VARIABLES ---
sliceSize = 0.05;              // Micron size per density slice
minDensityThreshold = 20;      // Minimum cells per slice to count as migration front
particleSizeMin = 10;          // Minimum particle size (pixels²)
particleSizeMax = 200;         // Maximum particle size (pixels²)
circularityMin = 0.3;          // Minimum circularity filter
bgSigma = 30;                  // Gaussian blur sigma for background subtraction
lineWidth = 3;                 // Width of migration front line
minMigrationDistance = 0.2;    // Minimum micron distance from wound edge (minY) before a slice can count as the front — prevents accidentally picking the very top of the image/wound edge

// ============================================================
// MAIN WORKFLOW
// ============================================================

// 1. GET ORIGINAL IMAGE
originalImg = getTitle();
if (originalImg == "") {
    exit("No image open. Please open a scratch assay image.");
}

// 2. PREPROCESSING: Background subtraction + contrast enhancement
run("Duplicate...", "title=processing");
selectWindow("processing");

run("Duplicate...", "title=background");
run("Gaussian Blur...", "sigma=" + bgSigma);
selectWindow("processing");
imageCalculator("Subtract", "processing", "background");
close("background");

run("Enhance Contrast...", "saturated=0.35 normalize");

// 3. THRESHOLDING
run("8-bit");
setAutoThreshold("Triangle dark");
run("Convert to Mask");

// 4. MORPHOLOGICAL CLEANUP
run("Open", "");

// 5. PARTICLE ANALYSIS
run("Set Measurements...", "area centroid redirect=None decimal=3");
run("Analyze Particles...", "size=" + particleSizeMin + "-" + particleSizeMax + 
    " circularity=" + circularityMin + "-1.00 pixel display clear");

// 6. GET RESULTS
if (nResults == 0) {
    exit("No particles detected. Check thresholding and size parameters.");
}

yValues = newArray(nResults);
for (i = 0; i < nResults; i++) {
    yValues[i] = getResult("Y", i);
}

yValuesSorted = Array.copy(yValues);
Array.sort(yValuesSorted);

// 7. CALCULATE DENSITY PROFILE (all in calibrated/micron units, matching Results table)
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

// 8. FIND MIGRATION FRONT (lowest slice with >= minDensityThreshold cells,
//    AND at least minMigrationDistance away from the wound edge/top)
migrationFrontSliceIndex = -1;
for (s = numSlices - 1; s >= 0; s--) {
    distanceFromTop = sliceStarts[s] - minY;
    if (sliceCounts[s] >= minDensityThreshold && distanceFromTop >= minMigrationDistance) {
        migrationFrontSliceIndex = s;
        s = -1;
    }
}

if (migrationFrontSliceIndex == -1) {
    print("WARNING: No slice found with >= " + minDensityThreshold + 
          " cells beyond minMigrationDistance (" + minMigrationDistance + " micron).");
    print("Falling back to the slice at minMigrationDistance from the top.");
    fallbackIndex = Math.ceil(minMigrationDistance / sliceSize);
    if (fallbackIndex >= numSlices) fallbackIndex = numSlices - 1;
    migrationFrontSliceIndex = fallbackIndex;
}

migrationFrontY = sliceStarts[migrationFrontSliceIndex];

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

// 9. CREATE DENSITY PROFILE PLOT (new window, micron units - matches Results table)
plotDensityProfile(sliceStarts, sliceCounts, migrationFrontY, minDensityThreshold);

// 10. DRAW RED LINE ON A DUPLICATE OF THE ORIGINAL (RGB + overlay, new window)
// IMPORTANT: avgMigrationY is in calibrated units (microns), but makeLine()
// needs pixel coordinates. Convert before drawing.
selectWindow(originalImg);
run("Duplicate...", "title=" + originalImg + "_migrationFront");
run("RGB Color");

dummyX = 0;
avgMigrationY_px = avgMigrationY;
toUnscaled(dummyX, avgMigrationY_px);

makeLine(0, avgMigrationY_px, getWidth(), avgMigrationY_px);
Overlay.addSelection("red", lineWidth);
Overlay.show();
run("Select None");

// 11. OUTPUT TO CONSOLE (Log window)
print("============================================================");
print("SCRATCH ASSAY MIGRATION FRONT DETECTION");
print("============================================================");
print("Image: " + originalImg);
print("Slice size: " + sliceSize + " micron");
print("Density threshold: " + minDensityThreshold + " cells/slice");
print("Minimum migration distance: " + minMigrationDistance + " micron");
print("Total particles detected: " + nResults);
print("Particles in migration front slice: " + frontCellYValues.length);
print("Migration front Y position (micron): " + avgMigrationY);
print("Migration front Y position (pixels): " + avgMigrationY_px);
print("============================================================");

// 12. CLEANUP
selectWindow("processing");
close();

// ============================================================
// HELPER FUNCTIONS
// ============================================================

function appendArray(arr, value) {
    newArr = newArray(arr.length + 1);
    for (i = 0; i < arr.length; i++) {
        newArr[i] = arr[i];
    }
    newArr[arr.length] = value;
    return newArr;
}

function plotDensityProfile(sliceStarts, sliceCounts, frontY, threshold) {
    Plot.create("Cell Density Profile", "Y position (micron)", "Cell count per slice");
    Plot.add("line", sliceStarts, sliceCounts);

    maxCount = sliceCounts[0];
    for (i = 1; i < sliceCounts.length; i++) {
        if (sliceCounts[i] > maxCount) maxCount = sliceCounts[i];
    }

    Plot.setColor("red");
    Plot.drawLine(sliceStarts[0], threshold, sliceStarts[sliceStarts.length - 1], threshold);

    Plot.setColor("blue");
    Plot.drawLine(frontY, 0, frontY, maxCount);

    Plot.show();
}
