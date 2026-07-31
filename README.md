# ImageJ Scripts

Collection of scripts used to analyze cells on ImageJ.

## 🎯 Master Macro (Recommended)

### scratch_assay_master.ijm
Unified macro for all scratch assay analysis modes. Asks for user input at runtime to select analysis type.

**Modes:**
- **Mode 1 — Individual**: Analyze a single currently-open image
  - Draws red migration front line on overlay
  - Shows cell density profile plot
  - Outputs migration front Y position to log
  
- **Mode 2 — Batch by Timepoint**: Process one XY position across all timepoints (t0hr, t24hr, t48hr)
  - Tiles processed images side-by-side with labels
  - Useful for tracking migration progression over time
  
- **Mode 3 — Full Grid**: Process all 36 XY positions in 6×6 grid layout
  - Each cell shows t0/t24/t48 triplet
  - Displays % confluence label on each image
  - Generates comprehensive summary panel

**Quick Start:**
1. Edit `basePath`, `condition`, and `channel` at top of macro
2. For Mode 2, set `xyPosition` (1-36)
3. Run macro, enter mode number (1, 2, or 3) when prompted

---

## Individual Analysis Macros (Reference)

### FRYL_i_scratch_assay_migration_grid_macro.ijm
Full grid panel macro (24 XY positions in 4×6 layout). Foundation for Mode 3 of master macro.
- **Purpose**: Grid-based analysis of migration across multiple positions
- **Input**: Directory of images organized by condition/timepoint/XY position
- **Output**: Combined grid panel with red migration front lines and % confluence labels

### batch_timepoints.ijm
Single XY position, multi-timepoint processor. Foundation for Mode 2 of master macro.
- **Purpose**: Process one XY position across t0hr/t24hr/t48hr
- **Features**: Automatic timepoint detection, side-by-side panel tiling with labels
- **Output**: Labeled migration panel showing progression over time

### individual_proliferation_redLine.ijm
Single image analyzer. Foundation for Mode 1 of master macro.
- **Purpose**: Analyze individual image or validate settings before batch processing
- **Features**: Density-based migration front detection, red line overlay, density profile plot
- **Output**: Migration metrics and visual confirmation of front detection

### test1.ijm
Development/validation macro.
- **Purpose**: Testing and experimentation
- **Status**: Test file

## Usage

1. Open ImageJ/Fiji
2. Select the appropriate macro for your analysis type
3. Load your microscopy images
4. Run the macro and follow prompts for parameter input
5. Results will be saved to your output directory

## Requirements

- ImageJ or Fiji
- Appropriate image files in supported formats (TIF, JPG, PNG)

## Data Directory Structure

Organize your data as follows for batch processing:
```
data/
├── experiment_1/
│   ├── t0/
│   ├── t1/
│   └── t2/
└── experiment_2/
    └── timepoints/
```

## Notes

These macros are designed for cell migration and proliferation analysis in scratch assay experiments. Adjust parameters in the macro code as needed for your specific microscopy setup and image characteristics.
