These scripts reproduce the experiments described in the article:

Xiaoqing Wang, Sebastian Rosenzweig, Nick Scholand, H.Christian M.Holme, Martin Uecker. <br>
**Model-Based Reconstruction for Simultaneous Multi-Slice T1 Mapping using Single-Shot Inversion-Recovery Radial FLASH**. <br>
Magnetic Resonance in Medicine: DOI: 10.1002/mrm.28497.[1,2]

The algorithms have been integrated into the Berkeley Advanced Reconstruction Toolbox (BART) [3] (version 0.7.00).

The raw files are hosted on ZENODO and must be downloaded first:

    
- Manual download: https://zenodo.org/record/3969809

- Download via script:
    - All files: `bash load_all.sh`
    - Individual files: `bash load.sh 3969809 <FILENAME>`. ( <FILENAME> without file extension. Then extract the *.tgz)

The other folders contain:

- `all.sh` scripts, which perfoms model-based image reconstructions for all data sets presented in the paper
- `run_xx.sh` scripts, which performs model-based image reconstruction for a specific data set
- `Figurex/Figx.sh` scripts, which create cfl files for the corresponding Figures and Videos.

The data can be viewed e.g. with 'view'[4] or be loaded into Matlab or Python using the wrappers provided in BART subdirectories './matlab' and './python'.

Running all scripts will take several days (a single data set may take a few hours) on a multi-core computer system!

If you need further help to run the scripts, I am happy to help you: xiaoqing.wang@med.uni-goettingen.de.


[1]. https://arxiv.org/abs/1909.10633
[2]. https://onlinelibrary.wiley.com/doi/10.1002/mrm.28497
[3]. https://mrirecon.github.io/bart
[4]. https://github.com/mrirecon/view
