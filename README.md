
*This is the updated version of SUIT (uses updated suit 12 toolbox/functions)
The matlab scripts are roi_suit_to_sub.m --- to get the rois transferred suit space to subject space.
The script is basically for connectivity, by product it will have beta coefficient file in SUIT space.
Once the rois are in subject space, it runs bash script to get connectivity maps
These scripts are in /media/mcuser/CardiB_Data3/CHU/Ref_scripts/spm12/toolbox/suit/ roi_suit_to_sub.m
The driver bash script is in /media/mcuser/CardiB_Data3/CHU/Chu_scripts/fMRI/SUIT_connectivity_corr_Adury.sh*


Main steps-
1.Have anatomical in LPI and AC origin
2. Have EPI in LPI
3. Run SUIT preprocessing steps for afni proc py. Only difference between the whole brain with SUIT afni proc py is, SUIT proc py won’t warp the anatomical in MNI space and won’t do blur.—the afni proc py will generate errts and stats file for connectivity and BOLD respectively.
The folder architecture is—Subject—scan (same1/same2)---> errts, anat and stats file. 
Note that,  a maskSUIT_3mm.nii template is expected in the $dir folder for resampling the output connectivity map.


Additional tips—may have some redundancy
We need preprocessed data for the connectivity analysis (errts). We also need anatomical file in the same folder. The anatomical file needs to be in LPI orientation and centered in the anterior commissure. Run copy_file_stage1 for copying the files and have it in LPI orientation. To set the origin on the AC, we need to manually set it. So load spm fmri in matlab and set the display for the LPI T1 image. And manually click on the AC and press set origin. For changing directories, go on the list of previous directories and click on the last one. From there, go up (..) one directory … move from there. 
Click on the set origin, then set orientation and done. Don’t need to save the matrix unless you want to use it, so click no.
 

In the bash script, edit dir (where preprocessed data is)
refDir- where the suit toolbox/functions are.
ROI_dir= the rois/seed that will be used to for the connectivity analysis
ROI= for roi names. Create txt file with roi names, same as the nii file for rois.
Subj= to cat the text file.

