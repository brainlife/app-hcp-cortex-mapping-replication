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
mkdir -p cortexmap ./cortexmap/func/ ./cortexmap/func/fsaverage_LR32k ./cortexmap/label ./cortexmap/surf/ ./cortexmap/vol/ metric raw

# copy metrics
met="${ad} ${fa} ${md} ${rd} ${isovf} ${od} ${icvf}"
for MET in ${met}
do
	cp ${MET} ./metric/
done

# copy over ribbon for vizualiation
cp -v ${AtlasSpaceFolder}/ribbon.nii.gz ./cortexmap/surf/

# copy over files for visualization and future stats
for hemi in ${HEMI}
do
	if [[ ${HEMI} == "lh" ]]; then
		CARET_HEMI="L"
	else
		CARET_HEMI="R"
	fi

	# aparc a2009s
	cp -v ${postfreesurfer}/MNINonLinear/Native/*.${CARET_HEMI}.aparc.a2009s.native.label.gii ./cortexmap/label/${HEMI}.aparc.a2009s.native.label.gii

	# pial
	cp -v ${postfreesurfer}/MNINonLinear/Native/*.${CARET_HEMI}.pial.native.surf.gii ./cortexmap/surf/${HEMI}.pial.surf.gii

	# white
	cp -v ${postfreesurfer}/MNINonLinear/Native/*.${CARET_HEMI}.white.native.surf.gii ./cortexmap/surf/${HEMI}.white.surf.gii

	# midthickness
	cp -v ${postfreesurfer}/MNINonLinear/Native/*.${CARET_HEMI}.midthickness.native.surf.gii ./cortexmap/surf/${HEMI}.midthickness.native.surf.gii

	# midthickness inflated
	cp -v ${postfreesurfer}/MNINonLinear/Native/*.${CARET_HEMI}.very_inflated.native.surf.gii ./cortexmap/surf/${HEMI}.midthickness.very_inflated.native.surf.gii

	# roi
	cp -v ${postfreesurfer}/MNINonLinear/Native/*.${CARET_HEMI}.roi.native.surf.gii ./cortexmap/surf/${HEMI}.roi.shape.gii
done

# generate volume measures mapped to surface
for hemi in ${HEMI}
do
    # volume-specific operations
    volume_name="volume.shape.gii"
    outdir="./cortexmap/surf"
    if [ ! -f ${outdir}/${hemi}.${volume_name} ]; then
    	mris_convert -c ${freesurfer}/surf/${hemi}.volume \
    		${freesurfer}/surf/${hemi}.white \
    		${outdir}/${hemi}.${volume_name}

		wb_command -set-structure ${outdir}/${hemi}.${volume_name} \
			${STRUCTURE}

		wb_command -set-map-names ${outdir}/${hemi}.${volume_name} \
			-map 1 ${hemi}_Volume

		wb_command -metric-palette ${outdir}/${hemi}.${volume_name} \
			MODE_AUTO_SCALE_PERCENTAGE \
			-pos-percent 2 98 \
			-palette-name Gray_Interp \
			-disp-pos true \
			-disp-neg true \
			-disp-zero true
		
		wb_command -metric-math "abs(volume)" \
			${outdir}/${hemi}.${volume_name} \
			-var volume \
			${outdir}/${hemi}.${volume_name}

		wb_command -metric-palette ${outdir}/${hemi}.${volume_name} \
			MODE_AUTO_SCALE_PERCENTAGE \
			-pos-percent 4 96 \
			-interpolate true \
			-palette-name videen_style \
			-disp-pos true \
			-disp-neg false \
			-disp-zero false
	fi
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
		./cortexmap/func/${hemi}.snr.func.gii \
		-myelin-style ribbon_${hemi}.nii.gz \
		${AtlasSpaceNativeFolder}/*.${caretHemi}.thickness.native.shape.gii \
		"$MappingSigma"
	
	# mask out non cortex
	wb_command -metric-mask ./cortexmap/func/${hemi}.snr.func.gii \
		${AtlasSpaceNativeFolder}/*.${caretHemi}.roi.native.shape.gii \
		./cortexmap/func/${hemi}.snr.func.gii

	# find "good" vertices (snr > 10)
	wb_command -metric-math 'x>10' ./cortexmap/func/${hemi}.goodvertex.func.gii \
		-var x \
		./cortexmap/func/${hemi}.snr.func.gii
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
        	        ./cortexmap/func/${hemi}.${vol}.func.gii \
                	-myelin-style ribbon_${hemi}.nii.gz \
                	${AtlasSpaceNativeFolder}/*.${caretHemi}.thickness.native.shape.gii \
                	"$MappingSigma"
		
		# mask surfaces by good vertices
		wb_command -metric-mask ./cortexmap/func/${hemi}.${vol}.func.gii \
			./cortexmap/func/${hemi}.goodvertex.func.gii \
			./cortexmap/func/${hemi}.${vol}.func.gii
		
		# dilate surface
		wb_command -metric-dilate ./cortexmap/func/${hemi}.${vol}.func.gii \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.midthickness.native.surf.gii \
			20 \
			./cortexmap/func/${hemi}.${vol}.func.gii \
			-nearest
		
		# mask surface by roi.native.shape
		wb_command -metric-mask ./cortexmap/func/${hemi}.${vol}.func.gii \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.roi.native.shape.gii \
			 ./cortexmap/func/${hemi}.${vol}.func.gii

		wb_command -set-map-name ./cortexmap/func/${hemi}.${vol}.func.gii \
			1 \
			"$caretHemi"_"$vol"

		wb_command -metric-palette ./cortexmap/func/${hemi}.${vol}.func.gii \
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

		wb_command -metric-resample ./cortexmap/func/${hemi}.${vol}.func.gii \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.sphere.MSMAll.native.surf.gii \
			${DownsampleFolder}/*.${caretHemi}.sphere.32k_fs_LR.surf.gii \
			ADAP_BARY_AREA \
			./cortexmap/func/fsaverage_LR32k/${hemi}.${vol}.MSMAll.32k_fs_LR.func.gii \
			-area-surfs \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.midthickness.native.surf.gii \
			${DownsampleFolder}/*.${caretHemi}.midthickness.32k_fs_LR.surf.gii \
			-current-roi \
			${AtlasSpaceNativeFolder}/*.${caretHemi}.roi.native.shape.gii

		wb_command -metric-mask ./cortexmap/func/fsaverage_LR32k/${hemi}.${vol}.MSMAll.32k_fs_LR.func.gii \
			${DownsampleFolder}/*.${caretHemi}.atlasroi.32k_fs_LR.shape.gii \
			./cortexmap/func/fsaverage_LR32k/${hemi}.${vol}.MSMAll.32k_fs_LR.func.gii

		wb_command -metric-smoothing ${DownsampleFolder}/*.${caretHemi}.midthickness.32k_fs_LR.surf.gii \
			./cortexmap/func/fsaverage_LR32k/${hemi}.${vol}.MSMAll.32k_fs_LR.func.gii \
			"${SmoothingSigma}" \
			./cortexmap/func/fsaverage_LR32k/${hemi}.${vol}.MSMAll_smooth.32k_fs_LR.func.gii \
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

	wb_command -cifti-create-dense-scalar ${vol}.MSMAll.32k_fs_LR.dscalar.nii \
		-volume ${vol}_AtlasSubcortical_smooth.nii.gz \
		Atlas_ROIs.2.nii.gz \
		-left-metric ./cortexmap/func/fsaverage_LR32k/lh.${vol}.MSMAll_smooth.32k_fs_LR.func.gii \
		-roi-left ${DownsampleFolder}/*.L.atlasroi.32k_fs_LR.shape.gii \
		-right-metric ./cortexmap/func/fsaverage_LR32k/rh.${vol}.MSMAll_smooth.32k_fs_LR.func.gii \
		-roi-right ${DownsampleFolder}/*.R.atlasroi.32k_fs_LR.shape.gii

	wb_command -set-map-names ${vol}.MSMAll.32k_fs_LR.dscalar.nii \
		-map 1 "${vol}"

	wb_command -cifti-palette ${vol}.MSMAll.32k_fs_LR.dscalar.nii \
		MODE_AUTO_SCALE_PERCENTAGE \
		${vol}.MSMAll.32k_fs_LR.dscalar.nii \
		-pos-percent 4 96 \
		-interpolate true \
		-palette-name videen_style \
		-disp-pos true \
		-disp-neg false \
		-disp-zero false
done

wb_command -cifti-math 'max(2*atan(1/kappa)/PI,0)' noddi_odi.MSMAll.32k_fs_LR.dscalar.nii \
	-var kappa noddi_kappa.MSMAll.32k_fs_LR.dscalar.nii

wb_command -set-map-names noddi_odi.MSMAll.32k_fs_LR.dscalar.nii \
                -map 1 "od"

wb_command -cifti-palette noddi_odi.MSMAll.32k_fs_LR.dscalar.nii \
                MODE_AUTO_SCALE_PERCENTAGE \
                ${vol}.MSMAll.32k_fs_LR.dscalar.nii \
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
if [ -f ./cortexmap/func/lh.isovf.func.gii ]; then
	mv *.dscalar* ./cortexmap/vol/
	mv *.nii* ./raw/
	rm -rf cortexmap/func/fsaverage_LR32k
	echo "complete"
	exit 0
else
	echo "failed"
	exit 1
fi
