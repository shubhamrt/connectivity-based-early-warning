# connectivity-based-early-warning
MATLAB analysis and figure-generation code for "The Role of Connectivity in Understanding Grassland–Shrubland Regime Shifts". Reproduces metrics, correlations, and plots using NOAA Climate Division precipitation; modified Stewart et al. model on Zenodo ; large .mat/.tif files kept out of the repo (doi:10.5281/zenodo.16104933).



# The Role of Connectivity in Understanding Grassland–Shrubland Regime Shifts
_MATLAB analysis and figure scripts for connectivity‑based early‑warning signals (1895–2022)._

**Authors:** Shubham Tiwari*, Laura Turnbull, John Wainwright  
*Corresponding author* — Department of Geography, Durham University, UK

---

## Overview
This repository contains the **exact code and outputs** used to generate the figures and tables for the manuscript. It is organised to keep code and *small, final artefacts* in the repo, while large model outputs and raw climate downloads remain on your machine.

**Please do not upload large `.mat`/`.tif` files.** The analysis reads these from a local folder (see _Inputs_).

---

## Repository layout (what each folder holds)
```
.
├─ Analysis/                 # MATLAB code
│  ├─ R1_networks.m                  # build/assemble networks from model outputs
│  ├─ R1_percentagegraze_v1_revision.m  # grazing scenarios / time series
│  ├─ R3_correlationplot.m           # correlations & early‑warning metrics
│  ├─ R4_node.m                      # main figure scripts
│  ├─ parseArgs.m  subaxis.m  suplabel.m  # helper utilities
│  └─ README.md (optional notes you may add)
├─ Figure/                   # publication‑ready figures exported by the scripts
├─ Supplementary Figures/    # figures for the supplement
└─ Rainfall/                 # (local only) NOAA climate division data *
```
\* _Keep `Rainfall/` local or empty in Git. If you need it in the repo for structure, add a tiny `README.md` inside that explains how to download data; do **not** commit the actual data files._

---

## Quick start (MATLAB)
1. **Clone** or download this repository.
2. Place **large inputs** (model `.mat` files and NOAA downloads) **outside** the repo or in a local, ignored folder (e.g., `Rainfall/` on your machine).
3. Open MATLAB with the repo as the **Current Folder**.
4. Run the scripts in this order (see details below):
   ```matlab
   % 1) Build/assemble networks
   run fullfile('Analysis','R2_networks.m')

   % 2) Grazing scenarios / time series
   run fullfile('Analysis','R1_percentagegraze_v1_revision.m')

   % 3) Correlations and early‑warning metrics
   run fullfile('Analysis','R3_correlationplot.m')

   % 4) Export figures
   run fullfile('Analysis','R4_node.m')
   ```
5. Final figures will appear in `Figure/` and `Supplementary Figures/`. Small tables (e.g., `Temporal_Correlations_*.xlsx`) are saved alongside the scripts or in a `results` subfolder if specified in your code.

> If a script can’t find your data, open the `.m` file and edit any path variables (e.g., `dataDir`, `inputDir`, `RainfallDir`) so they point to where your large files live on your machine.

---

## Inputs (kept off GitHub)
- **NOAA precipitation:** Monthly U.S. Climate Division dataset from <https://www.ncei.noaa.gov/>. Store locally (e.g., in `Rainfall/`).
- **Model outputs:** Large `.mat` files produced by the (modified) ecogeomorphic model of Stewart et al. (2014). Store locally outside the repo and reference their path inside the scripts.

> Tip: If you add a `.gitignore` at the repo root with lines like `*.mat` and `Rainfall/**`, GitHub will ignore large files automatically.

---

## What each main script does

- **`R1_percentagegraze_v1_revision.m`** — runs grazing scenarios (near‑natural, 30%, 60%), produces vegetation time series for dry vs wet climates.
- **`R2_networks.m`** — loads model output(s), builds structural/functional networks for **water** and **nitrogen**, and prepares any intermediate summaries used later.
- **`R3_correlationplot.m`** — computes correlations between connectivity metrics and biomass (grass/shrub) and can export tables such as `Temporal_Correlations_*.xlsx`.
- **`R4_node.m`** — produces the manuscript figures (and supplementary figures) and writes them to `Figure/` and `Supplementary Figures/`.

Helpers: `parseArgs.m`, `subaxis.m`, `suplabel.m` are utility functions used by the analysis and plotting scripts.

---

## Data availability
Precipitation data are from the **NOAA Monthly U.S. Climate Division** dataset (publicly available at <https://www.ncei.noaa.gov/>).  
Model outputs were produced using a modified version of the ecogeomorphic model developed by **Stewart et al. (2014)**; all modifications are detailed in **Supplementary Section S1**. The base model code is openly available in a **Zenodo** repository (link/DOI to be added).

---

## Manuscript abstract (context)
Regime shifts from grassland to shrubland are a key feature of dryland degradation, yet the role of connectivity in understanding these transitions remains poorly quantified. Using a connectivity‑based ecogeomorphic model with climate endmembers representing dry (Southwest Arizona) and wet (Northern New Mexico) conditions, we simulate vegetation change from 1895–2022. Under near‑natural grazing (1 g m⁻² yr⁻¹), grass biomass remained stable with negligible shrub presence. Moderate grazing (30%) initiated shrub emergence by 1930 in dry climates, while wetter systems largely retained grass (>20 g m⁻²). High grazing (60%) drove abrupt, near‑total grass loss, with shrub biomass exceeding 40 g m⁻² in dry and ~60 g m⁻² in wet climates. Connectivity metrics strongly predicted shrub expansion (up to r = 0.96 with shrub biomass), providing early‑warning signals **4–16 years** before vegetation shifts.

---

## Citing
Please cite:
1. This code repository.  
2. Stewart et al. (2014) model (Zenodo DOI).  
3. NOAA Monthly U.S. Climate Division dataset.


---

## License
Unless otherwise noted, code is released under the **MIT License**.

---

## Contact
Questions or issues: open a GitHub Issue or contact the corresponding author (Shubham Tiwari).
