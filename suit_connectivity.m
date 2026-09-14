function suit_connectivity(outputDir, refDir, sub, conn_map)
% SUIT_CONNECTIVITY
%
% Transforms a subject-level functional connectivity map from subject
% space into SUIT template space using previously estimated SUIT
% transformation files.
%
% Inputs:
%   output_dir - Subject/run directory containing SUIT transformation files
%   suit_dir   - Path to the SUIT toolbox
%   subj       - Subject identifier
%   conn_map   - Subject-level functional connectivity map
%
% Requirements:
%   MATLAB
%   SPM12
%   SUIT toolbox
%% Initialize SPM and SUIT
    addpath(genpath(refDir));
    spm fmri

%% Verify input directory and connectivity map
if ~exist(output_dir, 'dir')
    error('Output directory does not exist: %s', output_dir);
end

if ~exist(conn_map, 'file')
    error('Connectivity map not found: %s', conn_map);
end
 %   disp('Running SUIT segmentation...');
 %   suit_subj_dir = fullfile(outputDir, 'suit_segmentation');
 %   if ~exist(suit_subj_dir, 'dir')
 %       mkdir(suit_subj_dir);
 %   end
 %   cd(suit_subj_dir);

 %   %% Step 1: SUIT Segmentation (Isolate cerebellum & segment T1)
 %   disp('Running SUIT segmentation...');
    % Run cerebellum isolation & segmentation
 %   suit_isolate_seg({T1img});

    % Check output segmentation files
 %   grey = fullfile(suit_subj_dir, ['c_Z_pearson_' sub ' 'seed '_T1_seg1.nii']);
 %   white = fullfile(suit_subj_dir, ['c_' sub '_T1_seg2.nii']);
 %   cereb = fullfile(suit_subj_dir, ['c_' sub '_T1_pcereb.nii']);
    
 %   if ~exist(grey, 'file') || ~exist(white, 'file') || ~exist(cereb, 'file')
 %       error('SUIT segmentation failed: required files not found.');
 %   end

    %% Step 2: Normalization to SUIT Template
 %   disp('Performing SUIT normalization...');
 %   job.subjND.gray = {grey};
 %   job.subjND.white = {white};
 %   job.subjND.isolation = {cereb};
    
 %   suit_normalize_dartel(job);
    dartel_deform_file = fullfile(outputDir, ['u_a_' sub '.T1.LPI_seg1.nii']);
    
    %% Step 3: Reslicing stats image to SUIT space
    disp('Reslicing stats.nii to SUIT space...');
    job.subj.affineTr = {fullfile(outputDir, ['Affine_' sub '.T1.LPI_seg1.mat'])};
    job.subj.flowfield = {dartel_deform_file};
    job.subj.resample = {conn_map};
    job.subj.mask = {fullfile(outputDir, ['c_' sub '.T1.LPI_pcereb.nii'])};
    suit_reslice_dartel(job);
