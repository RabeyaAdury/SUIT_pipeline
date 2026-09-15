# SUIT Cerebellar Functional Connectivity Pipeline

## Overview

This repository contains a cerebellar functional connectivity pipeline that I developed using MATLAB, Bash, AFNI, SPM12, and the SUIT toolbox.

The pipeline transforms cerebellar ROIs from SUIT template space into individual subject space, performs seed-based functional connectivity analysis using preprocessed fMRI time series, and transforms the resulting connectivity maps back into SUIT space for cerebellum-specific analysis.

## Workflow

1. **Cerebellar segmentation and normalization**
   - Isolates and segments the cerebellum from the subject's T1-weighted image.
   - Estimates normalization between individual anatomy and SUIT template space.

2. **SUIT ROI → Subject Space**
   - Inverse-warps predefined cerebellar ROIs from SUIT space into individual subject space.

3. **Seed-Based Functional Connectivity**
   - Resamples each ROI to the fMRI data.
   - Extracts the mean ROI time series.
   - Computes seed-to-voxel Pearson correlations.
   - Applies Fisher r-to-z transformation.

4. **Subject Space → SUIT Space**
   - Transforms subject-level connectivity maps into SUIT space.
   - Resamples and spatially smooths the connectivity maps for downstream analysis.


## Scripts
### `SUIT_connectivity_corr.sh`
Main Bash driver that coordinates processing across subjects, runs, and cerebellar seeds. It performs ROI-based time-series extraction, seed-to-voxel correlation, Fisher z transformation, SUIT-space transformation, resampling, and smoothing.

### `roi_suit_to_sub.m`
Performs cerebellar isolation/segmentation and SUIT normalization, reslices the functional statistical image into SUIT space, and inverse-warps SUIT-space ROIs into individual subject space.

### `suit_connectivity.m`
Transforms subject-level functional connectivity maps into SUIT template space using the previously estimated affine and DARTEL transformations.

## Requirements

- MATLAB
- SPM12
- SUIT toolbox
- AFNI
- Bash/Linux

## Input Data

The pipeline requires:

- Preprocessed fMRI residual time series
- T1-weighted anatomical images
- Subject-level statistical maps
- Cerebellar ROIs defined in SUIT space
- Subject and ROI lists

The anatomical images used in this workflow are LPI-oriented and centered at the anterior commissure.

## Output

The pipeline generates subject-level:

- Cerebellar ROIs transformed into subject space
- ROI mean time series
- Seed-to-voxel correlation maps
- Fisher z-transformed connectivity maps
- Connectivity maps transformed into SUIT space
- Resampled and spatially smoothed maps for downstream analysis

## Notes

This pipeline was developed for my research analyses. Study-specific data, subject identifiers, and internal computing paths are not included in the public repository. Dataset-specific parameters, including ROI definitions, spatial resolution, smoothing, and file naming conventions, should be modified as appropriate for other datasets.
