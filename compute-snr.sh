#!/bin/bash

dwi=`jq -r '.dwi' config.json`
bvals=`jq -r '.bvals' config.json`
bvecs=`jq -r '.bvecs' config.json`
mask=`jq -r '.brainmask' config.json`

select_dwi_vols ${dwi} \
	${bvals} \
	nodif.nii.gz \
	0

fslmaths nodif.nii.gz -Tmean nodif_mean.nii.gz -odt float
fslmaths nodif.nii.gz -Tstd nodif_std.nii.gz -odt float
fslmaths nodif_mean.nii.gz -div nodif_std.nii.gz snr.nii.gz -odt float
fslmaths snr.nii.gz -mas ${mask} snr.nii.gz
