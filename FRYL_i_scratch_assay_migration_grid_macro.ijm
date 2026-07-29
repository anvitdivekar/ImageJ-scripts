// ============================================================
// SCRATCH ASSAY - FULL GRID PANEL (24 XY POSITIONS)
// Jo Lab / Anvit Divekar
// 4 rows x 6 columns, each cell = t0/t24/t48 triplet with red line
// Row-major fill: XY01-06=row1, XY07-12=row2, XY13-18=row3, XY19-24=row4
// ============================================================

// --- USER-CONFIGURABLE VARIABLES ---
basePath = "Y:\\jo-lab\\anvitdivekar\\20260727_candidate_scratch_primary\\FRYL_i\\";
condition = "FRYL_i";        // Gene/condition name - shown top right of the grid
channel = "CH4";
numXYPositions = 24;         // Total XY positions to process
gridCols = 6;                // Columns in the grid
gridRows = 4;                // Rows in the grid (numXYPositions / gridCols)

timepoints = newArray("t0hr", "t24hr", "t48hr");

// --- ANALYSIS VARIABLES (validated defaults) ---
sliceSize = 0.05;
minDensityThreshold = 8;
windowSize = 5;
particleSizeMin = 10;
particleSizeMax = 200;
circularityMin = 0.3;
bgSigma = 30;
lineWidth = 3;
minMigrationDistance = 0.2;

// --- LAYOUT VARIABLES ---
withinCellGap = 4;           // Gap between the 3 timepoint images inside one cell
cellLabelHeight = 24;        // Space for the "(XY__)" label under each cell
cellGap = 16;                // Gap between grid cells
gridMargin = 20;             // Outer margin around the whole grid
titleHeight = 50;            // Space at top for the gene title

// --- GLOBAL RESULT HOLDER ---
lastPercentAboveLine = -1;

// ============================================================
// VALIDATE
// ============================================================
if (gridRows * gridCols != numXYPositions) {
    exit("ERROR: gridRows (" + gridRows + ") x gridCols (" + gridCols + 
         ") = " + (gridRows * gridCols) + ", which does not equal numXYPositions (" + numXYPositions + ").");
}

// ============================================================
// PROCESS ALL XY POSITIONS, BUILD ONE CELL-STRIP PER XY
// ============================================================
cellTitles = newArray(numXYPositions);
imgWidth = 0;
imgHeight = 0;

for (xy = 1; xy <= numXYPositions; xy++) {

    xyString = "" + xy;
    if (xy < 10) xyString = "0" + xyString;

    isBottomUp = (xy % 2 == 0);

    processedTitles = newArray(timepoints.length);

    for (t = 0; t < timepoints.length; t++) {
        tp = timepoints[t];
        filePath = basePath + condition + "_" + tp + "\\XY" + xyString + "\\Imageq_XY" + xyString + "_" + channel + ".tif";

        if (!File.exists(filePath)) {
            print("WARNING: File not found, skipping: " + filePath);
            continue;
        }

        open(filePath);
        originalImg = getTitle();

        result = processImage(originalImg, sliceSize, minDensityThreshold, windowSize, particleSizeMin,
                               particleSizeMax, circularityMin, bgSigma, lineWidth, minMigrationDistance, isBottomUp);

        annotatedTitle = "xy" + xyString + "_" + tp;
        rename(annotatedTitle);
        processedTitles[t] = annotatedTitle;

        imgWidth = getWidth();
        imgHeight = getHeight();

        print("XY" + xyString + " | " + tp + " | front Y=" + result + " | percent=" + lastPercentAboveLine);

        closeIfOpen(originalImg);
        closeIfOpen("processing");
    }

    // Build this XY's 3-image cell strip
    validInCell = 0;
    for (t = 0; t < processedTitles.length; t++) {
        if (processedTitles[t] != "") validInCell++;
    }

    if (validInCell == 0) {
        print("WARNING: No valid images for XY" + xyString + ". Cell will be blank.");
        cellTitles[xy - 1] = "";
        continue;
    }

    cellWidth = (imgWidth * timepoints.length) + (withinCellGap * (timepoints.length - 1));
    cellHeight = imgHeight + cellLabelHeight;

    newImage("cell_XY" + xyString, "RGB white", cellWidth, cellHeight, 1);
    cellCanvas = getTitle();

    xOff = 0;
    for (t = 0; t < timepoints.length; t++) {
        if (processedTitles[t] == "") {
            xOff = xOff + imgWidth + withinCellGap;
            continue;
        }
        selectWindow(processedTitles[t]);
        run("Select All");
        run("Copy");

        selectWindow(cellCanvas);
        makeRectangle(xOff, 0, imgWidth, imgHeight);
        run("Paste");
        run("Select None");

        xOff = xOff + imgWidth + withinCellGap;
        close(processedTitles[t]);
    }

    // Centered "(XY__)" label under the triplet
    selectWindow(cellCanvas);
    setColor(0, 0, 0);
    setFont("SansSerif", 16, "bold");
    labelText = "(XY" + xyString + ")";
    labelWidth = getStringWidth(labelText);
    drawString(labelText, (cellWidth / 2) - (labelWidth / 2), imgHeight + 18);

    cellTitles[xy - 1] = cellCanvas;
}

// ============================================================
// ASSEMBLE FULL GRID
// ============================================================
cellWidthFinal = (imgWidth * timepoints.length) + (withinCellGap * (timepoints.length - 1));
cellHeightFinal = imgHeight + cellLabelHeight;

gridContentWidth = (cellWidthFinal * gridCols) + (cellGap * (gridCols - 1));
gridContentHeight = (cellHeightFinal * gridRows) + (cellGap * (gridRows - 1));

canvasWidth = gridContentWidth + (gridMargin * 2);
canvasHeight = gridContentHeight + (gridMargin * 2) + titleHeight;

newImage("FullGrid_" + condition, "RGB white", canvasWidth, canvasHeight, 1);
fullGrid = getTitle();

// Gene title, top right
setColor(0, 0, 0);
setFont("SansSerif", 28, "bold");
titleText = condition;
titleWidth = getStringWidth(titleText);
drawString(titleText, canvasWidth - titleWidth - gridMargin, titleHeight - 15);

// Place each cell in row-major order
for (xy = 1; xy <= numXYPositions; xy++) {
    cellTitle = cellTitles[xy - 1];
    if (cellTitle == "") continue;

    idx = xy - 1;
    row = floor(idx / gridCols);
    col = idx % gridCols;

    xPos = gridMargin + (col * (cellWidthFinal + cellGap));
    yPos = titleHeight + gridMargin + (row * (cellHeightFinal + cellGap));

    selectWindow(cellTitle);
    run("Select All");
    run("Copy");

    selectWindow(fullGrid);
    makeRectangle(xPos, yPos, cellWidthFinal, cellHeightFinal);
    run("Paste");
    run("Select None");

    close(cellTitle);
}

selectWindow(fullGrid);
run("Select None");

print("============================================================");
print("FULL GRID PANEL COMPLETE: " + fullGrid);
print("Grid: " + gridRows + " rows x " + gridCols + " columns");
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

function processImage(originalImg, sliceSize, minDensityThreshold, windowSize, particleSizeMin,
                       particleSizeMax, circularityMin, bgSigma, lineWidth, minMigrationDistance, isBottomUp) {

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

    selectWindow(originalImg);
    run("Duplicate...", "title=annotated");
    run("RGB Color");
    imgH = getHeight();
    imgW = getWidth();

    if (nResults == 0) {
        print("WARNING: No particles detected for " + originalImg + ". Skipping line draw.");
        lastPercentAboveLine = -1;
        selectWindow("processing");
        close();
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

    if (!isBottomUp) {
        for (s = numSlices - windowSize; s >= 0; s--) {
            distanceFromEdge = sliceStarts[s] - minY;
            if (distanceFromEdge < minMigrationDistance) continue;

            windowSum = 0;
            for (w = 0; w < windowSize; w++) {
                windowSum = windowSum + sliceCounts[s + w];
            }
            windowAvg = windowSum / windowSize;

            if (windowAvg >= minDensityThreshold) {
                migrationFrontSliceIndex = s;
                s = -1;
            }
        }
        if (migrationFrontSliceIndex == -1) {
            fallbackIndex = Math.ceil(minMigrationDistance / sliceSize);
            if (fallbackIndex >= numSlices) fallbackIndex = numSlices - 1;
            migrationFrontSliceIndex = fallbackIndex;
        }
    } else {
        for (s = 0; s <= numSlices - windowSize; s++) {
            distanceFromTop = sliceStarts[s] - minY;
            if (distanceFromTop < minMigrationDistance) continue;

            windowSum = 0;
            for (w = 0; w < windowSize; w++) {
                windowSum = windowSum + sliceCounts[s + w];
            }
            windowAvg = windowSum / windowSize;

            if (windowAvg >= minDensityThreshold) {
                migrationFrontSliceIndex = s;
                s = numSlices;
            }
        }
        if (migrationFrontSliceIndex == -1) {
            fallbackIndex = numSlices - 1 - Math.ceil(minMigrationDistance / sliceSize);
            if (fallbackIndex < 0) fallbackIndex = 0;
            migrationFrontSliceIndex = fallbackIndex;
        }
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
    } else {
        avgMigrationY = sliceStarts[migrationFrontSliceIndex];
    }

    selectWindow("annotated");

    dummyX = 0;
    avgMigrationY_px = avgMigrationY;
    toUnscaled(dummyX, avgMigrationY_px);

    makeLine(0, avgMigrationY_px, imgW, avgMigrationY_px);
    Overlay.addSelection("red", lineWidth);
    Overlay.show();
    run("Select None");

    run("Flatten");
    flattenedTitle = getTitle();
    close("annotated");
    selectWindow(flattenedTitle);
    rename("annotated");

    if (!isBottomUp) {
        percentOccupied = (avgMigrationY_px / imgH) * 100;
    } else {
        percentOccupied = ((imgH - avgMigrationY_px) / imgH) * 100;
    }
    lastPercentAboveLine = percentOccupied;

    setColor(255, 0, 0);
    setFont("SansSerif", 20, "bold");
    labelText = d2s(percentOccupied, 1) + "%";
    labelWidth2 = getStringWidth(labelText);
    drawString(labelText, (imgW / 2) - (labelWidth2 / 2), imgH - 15);

    selectWindow("processing");
    close();

    selectWindow("annotated");
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
