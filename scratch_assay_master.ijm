// ============================================================
// SCRATCH ASSAY MASTER MACRO
// Jo Lab / Anvit Divekar
//
// Mode 1 — Individual: run on currently-open image, draw red
//           migration-front line + density profile plot
// Mode 2 — Batch timepoints: one XY position, processes
//           t0hr/t24hr/t48hr and tiles side-by-side panel
// Mode 3 — Full grid: all 36 XY positions (6x6 grid), each
//           cell = t0/t24/t48 triplet with % label
// ============================================================

// --- USER-CONFIGURABLE VARIABLES ---
basePath  = "Y:\\jo-lab\\anvitdivekar\\20260727_candidate_scratch_primary\\FRYL_i\\";
condition = "FRYL_i";
channel   = "CH4";
xyPosition = 1;          // Mode 2 only: which XY position to process (1-36)
numXYPositions = 36;     // Mode 3: total XY positions
gridCols = 6;
gridRows = 6;

// --- ANALYSIS PARAMETERS ---
sliceSize            = 0.05;
minDensityThreshold  = 8;
windowSize           = 5;
particleSizeMin      = 10;
particleSizeMax      = 200;
circularityMin       = 0.3;
bgSigma              = 30;
lineWidth            = 3;
minMigrationDistance = 0.2;

// --- LAYOUT PARAMETERS ---
panelGap       = 10;
labelHeight    = 30;
withinCellGap  = 4;
cellLabelHeight = 24;
cellGap        = 16;
gridMargin     = 20;
titleHeight    = 50;

// --- GLOBAL RESULT HOLDER ---
lastPercentAboveLine = -1;

timepoints = newArray("t0hr", "t24hr", "t48hr");

// ============================================================
// MODE SELECTION
// ============================================================
mode = getNumber("Enter mode:\n 1 = Individual (currently open image)\n 2 = Batch (one XY, all timepoints)\n 3 = Full grid (all " + numXYPositions + " XY positions)", 1);

if (mode == 1)      runIndividual();
else if (mode == 2) runBatchTimepoints();
else if (mode == 3) runFullGrid();
else exit("Invalid mode. Enter 1, 2, or 3.");

// ============================================================
// MODE 1 — INDIVIDUAL
// ============================================================
function runIndividual() {
    originalImg = getTitle();
    if (originalImg == "") exit("No image open. Please open a scratch assay image first.");

    // Store particle data for density plot
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
        close("processing");
        exit("No particles detected. Check thresholding and size parameters.");
    }

    yValues = newArray(nResults);
    for (i = 0; i < nResults; i++) yValues[i] = getResult("Y", i);

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
        si = floor((y - minY) / sliceSize);
        if (si >= 0 && si < numSlices) sliceCounts[si] = sliceCounts[si] + 1;
    }

    // Find migration front (simple per-slice threshold, top-down)
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

    migrationFrontY = sliceStarts[migrationFrontSliceIndex];

    frontCellYValues = newArray(0);
    for (i = 0; i < nResults; i++) {
        y = getResult("Y", i);
        si = floor((y - minY) / sliceSize);
        if (si == migrationFrontSliceIndex) frontCellYValues = appendArray(frontCellYValues, y);
    }

    avgMigrationY = 0;
    for (i = 0; i < frontCellYValues.length; i++) avgMigrationY += frontCellYValues[i];
    if (frontCellYValues.length > 0) avgMigrationY = avgMigrationY / frontCellYValues.length;

    // Density profile plot
    plotDensityProfile(sliceStarts, sliceCounts, migrationFrontY, minDensityThreshold);

    // Draw red line on duplicate
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

    close("processing");

    print("============================================================");
    print("SCRATCH ASSAY — INDIVIDUAL MODE");
    print("Image: " + originalImg);
    print("Total particles: " + nResults);
    print("Particles in front slice: " + frontCellYValues.length);
    print("Migration front Y (micron): " + avgMigrationY);
    print("Migration front Y (pixels): " + avgMigrationY_px);
    print("============================================================");
}

// ============================================================
// MODE 2 — BATCH TIMEPOINTS (one XY, t0/t24/t48 panel)
// ============================================================
function runBatchTimepoints() {
    if (xyPosition < 1 || xyPosition > 36)
        exit("ERROR: xyPosition must be 1-36. You set: " + xyPosition);

    xyString = "" + xyPosition;
    if (xyPosition < 10) xyString = "0" + xyString;

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

        isBottomUp = (xyPosition % 2 == 0);
        result = processImage(originalImg, isBottomUp);

        annotatedTitle = "panel_" + tp;
        rename(annotatedTitle);
        processedTitles[t] = annotatedTitle;

        panelWidth  = getWidth();
        panelHeight = getHeight();

        print("Timepoint: " + tp + " | XY" + xyString + " | front Y=" + result + " | percent=" + lastPercentAboveLine);

        closeIfOpen(originalImg);
        closeIfOpen("processing");
    }

    validCount = 0;
    for (t = 0; t < processedTitles.length; t++) if (processedTitles[t] != "") validCount++;

    if (validCount == 0) exit("No images processed. Check file paths.");

    canvasWidth  = (panelWidth * validCount) + (panelGap * (validCount + 1));
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

        setColor(0, 0, 0);
        setFont("SansSerif", 16, "bold");
        drawString(timepoints[t] + "  (XY" + xyString + ")", xOffset, labelHeight - 8);

        xOffset = xOffset + panelWidth + panelGap;
        close(processedTitles[t]);
    }

    selectWindow(panelCanvas);
    run("Select None");
    print("PANEL COMPLETE: " + panelCanvas);
}

// ============================================================
// MODE 3 — FULL GRID (all XY positions)
// ============================================================
function runFullGrid() {
    if (gridRows * gridCols != numXYPositions)
        exit("ERROR: gridRows (" + gridRows + ") x gridCols (" + gridCols +
             ") must equal numXYPositions (" + numXYPositions + ").");

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

            result = processImage(originalImg, isBottomUp);

            annotatedTitle = "xy" + xyString + "_" + tp;
            rename(annotatedTitle);
            processedTitles[t] = annotatedTitle;

            imgWidth  = getWidth();
            imgHeight = getHeight();

            print("XY" + xyString + " | " + tp + " | front Y=" + result + " | percent=" + lastPercentAboveLine);

            closeIfOpen(originalImg);
            closeIfOpen("processing");
        }

        validInCell = 0;
        for (t = 0; t < processedTitles.length; t++) if (processedTitles[t] != "") validInCell++;

        if (validInCell == 0) {
            print("WARNING: No valid images for XY" + xyString + ". Cell will be blank.");
            cellTitles[xy - 1] = "";
            continue;
        }

        cellWidth  = (imgWidth * timepoints.length) + (withinCellGap * (timepoints.length - 1));
        cellHeight = imgHeight + cellLabelHeight;

        newImage("cell_XY" + xyString, "RGB white", cellWidth, cellHeight, 1);
        cellCanvas = getTitle();

        xOff = 0;
        for (t = 0; t < timepoints.length; t++) {
            if (processedTitles[t] == "") { xOff += imgWidth + withinCellGap; continue; }
            selectWindow(processedTitles[t]);
            run("Select All");
            run("Copy");
            selectWindow(cellCanvas);
            makeRectangle(xOff, 0, imgWidth, imgHeight);
            run("Paste");
            run("Select None");
            xOff += imgWidth + withinCellGap;
            close(processedTitles[t]);
        }

        selectWindow(cellCanvas);
        setColor(0, 0, 0);
        setFont("SansSerif", 16, "bold");
        labelText = "(XY" + xyString + ")";
        labelW = getStringWidth(labelText);
        drawString(labelText, (cellWidth / 2) - (labelW / 2), imgHeight + 18);

        cellTitles[xy - 1] = cellCanvas;
    }

    // Assemble full grid
    cellWidthFinal  = (imgWidth * timepoints.length) + (withinCellGap * (timepoints.length - 1));
    cellHeightFinal = imgHeight + cellLabelHeight;

    gridContentWidth  = (cellWidthFinal * gridCols) + (cellGap * (gridCols - 1));
    gridContentHeight = (cellHeightFinal * gridRows) + (cellGap * (gridRows - 1));

    canvasWidth  = gridContentWidth + (gridMargin * 2);
    canvasHeight = gridContentHeight + (gridMargin * 2) + titleHeight;

    newImage("FullGrid_" + condition, "RGB white", canvasWidth, canvasHeight, 1);
    fullGrid = getTitle();

    setColor(0, 0, 0);
    setFont("SansSerif", 28, "bold");
    titleText = condition;
    titleW = getStringWidth(titleText);
    drawString(titleText, canvasWidth - titleW - gridMargin, titleHeight - 15);

    for (xy = 1; xy <= numXYPositions; xy++) {
        cellTitle = cellTitles[xy - 1];
        if (cellTitle == "") continue;

        idx = xy - 1;
        row = floor(idx / gridCols);
        col  = idx % gridCols;

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
    print("FULL GRID COMPLETE: " + fullGrid + " | " + gridRows + "x" + gridCols);
}

// ============================================================
// SHARED processImage FUNCTION
// ============================================================
function processImage(originalImg, isBottomUp) {
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
        print("WARNING: No particles detected for " + originalImg + ". Skipping line.");
        lastPercentAboveLine = -1;
        close("processing");
        return -1;
    }

    yValues = newArray(nResults);
    for (i = 0; i < nResults; i++) yValues[i] = getResult("Y", i);
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
        si = floor((y - minY) / sliceSize);
        if (si >= 0 && si < numSlices) sliceCounts[si] = sliceCounts[si] + 1;
    }

    migrationFrontSliceIndex = -1;

    if (!isBottomUp) {
        for (s = numSlices - windowSize; s >= 0; s--) {
            if ((sliceStarts[s] - minY) < minMigrationDistance) continue;
            windowSum = 0;
            for (w = 0; w < windowSize; w++) windowSum += sliceCounts[s + w];
            if ((windowSum / windowSize) >= minDensityThreshold) { migrationFrontSliceIndex = s; s = -1; }
        }
        if (migrationFrontSliceIndex == -1) {
            fallbackIndex = Math.ceil(minMigrationDistance / sliceSize);
            if (fallbackIndex >= numSlices) fallbackIndex = numSlices - 1;
            migrationFrontSliceIndex = fallbackIndex;
        }
    } else {
        for (s = 0; s <= numSlices - windowSize; s++) {
            if ((sliceStarts[s] - minY) < minMigrationDistance) continue;
            windowSum = 0;
            for (w = 0; w < windowSize; w++) windowSum += sliceCounts[s + w];
            if ((windowSum / windowSize) >= minDensityThreshold) { migrationFrontSliceIndex = s; s = numSlices; }
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
        if (floor((y - minY) / sliceSize) == migrationFrontSliceIndex)
            frontCellYValues = appendArray(frontCellYValues, y);
    }

    avgMigrationY = 0;
    for (i = 0; i < frontCellYValues.length; i++) avgMigrationY += frontCellYValues[i];
    if (frontCellYValues.length > 0) avgMigrationY = avgMigrationY / frontCellYValues.length;
    else avgMigrationY = sliceStarts[migrationFrontSliceIndex];

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

    percentOccupied = (!isBottomUp)
        ? (avgMigrationY_px / imgH) * 100
        : ((imgH - avgMigrationY_px) / imgH) * 100;
    lastPercentAboveLine = percentOccupied;

    setColor(255, 0, 0);
    setFont("SansSerif", 20, "bold");
    pctLabel = d2s(percentOccupied, 1) + "%";
    pctLabelW = getStringWidth(pctLabel);
    drawString(pctLabel, (imgW / 2) - (pctLabelW / 2), imgH - 15);

    close("processing");
    selectWindow("annotated");
    return avgMigrationY;
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================
function closeIfOpen(title) {
    if (isOpen(title)) { selectWindow(title); close(); }
}

function appendArray(arr, value) {
    newArr = newArray(arr.length + 1);
    for (i = 0; i < arr.length; i++) newArr[i] = arr[i];
    newArr[arr.length] = value;
    return newArr;
}

function plotDensityProfile(sliceStarts, sliceCounts, frontY, threshold) {
    Plot.create("Cell Density Profile", "Y position (micron)", "Cell count per slice");
    Plot.add("line", sliceStarts, sliceCounts);

    maxCount = sliceCounts[0];
    for (i = 1; i < sliceCounts.length; i++) if (sliceCounts[i] > maxCount) maxCount = sliceCounts[i];

    Plot.setColor("red");
    Plot.drawLine(sliceStarts[0], threshold, sliceStarts[sliceStarts.length - 1], threshold);
    Plot.setColor("blue");
    Plot.drawLine(frontY, 0, frontY, maxCount);
    Plot.show();
}
