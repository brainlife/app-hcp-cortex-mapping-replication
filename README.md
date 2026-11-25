<h1 align="center">Cortex Tissue Mapping: Fukutomi et al. 2018 Replication</h1>

<p align="center">
  DTI and NODDI measures mapped onto HCP native cortical surfaces and 32k fs_LR CIFTI maps, replicating the Fukutomi et al. (2018) NODDI cortex-mapping pipeline.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.430"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.430-blue.svg" alt="Run on brainlife.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="MIT license"></a>
</p>

## 🧠 At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Maps DTI and NODDI measures onto HCP PostFreeSurfer native and 32k fs_LR cortical surfaces with Connectome Workbench, replicating the Fukutomi et al. (2018) NODDI cortex-mapping pipeline.**

Ports the RIKEN NoddiSurfaceMapping code: warps the tensor and NODDI maps (plus a derived NODDI kappa) to MNI with the HCP acpc_dc2standard warp, maps them onto the native midthickness surface weighted by cortical thickness, masks vertices with b0 SNR below 10, and resamples to the 32k fs_LR mesh with MSMAll spheres. Requires HCP-style PostFreeSurfer outputs (MNINonLinear with Native and fsaverage_LR32k folders, MSMAll spheres); use the general Cortex Tissue Mapping Apps for FreeSurfer-only data. Requires a FreeSurfer license.

| | |
|---|---|
| 📥 **Inputs** | `neuro/dwi` · `neuro/freesurfer` · `neuro/hcp/freesurferpost` · `neuro/tensor` · `neuro/noddi` · `neuro/anat/t1w` · `neuro/mask` |
| 📤 **Outputs** | `neuro/cortexmap` · `raw` |
| 🐳 **Container** | `brainlife/fsl:5.0.9` |
| ⚙️ **Resources** | 8 CPUs · 16 GB memory · 1 h walltime |
| 🔑 **Requires** | `FREESURFER_LICENSE` |
| 🔗 **Run it** | [doi.org/10.25663/brainlife.app.430](https://doi.org/10.25663/brainlife.app.430) |

#### 📥 Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `dwi` | `neuro/dwi` | yes | DWI with bvals/bvecs; used to compute the b0 temporal SNR map for masking vertices. Must contain several b0 volumes. |
| `freesurfer` | `neuro/freesurfer` | yes | FreeSurfer output of the subject. |
| `postfreesurfer` | `neuro/hcp/freesurferpost` | yes | HCP PostFreeSurfer output; provides MNINonLinear native surfaces, labels, the acpc_dc2standard warp and the 32k fs_LR spheres. Must include MSMAll native spheres and the fsaverage_LR32k folder. |
| `tensor` | `neuro/tensor` | yes | DTI measures (fa, md, rd, ad) in DWI space. |
| `noddi` | `neuro/noddi` | yes | NODDI measures (ndi, isovf, odi) in DWI space; odi is also converted to a NODDI kappa map. |
| `anat` | `neuro/anat/t1w` | yes | T1-weighted image passed as the -fnirt source to wb_command -volume-warpfield-resample when warping measures to MNI. |
| `brainmask` | `neuro/mask` | yes | dwi brainmask |

#### 📤 Outputs

| Output | Datatype | Description |
|---|---|---|
| `cortexmap` | `neuro/cortexmap` | cortexmap with native surfaces, aparc.a2009s labels, and native and 32k fs_LR (MSMAll) func maps of each measure and SNR. |
| `raw` | `raw` | Intermediate derivatives (measure volumes, SNR images) for QA and debugging. |

<!-- brainlife-app:end -->

## 🏷️ Versions on brainlife.io

Each version is a separate App on brainlife.io, built from its own branch of this repository.

| Version | Connectome Workbench | Branch | Run it | Status |
|---|---|---|---|---|
| Cortex Tissue Mapping - Fukutomi et al 2018 Replication | 1.4.2b | [`v1.0`](https://github.com/brainlife/app-hcp-cortex-mapping-replication/tree/v1.0) | [doi:10.25663/brainlife.app.430](https://doi.org/10.25663/brainlife.app.430) | current |
| Cortex Tissue Mapping - Fukutomi et al 2018 Replication - DEPRECATED (takes `neuro/noddi-deprecated`) | 1.4.2b | [`master`](https://github.com/brainlife/app-hcp-cortex-mapping-replication/tree/master) | [doi:10.25663/brainlife.app.293](https://doi.org/10.25663/brainlife.app.293) | deprecated |

## 🚀 Running the App

### ☁️ On brainlife.io

Open the App at [doi.org/10.25663/brainlife.app.430](https://doi.org/10.25663/brainlife.app.430), choose the subject's `neuro/dwi`, `neuro/freesurfer`, HCP PostFreeSurfer output (`neuro/hcp/freesurferpost`), `neuro/tensor`, `neuro/noddi`, T1-weighted image and DWI brain mask, and press **Execute**. The App archives a `neuro/cortexmap` dataset and a `raw` dataset of intermediate derivatives.

This App is a port of the [NODDI cortex-mapping code](https://github.com/RIKEN-BCIL/NoddiSurfaceMapping) developed by Fukutomi et al.; the methods are described in their [2018 NeuroImage paper](https://www.sciencedirect.com/science/article/pii/S1053811918301058). It needs HCP-style PostFreeSurfer outputs (`MNINonLinear` with `Native`, `ROIs`, `xfms` and `fsaverage_LR32k` folders and MSMAll native spheres). The DWI must contain several b0 volumes, which are used for the SNR mask.

### 💻 Locally

You need [Singularity/Apptainer](https://apptainer.org/), [`jq`](https://jqlang.github.io/jq/) and a [FreeSurfer license](https://surfer.nmr.mgh.harvard.edu/registration.html). The App runs FSL from `brainlife/fsl:5.0.9` and Connectome Workbench from `brainlife/connectome_workbench:1.4.2b`.

1. Clone this repository and check out the App branch: `git checkout v1.0`.
2. Create `config.json` with the paths to your inputs:

   ```json
   {
       "dwi": "/input/dwi/dwi.nii.gz",
       "bvecs": "/input/dwi/dwi.bvecs",
       "bvals": "/input/dwi/dwi.bvals",
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

3. Export your license and run the App:

   ```bash
   export FREESURFER_LICENSE="$(cat ~/freesurfer/license.txt)"
   ./main
   ```

### 🧪 Sample data

Download sample datasets from brainlife.io with the [brainlife CLI](https://github.com/brainlife/cli):

```bash
npm install -g brainlife
bl login
mkdir input
bl dataset download <dataset-id>
```

## 📦 Outputs

The App computes a brain-masked b0 temporal SNR map, warps it and each measure (ad, fa, md, rd, ndi, isovf, odi and a NODDI kappa derived from odi) to MNI space with the HCP `acpc_dc2standard` warp, maps them onto the native midthickness surface with thickness-weighted ribbon mapping, masks vertices with SNR ≤ 10, and resamples them to the 32k fs_LR mesh with the MSMAll spheres.

```text
cortexmap/cortexmap/
├── func/    lh/rh.<measure>.func.gii on the native mesh, plus snr and goodvertex maps
├── label/   lh/rh.aparc.a2009s.native.label.gii
├── surf/    pial, white, midthickness, very_inflated, thickness, volume and roi files; ribbon.nii.gz
└── vol/     <measure>.MSMAll.32k_fs_LR.dscalar.nii CIFTI maps (with noddi_odi recomputed from kappa)
raw/         intermediate volumes (SNR images, warped measures, subcortical maps)
```

## 🩺 Troubleshooting

- **`failed`**: the native surface maps were not written. Check that the PostFreeSurfer output contains the `MNINonLinear/Native` surfaces and MSMAll spheres, the `fsaverage_LR32k` folder and `xfms/acpc_dc2standard.nii.gz`, and that `FREESURFER_LICENSE` is set.

## 📚 Citing

> [!TIP]
> If you use this App in your work, please cite the App, the software it builds on and brainlife.io (below). GitHub's **Cite this repository** button gives the App citation in APA and BibTeX.

- Fukutomi H, Glasser MF, Zhang H, Autio JA, Coalson TS, Okada T, Togashi K, Van Essen DC, Hayashi T. Neurite imaging reveals microstructural variations in human cerebral cortical gray matter. *NeuroImage* (2018). [Article](https://www.sciencedirect.com/science/article/pii/S1053811918301058)
- Cortex Tissue Mapping - Fukutomi et al  2018 Replication. brainlife.io App. [doi:10.25663/brainlife.app.430](https://doi.org/10.25663/brainlife.app.430)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Sci Data 6, 69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)
- Fischl. FreeSurfer. *NeuroImage* 62:774-781 (2012). [doi:10.1016/j.neuroimage.2012.01.021](https://doi.org/10.1016/j.neuroimage.2012.01.021)
- Jenkinson et al. FSL. *NeuroImage* 62:782-790 (2012). [doi:10.1016/j.neuroimage.2011.09.015](https://doi.org/10.1016/j.neuroimage.2011.09.015)
- Marcus et al. Informatics and Data Mining Tools and Strategies for the Human Connectome Project. *Frontiers in Neuroinformatics* 5 (2011). [doi:10.3389/fninf.2011.00004](https://doi.org/10.3389/fninf.2011.00004)
- Zhang et al. NODDI: Practical in vivo neurite orientation dispersion and density imaging of the human brain. *NeuroImage* 61:1000-1016 (2012). [doi:10.1016/j.neuroimage.2012.03.072](https://doi.org/10.1016/j.neuroimage.2012.03.072)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)

## 👥 Authors

- Brad Caron

**Contributors:** Soichi Hayashi

## 💰 Funding

[![Wellcome-226486/Z/22/Z](https://img.shields.io/badge/Wellcome-226486%2FZ%2F22%2FZ-purple.svg)](https://wellcome.org/)
[![NIH-NINDS-U24NS140384](https://img.shields.io/badge/NIH_NINDS-U24NS140384-green.svg)](https://reporter.nih.gov/project-details/11261037)
[![NIH-NINDS-UM1NS132207](https://img.shields.io/badge/NIH_NINDS-UM1NS132207-green.svg)](https://reporter.nih.gov/project-details/11411328)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://reporter.nih.gov/project-details/10262925)
[![NIH-NIBIB-R01EB030896](https://img.shields.io/badge/NIH_NIBIB-R01EB030896-green.svg)](https://reporter.nih.gov/project-details/10428625)
[![NIH-NIMH-R01MH126699](https://img.shields.io/badge/NIH_NIMH-R01MH126699-green.svg)](https://reporter.nih.gov/project-details/10460628)
[![NIH-NIDCD-R01DC020088](https://img.shields.io/badge/NIH_NIDCD-R01DC020088-green.svg)](https://reporter.nih.gov/project-details/11140284)
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-2203524](https://img.shields.io/badge/NSF_BCS-2203524-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2203524)
[![NSF-IIS-1636893](https://img.shields.io/badge/NSF_IIS-1636893-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-OAC-2148729](https://img.shields.io/badge/NSF_OAC-2148729-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148729)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NSF-IIS-2148700](https://img.shields.io/badge/NSF_IIS-2148700-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148700)
[![NSF-OAC-1916518](https://img.shields.io/badge/NSF_OAC-1916518-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1916518)

<sub>brainlife.io is publicly funded, and acknowledging that support helps keep it running. This App was developed with support from Wellcome, the U.S. National Institutes of Health (including the BRAIN Initiative BRAIN CONNECTS program: The Axonal Projectome EXchange, U24NS140384, and the Center for Mesoscale Connectomics, UM1NS132207) and the U.S. National Science Foundation.</sub>

## ⚖️ License

MIT, Copyright (c) 2020 brainlife.io, The University of Texas at Austin and Indiana University. FSL and Connectome Workbench are distributed under their own licenses.
