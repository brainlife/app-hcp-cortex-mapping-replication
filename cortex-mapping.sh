#!/bin/bash

## This script will create a midthickness surface, map tensor and NODDI values to this surface, and compute stats for each ROI from Freesurfer parcellation

# # Set subject directory in Freesurfer
# export SUBJECTS_DIR=./

# parse inputs
freesurfer=`jq -r '.freesurfer' config.json`
postfreesurfer=`jq -r '.postfreesurfer' config.json`;
dwi=`jq -r '.dwi' config.json`;
fa=`jq -r '.fa' config.json`;
ad=`jq -r '.ad' config.json`;
md=`jq -r '.md' config.json`;
rd=`jq -r '.rd' config.json`;
ndi=`jq -r '.ndi' config.json`;
isovf=`jq -r '.isovf' config.json`;
odi=`jq -r '.odi' config.json`;
anat=`jq -r '.anat' config.json`;

# set paths and variables
diffRes="`fslval ${dwi} pixdim1 | awk '{printf "%0.2f",$1}'`"
MappingFWHM="` echo "$diffRes * 2.5" | bc -l`"
MappingSigma=` echo "$MappingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
SmoothingFWHM=$diffRes
SmoothingSigma=` echo "$SmoothingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
BrainOrdinateResolution=2
AtlasSpaceFolder="${postfreesurfer}/MNINonLinear"
AtlasSpaceNativeFolder="${AtlasSpaceFolder}/Native"
AtlasSpaceROIFolder="${AtlasSpaceFolder}/ROIs"
AtlasSpaceXfmsFolder="${AtlasSpaceFolder}/xfms"
METRIC="ad fa md rd ndi isovf odi"
HEMI="lh rh"

# make directories
mkdir -p cortexmap ./cortexmap/func/ ./cortexmap/func/fsaverage_LR32k ./cortexmap/surf/ ./cortexmap/vol/ metric raw

# copy metrics
met="${ad} ${fa} ${md} ${rd} ${isovf} ${od} ${icvf}"
for MET in ${met}
do
	cp ${MET} ./metric/
done

## extract hemispheric ribbons
fslmaths ${AtlasSpaceFolder}/ribbon.nii.gz -thr 3 -uthr 3 -bin ./ribbon_lh.nii.gz
fslmaths ${AtlasSpaceFolder}/ribbon.nii.gz -thr 42 -uthr 42 -bin ./ribbon_rh.nii.gz

# mv t1-2mm and atlas rois-2mm to local dir
cp ${AtlasSpaceFolder}/T1w_restore.2.nii.gz ./
cp ${AtlasSpaceROIFolder}/Atlas_ROIs.2.nii.gz ./

# map odi to kappa
wb_command -volume-math 'max(1/tan((od*PI)/2),0)' ./metric/noddi_kappa.nii.gz -var od ${od} 1>/dev/null
METRIC="ad fa md rd icvf isovf noddi_kappa"

# SNR surface mapping
wb_command -volume-warpfield-resample snr.nii.gz \
	${AtlasSpaceXfmsFolder}/acpc_dc2standard.nii.gz \
	${AtlasSpaceFolder}/T1w_restore.nii.gz \
	CUBIC snr_T1.nii.gz \
	-fnirt ${anat}

for hemi in $HEMI
do
	if [[ $hemi == "lh" ]]; then
		caretHemi="L"
	else
		caretHemi="R"
	fi
	# map snr
	wb_command -volume-to-surface-mapping snr_T1.nii.gz \
		${AtlasSpaceNativeFolder}/*.${caretHemi}.midthickness.native.surf.gii \
		./cortexmap/func/${caretHemi}.snr.native.func.gii \
		-myelin-style ribbon_${hemi}.nii.gz \
		${AtlasSpaceNativeFolder}/*.${caretHemi}.thickness.native.shape.gii \
		"$MappingSigma"
	
	# mask out non cortex
	wb_command -metric-mask ./cortexmap/func/${caretHemi}.snr.native.func.gii \
		${AtlasSpaceNativeFolder}/*.${caretHemi}.roi.native.shape.gii \
		./cortexmap/func/${caretHemi}.snr.native.func.gii

	# find "good" vertices (snr > 10)
	wb_command -metric-math 'x>10' ./cortexmap/func/${caretHemi}.goodvertex.native.func.gii \
		-var x \
		./cortexmap/func/${caretHemi}.snr.native.func.gii
done

# metric surface mapping
for vol in ${METRIC}
do
	wb_command -volume-warpfield-resample ./metric/${vol}.nii.gz \
        	${AtlasSpaceXfmsFolder}/acpc_dc2standard.nii.gz \
        	${AtlasSpaceFolder}/T1w_restore.nii.gz \
        	CUBIC ${vol}.nii.gz \
        	-fnirt ${anat}

	for hemi in $HEMI
	do
		if [[ $hemi == "lh" ]]; then
			caretHemi="L"
        	else
                	caretHemi="R"
        	fi
		
		# map volumes to surface
		wb_command -volume-to-surface-mapping ${vol}.nii.gz \
	                ${AtlasSpaceNativeFolder}/*.${caretHemi}.midthickness.native.surf.gii \
        	        ./cortexmap/func/${caretHemi}.${vol}.native.func.gii \
                	-myelin-style ribbon_${hemi}.nii.gz \
                	${AtlasSpaceNativeFolder}/*.${caretHemi}.thickness.native.shape.gii \
                	"$MappingSigma"
		
		# mask surfaces by good vertices
		wb_command -metric-mask ./cortexmap/func/${caretHemi}.${vol}.native.func.gii \
			./cortexmap/func/${caretHemi}.goodvertex.native.func.gii \
			./cortexmap/func/${caretHemi}.${vol}.native.func.gii
		
		# dilate surface
		wb_command -metric-dilate ./cortexmap/func/${caretHemi}.${vol}.native.func.gii \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.midthickness.native.surf.gii \
			20 \
			./cortexmap/func/${caretHemi}.${vol}.native.func.gii \
			-nearest
		
		# mask surface by roi.native.shape
		wb_command -metric-mask ./cortexmap/func/${caretHemi}.${vol}.native.func.gii \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.roi.native.shape.gii \
			 ./cortexmap/func/${caretHemi}.${vol}.native.func.gii

		wb_command -set-map-name ./cortexmap/func/${caretHemi}.${vol}.native.func.gii \
			1 \
			"$caretHemi"_"$vol"

		wb_command -metric-palette ./cortexmap/func/${caretHemi}.${vol}.native.func.gii \
			MODE_AUTO_SCALE_PERCENTAGE \
			-pos-percent 4 96 \
			-interpolate true \
			-palette-name videen_style \
			-disp-pos true \
			-disp-neg false \
			-disp-zero false
	done
done

# resample to low res and high res meshes
for vol in ${METRIC}
do
	for hemi in $HEMI
	do
		if [[ $hemi == "lh" ]]; then
			caretHemi="L"
		else
			caretHemi="R"
		fi

		DownsampleFolder=${AtlasSpaceFolder}/fsaverage_LR32k

		wb_command -metric-resample ./cortexmap/func/${caretHemi}.${vol}.native.func.gii \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.sphere.MSMAll.native.surf.gii \
			${DownsampleFolder}/*.${caretHemi}.sphere.32k_fs_LR.surf.gii \
			ADAP_BARY_AREA \
			./cortexmap/func/fsaverage_LR32k/${caretHemi}.${vol}MSMAll.32k_fs_LR.func.gii \
			-area-surfs \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.midthickness.native.surf.gii \
			${DownsampleFolder}/*.${caretHemi}.midthickness.32k_fs_LR.surf.gii \
			-current-roi \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.roi.native.shape.gii

		wb_command -metric-mask ./cortexmap/func/fsaverage_LR32k/${caretHemi}.${vol}MSMAll.32k_fs_LR.func.gii \
			${DownsampleFolder}/*.${caretHemi}.atlasroi.32k_fs_LR.shape.gii \
			./cortexmap/func/fsaverage_LR32k/${caretHemi}.${vol}MSMAll.32k_fs_LR.func.gii

		wb_command -metric-smoothing ${DownsampleFolder}/*.${caretHemi}.midthickness.32k_fs_LR.surf.gii \
			./cortexmap/func/fsaverage_LR32k/${caretHemi}.${vol}MSMAll.32k_fs_LR.func.gii \
			"${SmoothingSigma}" \
			./cortexmap/func/fsaverage_LR32k/${caretHemi}.${vol}MSMAll_smooth.32k_fs_LR.func.gii \
			-roi \
			${DownsampleFolder}/*.${caretHemi}.atlasroi.32k_fs_LR.shape.gii
	done

	wb_command -volume-warpfield-resample ./metric/${vol}.nii.gz \
		${AtlasSpaceXfmsFolder}/acpc_dc2standard.nii.gz \
		T1w_restore.2.nii.gz \
		CUBIC \
		${vol}.2.nii.gz \
		-fnirt ${anat}

	wb_command -volume-parcel-resampling ${vol}.2.nii.gz \
		${AtlasSpaceROIFolder}/ROIs.2.nii.gz \
		Atlas_ROIs.2.nii.gz \
		${SmoothingSigma} \
		${vol}_AtlasSubcortical_smooth.nii.gz \
		-fix-zeros

	wb_command -cifti-create-dense-scalar ${vol}MSMAll.32k_fs_LR.dscalar.nii \
		-volume ${vol}_AtlasSubcortical_smooth.nii.gz \
		Atlas_ROIs.2.nii.gz \
		-left-metric ./cortexmap/func/fsaverage_LR32k/L.${vol}MSMAll_smooth.32k_fs_LR.func.gii \
		-roi-left ${DownsampleFolder}/*.L.atlasroi.32k_fs_LR.shape.gii \
		-right-metric ./cortexmap/func/fsaverage_LR32k/R.${vol}MSMAll_smooth.32k_fs_LR.func.gii \
		-roi-right ${DownsampleFolder}/*.R.atlasroi.32k_fs_LR.shape.gii

	wb_command -set-map-names ${vol}MSMAll.32k_fs_LR.dscalar.nii \
		-map 1 "${vol}"

	wb_command -cifti-palette ${vol}MSMAll.32k_fs_LR.dscalar.nii \
		MODE_AUTO_SCALE_PERCENTAGE \
		${vol}MSMAll.32k_fs_LR.dscalar.nii \
		-pos-percent 4 96 \
		-interpolate true \
		-palette-name videen_style \
		-disp-pos true \
		-disp-neg false \
		-disp-zero false
done

wb_command -cifti-math 'max(2*atan(1/kappa)/PI,0)' noddi_odMSMAll.32k_fs_LR.dscalar.nii \
	-var kappa noddi_kappaMSMAll.32k_fs_LR.dscalar.nii

wb_command -set-map-names noddi_odMSMAll.32k_fs_LR.dscalar.nii \
                -map 1 "od"

wb_command -cifti-palette noddi_odMSMAll.32k_fs_LR.dscalar.nii \
                MODE_AUTO_SCALE_PERCENTAGE \
                ${vol}MSMAll.32k_fs_LR.dscalar.nii \
                -pos-percent 4 96 \
                -interpolate true \
                -palette-name videen_style \
                -disp-pos true \
                -disp-neg false \
                -disp-zero false


for vol in ${METRIC}
do
	for hemi in ${HEMI}
	do
                if [[ $hemi == "lh" ]]; then
                        caretHemi="L"
                else
                        caretHemi="R"
                fi

		rm -rf ./cortexmap/func/fsaverage_LR32k/${caretHemi}.${vol}MSMAll.32k_fs_LR.func.gii
		rm -rf ./cortexmap/func/fsaverage_LR32k/${caretHemi}.${vol}MSMAll_smooth.32k_fs_LR.func.gii
	done
done

# clean up
if [ -f ./cortexmap/func/L.isovf.native.func.gii ]; then
	cp ${AtlasSpaceNativeFolder}/*.midthickness.native.surf.gii ./cortexmap/surf/
	mv *.dscalar* ./cortexmap/vol/
	mv *.nii* ./raw/
	rm -rf cortexmap/func/fsaverage_LR32k
	echo "complete"
	exit 0
else
	echo "failed"
	exit 1
fi
