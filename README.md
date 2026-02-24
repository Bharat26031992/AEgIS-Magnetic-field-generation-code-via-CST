# AEgIS-Magnetic-field-generation-code-via-CST
This python script automates the generation of input data sets for the 23 AEgIS electromagnetic coils by sequentially running CST simulations for different coil values.

## Project Structure

- **`Bfield_datasetgeneration.py`** - Main script that automates CST electromagnetic simulations
- **`MagnetSuperpositionGUI.m`** - MATLAB GUI for visualizing magnetic field results
- **`MagnetMasterData.mat`** - Pre-computed dataset for testing the visualization

## How to Build and Use This Workspace

### 1. Generate Magnetic Field Data (Python)
To generate magnetic field datasets:
- Edit `Bfield_datasetgeneration.py` and configure these paths:
  ```
  PROJECT_PATH = r"path/to/your/DTBfieldOptimzer.cst"
  BASE_RESULT_FOLDER = r"path/to/output/Results"
  ```
- Adjust parameters: `NUM_SAMPLES`, `VARIATION_PERCENTAGE`, coil defaults
- Run: `python Bfield_datasetgeneration.py`
- Requires: CST installed with Python scripting support

### 2. Visualize Results (MATLAB)
To view magnetic field data:
- Place `MagnetMasterData.mat` in the same folder as `MagnetSuperpositionGUI.m`
- Open and run `MagnetSuperpositionGUI.m` in MATLAB
- This displays 2D field maps and 1D field profiles

## Prerequisites
- **Python** (for data generation)
- **CST Studio** (for running simulations)
- **MATLAB** (for visualization)

# --- Configuration ---
PROJECT_PATH = r"D:\DTBfieldOptimzer.cst" # Repalce with the path where .CST file is located 

BASE_RESULT_FOLDER = r"D:\CST Python\Results" # Replace with the path where the data sets need to be created

NUM_SAMPLES = 10 %% The number of samples for LHC (Latin Hyper Cube) sampling, increasing to higher number will lead to more simulations and larger dataset

VARIATION_PERCENTAGE = 0.1  %% The variation of values around the default setting


COIL_DEFAULTS = {
    "Coil_11": 159.175, "Coil10_5T": 9.73, "Coil12_1Tmain": 83.783,
    "Corrector_Coil1_5T": 83.852, "Corrector_Coil2_5T": 5.0, "Corrector_Coil3_5T": 2.94,
    "Corrector_Coil4_5T": 0.63, "Corrector_Coil5_5T": 0.0, "Corrector_Coil6_5T": 0.0,
    "Corrector_Coil7_5T": 0.0, "Corrector_Coil8_5T": 2.2, "Corrector_Coil9_5T": 0.0,
    "Corrector_Coil13_1T": 1.3, "Corrector_Coil14_1T": 1.91, "Corrector_Coil15_1T": 1.36,
    "Corrector_Coil16_1T": 0.29, "Corrector_Coil17_1T": 0.37, "Corrector_Coil18_1T": 1.12,
    "Corrector_Coil19_1T": 0.32, "Corrector_Coil20_1T": 3.8, "Corrector_Coil21_1T": 0.0,
    "Corrector_Coil22_1T": 6.22, "Corrector_Coil23_1T": 8.0
}

SUB_VOL = [-528.94, 520.94, -528.94, 520.94, -1673.55, 3493.39]
%% This is the subvolume of the CST model through which the Bfield is spread, one can increase or decrease the dimensions according to their own model.



   # Export
                full_path_vba = full_path_os.replace("\\", "\\\\")
                export_vba = f"""
                Sub Main
                    SelectTreeItem("2D/3D Results\\B-Field [Ms]")
                    With ASCIIExport
                        .Reset
                        .FileName ("{full_path_vba}")
                        .Mode "FixedWidth"
                        .StepX 10: .StepY 10: .StepZ 10
                        .SetSubvolume {SUB_VOL[0]}, {SUB_VOL[1]}, {SUB_VOL[2]}, {SUB_VOL[3]}, {SUB_VOL[4]}, {SUB_VOL[5]}
                        .UseSubvolume True
                        .Execute
                    End With
                End Sub
                """
                prj.schematic.execute_vba_code(export_vba)
                prj.save()

The StepX 10 defines the spatial resolution of the exported Magnetic field.




###############################################################

The MagnetMasterData.mat dataset file contains some precomputed simulation results, to visualize it copy the dataset in the same forlder as MagnetSuperpositionGUI.m file and it would export the field values from the file to give the 2D field map and 1D field profile.