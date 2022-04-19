[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.430-blue.svg)](https://doi.org/10.25663/brainlife.app.430)

# Cortex Tissue Mapping - Fukutomi et al  2018 Replication

This app will map diffusion measures to the cortical surface. This application is a port of the NODDI Cortex Mapping code (https://github.com/RIKEN-BCIL/NoddiSurfaceMapping) developed by Fukutomi et al. The description of methodologies can be found in their 2018 Neuroimage paper (https://www.sciencedirect.com/science/article/pii/S1053811918301058?via%3Dihub). If used, please cite: Fukutomi, H., Glasser, M.F., Zhang, H., Autio, J.A., Coalson, T.S., Okada, T., Togashi, K., Van Essen, D.C., Hayashi, T., 2018. Neurite imaging reveals microstructural variations in human cerebral cortical gray matter. Neuroimage.

### Authors

- Brad Caron (bacaron@utexas.edu)

### Contributors

- Soichi Hayashi (shayashi@iu.edu)

### Funding Acknowledgement

brainlife.io is publicly funded and for the sustainability of the project it is helpful to Acknowledge the use of the platform. We kindly ask that you acknowledge the funding below in your publications and code reusing this code.

[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)

### Citations

We kindly ask that you cite the following articles when publishing papers and code using this code.

1. Avesani, P., McPherson, B., Hayashi, S. et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Sci Data 6, 69 (2019). https://doi.org/10.1038/s41597-019-0073-y

2. Fukutomi, H., Glasser, M.F., Zhang, H., Autio, J.A., Coalson, T.S., Okada, T., Togashi, K., Van Essen, D.C., Hayashi, T., 2018. Neurite imaging reveals microstructural variations in human cerebral cortical gray matter. Neuroimage.

#### MIT Copyright (c) 2020 brainlife.io The University of Texas at Austin and Indiana University

## Running the App

### On Brainlife.io

You can submit this App online at [https://doi.org/10.25663/brainlife.app.430](https://doi.org/10.25663/brainlife.app.430) via the 'Execute' tab.

### Running Locally (on your machine)

1. git clone this repo

2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files.

```json
{
    "dwi": "/input/dwi/dwi.nii.gz",
    "bvecs": "/input/dwi/bvecs.nii.gz",
    "bvals": "/input/dwi/bvals.nii.gz",
    "freesurfer": "/input/freesurfer/output",
    "postfreesurfer": "/input/postfreesurfer/output",
    "fa": "/input/tensor/fa.nii.gz",
    "md": "/input/tensor/md.nii.gz",
    "rd": "/input/tensor/rd.nii.gz",
    "ad": "/input/tensor/ad.nii.gz",
    "dir": "/input/noddi/dir.nii.gz",
    "ndi": "/input/noddi/ndi.nii.gz",
    "isovf": "/input/noddi/isovf.nii.gz",
    "odi": "/input/noddi/odi.nii.gz",
    "anat": "/input/anat/t1.nii.gz",
    "brainmask": "/input/brainmask/mask.nii.gz"
}
```

### Sample Datasets

You can download sample datasets from Brainlife using [Brainlife CLI](https://github.com/brain-life/cli).

```
npm install -g brainlife
bl login
mkdir input
bl dataset download
```

3. Launch the App by executing 'main'

```bash
./main
```

## Output

The main output of this App is a cortexmap datatype containing the surface-mapped files and a raw directory containing all of the derivatives generated during this app.

#### Product.json

The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing.

### Dependencies

This App only requires [singularity](https://www.sylabs.io/singularity/) to run. If you don't have singularity, you will need to install following dependencies.   

- FSL: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki
- Connectome Workbench: https://www.humanconnectome.org/software/connectome-workbench

#### MIT Copyright (c) 2020 brainlife.io The University of Texas at Austin and Indiana University
