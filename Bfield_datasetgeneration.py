import os
import time
import cst.interface
import numpy as np
from scipy.stats import qmc

# --- Configuration ---
PROJECT_PATH = r"D:\DTBfieldOptimzer.cst"
BASE_RESULT_FOLDER = r"D:\CST Python\Results"
NUM_SAMPLES = 10
VARIATION_PERCENTAGE = 0.1 

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

def main():
    # --- Check for Existing Progress ---
    mode = "run"
    if os.path.exists(BASE_RESULT_FOLDER) and os.listdir(BASE_RESULT_FOLDER):
        print("Existing result folders detected.")
        choice = input("Do you want to (O)verwrite everything or (R)esume from the last crash? [O/R]: ").strip().lower()
        if choice == 'r':
            mode = "resume"
            print("Mode set to RESUME: Existing files will be skipped.")
        else:
            print("Mode set to OVERWRITE: Existing data will be replaced.")

    de = cst.interface.DesignEnvironment.connect_to_any_or_new()
    
    try:
        prj = de.open_project(PROJECT_PATH)
        
        for target_coil, default_val in COIL_DEFAULTS.items():
            coil_folder = os.path.join(BASE_RESULT_FOLDER, target_coil)
            if not os.path.exists(coil_folder):
                os.makedirs(coil_folder)

            # Generate LHS Samples (using a fixed seed ensures same values on resume)
            lower = default_val * (1 - VARIATION_PERCENTAGE) if default_val != 0 else 0
            upper = default_val * (1 + VARIATION_PERCENTAGE) if default_val != 0 else 1.0
            sampler = qmc.LatinHypercube(d=1, seed=42) 
            sample = sampler.random(n=NUM_SAMPLES)
            current_values = qmc.scale(sample, [lower], [upper]).flatten()

            print(f"\nProcessing Coil: {target_coil}")

            for i, val in enumerate(current_values):
                val = round(float(val), 3)
                file_name = f"BField_{target_coil}_{val}.txt"
                full_path_os = os.path.join(coil_folder, file_name)
                
                # --- RESUME LOGIC ---
                if mode == "resume" and os.path.exists(full_path_os):
                    print(f"  [Skipping] {file_name} already exists.")
                    continue

                print(f"  [Running] {target_coil} = {val} ({i+1}/{NUM_SAMPLES})")

                # VBA: Update Parameters
                vba_set_params = "Sub Main\n"
                for coil_name in COIL_DEFAULTS.keys():
                    set_val = val if coil_name == target_coil else 0.0
                    vba_set_params += f'  StoreParameter("{coil_name}", {set_val})\n'
                vba_set_params += "  Rebuild\nEnd Sub"
                prj.schematic.execute_vba_code(vba_set_params)
                
                # Solver
                try:
                    prj.model3d.run_solver()
                except Exception as e:
                    print(f"    Solver error: {e}")

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

    except Exception as e:
        print(f"Critical error: {e}")
    finally:
        print("\nBatch process finished.")

if __name__ == "__main__":
    main()