function roi_suit_to_sub(data_dir, refDir, subj, T1img, statsImg)
% ROI_SUIT_TO_SUBJECT
%
% Performs subject-level SUIT processing and transforms cerebellar ROIs
% from SUIT template space into individual subject space.
%
% Processing steps:
%   1. Isolate and segment the cerebellum from the T1-weighted image
%   2. Estimate normalization to SUIT template space using DARTEL
%   3. Reslice the functional/statistical image into SUIT space
%   4. Inverse-warp SUIT-space ROIs into subject space
%
% Inputs:
%   data_dir  - Subject/run directory containing anatomical and fMRI data
%   suit_dir  - Path to the SUIT toolbox
%   roi_dir   - Directory containing SUIT-space ROI masks
%   subj      - Subject identifier
%   T1img     - Subject T1-weighted image
%   statsImg  - Subject-level statistical image
%
% Requirements:
%   MATLAB
%   SPM12
%   SUIT toolbox
%% Initialize SPM and SUIT
    addpath(genpath(refDir));
    spm fmri
% Identify ROI files
roi_files = cellstr(spm_select('FPList', roi_dir, '\.nii$'));

    if isempty(roi_files)
        error('No ROI files found in: %s', roi_dir);
    end
    % Run cerebellum isolation & segmentation
    suit_isolate_seg({T1img});
    disp('processing');
    % Check output segmentation files
    grey = fullfile(data_dir, [ subj '.T1.LPI_seg1.nii']);
    white = fullfile(data_dir, [ subj '.T1.LPI_seg2.nii']);
    cereb = fullfile(data_dir, ['c_' subj '.T1.LPI_pcereb.nii']);
    
    if ~exist(grey, 'file') || ~exist(white, 'file') || ~exist(cereb, 'file')
        error('SUIT segmentation failed: required files not found.');
    end

    %% Step 2:  Normalize subject anatomy to SUIT space
    disp('Performing SUIT normalization...');
    job.subjND.gray = {grey};
    job.subjND.white = {white};
    job.subjND.isolation = {cereb};
    
    suit_normalize_dartel(job);
    dartel_deform_file = fullfile(data_dir, ['u_a_' subj '.T1.LPI_seg1.nii']);
    
    %% Step 3: Reslicing stats image to SUIT space
    disp('Reslicing stats.nii to SUIT space...');
    job.subj.affineTr = {fullfile(data_dir, ['Affine_' subj '.T1.LPI_seg1.mat'])};
    disp(job.subj.affineTr)
    job.subj.flowfield = {dartel_deform_file};
    disp(job.subj.flowfield)
    job.subj.resample = {statsImg};
    disp(job.subj.resample)
    job.subj.mask = {fullfile(data_dir, ['c_' subj '.T1.LPI_pcereb.nii'])};
    disp(job.subj.mask)
    suit_reslice_dartel(job);

    %% Step 4: Inverse Warping (Bring ROI back to subject space)
    disp('Performing inverse warping for ROI files...');
    for i = 1:length(roiFiles)
        roiFile = roiFiles{i};
        [~, roiName, ~] = fileparts(roiFile);  % Extract filename without extension
        output_roi = fullfile(data_dir, ['subj_space_' roiName '.nii']); % Define new name
        % Apply inverse warping
        job_inv.Affine = {fullfile(data_dir, ['Affine_' subj '.T1.LPI_seg1.mat'])};
        job_inv.flowfield = {dartel_deform_file};
        job_inv.resample = {roiFile};
        job_inv.ref = {T1img};  % Reference image for final geometry. T1 image in LPI orientation
        job_inv.outfilename = {output_roi};
        suit_reslice_dartel_inv(job_inv);
    end
    disp('Processing completed successfully.');
end
