# ImageJ Scripts

Collection of scripts used to analyze cells on ImageJ.

## Scratch Assay Analysis Macros

### FRYL_i_scratch_assay_migration_grid_macro.ijm
Analyzes cell migration in scratch assay experiments using a grid-based approach for the Jo Lab / D... workflow.
- **Purpose**: Quantify cell migration and confluence changes across multiple time points
- **Input**: Microscopy images from scratch assay experiments
- **Output**: Migration metrics and confluence measurements

### batch_timepoints.ijm
Processes multiple timepoint images in batch for consistent analysis across experimental replicates.
- **Purpose**: Automate processing of time-series microscopy data
- **Features**: Batch processing, timepoint registration
- **Usage**: Load directory of timepoint images and process automatically

### individual_proliferation_redLine.ijm
Analyzes individual cell proliferation using red line tracking methodology.
- **Purpose**: Track and quantify single cell proliferation rates
- **Method**: Red line-based cell tracking and proliferation analysis
- **Output**: Individual cell proliferation metrics

### test1.ijm
Test macro for validation and development of new analysis features.
- **Purpose**: Testing and experimentation
- **Status**: Development/validation macro

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
