#!/bin/bash
# ============================================================
# Cerebellar Seed-Based Functional Connectivity Pipeline
# ============================================================
#
# Performs subject-level cerebellar functional connectivity
# analysis and transforms connectivity maps into SUIT space.
#
# Workflow:
#   1. Transform SUIT-space ROIs into subject space
#   2. Extract seed time series from preprocessed fMRI data
#   3. Compute seed-to-voxel Pearson correlations
#   4. Apply Fisher r-to-z transformation
#   5. Transform connectivity maps into SUIT space
#   6. Resample and spatially smooth final connectivity maps
#
# Requirements:
#   AFNI
#   MATLAB
#   SPM12
#   SUIT toolbox
# Note: copy a mask_SUIT_3mm, which is basically a suit mask in 3mm res, in the dir folder
dir="/path/to/preprocessed/SUIT_data" #directory for where the preprocessed data is (errts, also have anatomical LPI,AC centered data in same folder)
refDir="/path/to/spm12/toolbox/suit"
ROI_dir="/path/to/SUIT_ROIs"
ROI=`cat $ROI_dir/suit_conn_7_rois.txt` 
scans=("same1" "same2")
subj=`cat "/path/to/subject_list.txt"`   


#get the rois in subject space
for sub in ${subj[@]}
do	
    for scan in ${scans[@]}
    do
        cd $refDir
        data_dir=$dir/$sub/$scan
        T1img=$data_dir/$sub.T1.LPI.nii
        echo "$T1img"
        3dbucket -overwrite -prefix $data_dir/stats.$sub.LPI_$scan.nii $data_dir/stats.$sub.LPI_$scan.nii[1]
        statsImg="$data_dir/stats.$sub.LPI_$scan.nii"
        echo "$statsImg"
        
        echo "matlab -nodesktop -nosplash -nodisplay -r roi_suit_to_sub('$data_dir', '$refDir', '$subj', '$T1img', '$statsImg'); catch ME, disp(ME.message); exit(1); end; exit;\""
        matlab -nodesktop -nosplash -nodisplay -r \
        "try, roi_suit_to_sub('$data_dir', '$refDir', '$sub', '$T1img', '$statsImg'); catch ME, disp(ME.message); end; exit;" \
         > "$data_dir/matlab_output.log" 2>&1

    done
done
#perform connectivity in subject space first, then run suit analysis on the whole brain connectivity map
for sub in ${subj[@]}
do	
    for scan in ${scans[@]}
    do
        output_dir=$dir/$sub/$scan
        #cp roi files to each scan folder
              
        errtsImg=$output_dir/errts.$sub.LPI_$scan.nii
        T1img=$output_dir/$sub.T1.LPI.nii
        for seed in ${ROI[@]}
        do
            echo "seed:$seed" 
            cd $output_dir
           
            in_file=$output_dir/errts.$sub.LPI_$scan.nii  #preprocessed epi data
            echo "$in_file"

            #======== Calculate correlation=======
                exec > >(tee -i script.log) 2>&1
                # Resample subject-space ROI to the fMRI grid
                3dresample -master ${in_file} -rmode NN -prefix res_subj_space_$seed.nii -inset iw_${seed}_u_a_$sub.T1.LPI_seg1.nii #get the seed image oriented with errts
                
                #get the mean seed time series
                3dROIstats -quiet -mask_f2short -mask res_subj_space_$seed.nii ${in_file} > ${sub}.${seed}_${scan}.1D  

                #compute seed-to-voxel pearson correlation
                3dTcorr1D -pearson -prefix pearson_${sub}.${seed}_${scan}.nii ${in_file} ${sub}.${seed}_${scan}.1D  

                # Fisher r-to-z transformed
                3dcalc -a pearson_${sub}.${seed}_${scan}.nii -expr 'atanh(a)' -prefix Z_pearson_${sub}.${seed}.nii 
                conn_map="$output_dir/Z_pearson_${sub}.${seed}.nii"
           
            #========= get connectivity map in suit space=====
                cd $refDir
                matlab -nodesktop -nosplash -nodisplay -r "try, suit_connectivity('$output_dir', '$refDir', '$sub', '$conn_map'); catch ME, disp(ME.message), exit(1); end; exit;" \
                > "$output_dir/matlab_output.log" 2>&1
            
            #=========post_suit_processing=========
                cd $output_dir
                if [ ! -d "final_conn_map" ]; then
                    mkdir -p "final_conn_map"
                else
                echo "Folder already exists."
                fi
    
                #Resampling to 3-mm resolution
                3dresample -dxyz 3 3 3 -input "wdZ_pearson_${sub}.${seed}.nii" -master "$dir/maskSUIT_3mm.nii" -prefix final_conn_map/wZ_pearson_${sub}.${seed}_3mm.nii
                
                #Spatial smoothing to 4-mm FWHM
                3dBlurToFWHM -input final_conn_map/wZ_pearson_${sub}.${seed}_3mm.nii -FWHM 4.0 -prefix final_conn_map/Z_pearson_${sub}.${seed}.${scan}_3mm_blurred.nii
                mv "$output_dir/3dFWHMx.1D" "$output_dir/3dFWHMx_${seed}.1D"
        done


    done
done 
exit 0
