#!/bin/bash

# Note: copy a mask_SUIT_3mm, which is basically a suit mask in 3mm res, in the dir folder
#loc=`pwd`
dir=/media/mcuser/DATA-SL0/Human_dystonia/behavioral_corrected_data_proc/SUIT #directory for where the preprocessed data is (errts, also have anatomical LPI,AC centered data in same folder)
refDir=/media/mcuser/CardiB_Data3/CHU/Ref_scripts/spm12/toolbox/suit #where the suit functions are
ROI_dir=/media/mcuser/CardiB_Data3/CHU/Ref_images/SUIT_template/Lobule_atlas/7ROIs_5mm  #change the directory accordingly, for roi text file
ROI=`cat $ROI_dir/suit_conn_7_rois.txt`  #change the roi file name (needs a text file too?)
scans=(same1 same2)
subj=`cat /media/mcuser/DATA-SL0/Human_dystonia/behavioral_corrected_data_proc/id_dystonia.txt`    #the subject list needs to be in $data_dir


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
                3dresample -master ${in_file} -rmode NN -prefix res_subj_space_$seed.nii -inset iw_${seed}_u_a_$sub.T1.LPI_seg1.nii #get the seed image oriented with errts
                
                3dROIstats -quiet -mask_f2short -mask res_subj_space_$seed.nii ${in_file} > ${sub}.${seed}_${scan}.1D  #get the mean activation for each time point from the errts

                3dTcorr1D -pearson -prefix pearson_${sub}.${seed}_${scan}.nii ${in_file} ${sub}.${seed}_${scan}.1D  #compute pearson coefficient between the seed to epi image
                3dcalc -a pearson_${sub}.${seed}_${scan}.nii -expr 'atanh(a)' -prefix Z_pearson_${sub}.${seed}.nii # get the computed values Z transformed 
                conn_map="$output_dir/Z_pearson_${sub}.${seed}.nii"
            #========= get connectivity map in suit space=====
                cd $refDir
                matlab -nodesktop -nosplash -nodisplay -r "try, suit_connectivity('$output_dir', '$refDir', '$sub', '$conn_map'); catch ME, disp(ME.message), exit(1); end; exit;" \
                > "$output_dir/matlab_output.log" 2>&1
            #=========post_suit_processing=========
                cd $output_dir
                #rm 3dFWHMx*
                #rm dir "final_conn_map"
                mkdir "final_conn_map"
            #if [ ! -d "final_conn_map" ]; then
               # mv final_conn_map final_conn_map_older
            #    mkdir -p "final_conn_map"
            #else
            #    echo "Folder already exists."
            #fi
            3dresample -dxyz 3 3 3 -input "wdZ_pearson_${sub}.${seed}.nii" -master "$dir/maskSUIT_3mm.nii" -prefix final_conn_map/wZ_pearson_${sub}.${seed}_3mm.nii
            
            3dBlurToFWHM -input final_conn_map/wZ_pearson_${sub}.${seed}_3mm.nii -FWHM 4.0 -prefix final_conn_map/Z_pearson_${sub}.${seed}.${scan}_3mm_blurred.nii
            mv "$output_dir/3dFWHMx.1D" "$output_dir/3dFWHMx_${seed}.1D"
        done


    done
done 
exit 0