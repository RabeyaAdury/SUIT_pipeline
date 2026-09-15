function suit_connectivity(outputDir, refDir, sub, conn_map)
% SUIT_CONNECTIVITY
%
% Transforms a subject-level functional connectivity map from subject
% space into SUIT template space using SUIT transformation files.
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
        
    %% Locate existing SUIT transformation files
    dartel_deform_file = fullfile(outputDir, ['u_a_' sub '.T1.LPI_seg1.nii']);
    
    if ~exist(affine_file, 'file')
        error('Affine transformation not found for subject %s.', sub);
    end
    
    %% Transform connectivity map from subject space to SUIT space
    fprintf('Transforming connectivity map to SUIT space for subject %s...\n', sub);
    job.subj.affineTr = {fullfile(outputDir, ['Affine_' sub '.T1.LPI_seg1.mat'])};
    job.subj.flowfield = {dartel_deform_file};
    job.subj.resample = {conn_map};
    job.subj.mask = {fullfile(outputDir, ['c_' sub '.T1.LPI_pcereb.nii'])};
    suit_reslice_dartel(job);

    fprintf('SUIT transformation completed for subject %s.\n', sub);

end
    
