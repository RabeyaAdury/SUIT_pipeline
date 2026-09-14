function roi_suit_to_sub(data_dir, refDir, subj, T1img, statsImg)
    % Add SUIT toolbox to path
    addpath(genpath(refDir));
    spm fmri
    roiDir='/media/mcuser/CardiB_Data3/CHU/Ref_images/SUIT_template/Lobule_atlas/7ROIs_5mm';
    
    roiFiles= cellstr(spm_select('FPList', roiDir, '\.nii$'));  %spm_select returns character array, celltstr converts it in string
    %% Step 1: SUIT Segmentation (Isolate cerebellum & segment T1)
    disp('Running SUIT segmentation...');
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

    %% Step 2: Normalization to SUIT Template
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
