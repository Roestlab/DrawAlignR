# DrawAlignR

An R package for the visualization of aligned ms2 chromatograms.

## Installation

To install this package, follow these commands:

``` r
## Check if devtools is available, else install it and load it
if(!require("devtools")) install.packages("devtools")
## Install BiocManager, BiocInstaller, zlibbioc, Rhdf5lib and mzR if not installed.
## *Note*: If you're using windows, you may have to restart your r session after each Bioconductor package install.  
## There may be times when BiocManager or one of the packages installed from BiocManager is not recognized as being installed until refreshing R's lib list.
if(!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
if(!require("BiocInstaller")) BiocManager::install("BiocInstaller")
if(!require("zlibbioc")) BiocManager::install("zlibbioc")
if(!require("Rhdf5lib")) BiocManager::install("Rhdf5lib")
if(!require("mzR")) BiocManager::install("mzR", suppressUpdates = TRUE)
## Use install_github to install necessary packages to run DrawAlignR
install_github("Roestlab/DrawAlignR", build_vignettes=FALSE, dependencies=TRUE, type="source")
## Load DrawAlignR
library(DrawAlignR)
DrawAlignR::runDrawAlignR()
```

## Overview

Illustration of general overview:

![](./inst/extdata/MAHMOODI_A_A1.PNG)

## Usage and Example

See Our Tutorial Vignette: [Tutorial_DrawAlignR.md](https://github.com/Roestlab/DrawAlignR/tree/master/vignettes/Tutorial_DrawAlignR.md)

## Example Dataset Availability

We have example datasets hosted on PeptideAtalas [PASS01520](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/PASS_View?identifier=PASS01520)


## Citation

Gupta, S., Sing, J., Mahmoodi, A., & Röst, H. (2020). DrawAlignR: An interactive tool for across run chromatogram alignment visualization. BioRxiv. https://doi.org/10.1101/2020.01.16.909143

Gupta S, Ahadi S, Zhou W, Röst H. "DIAlignR Provides Precise Retention Time Alignment Across Distant Runs in DIA and Targeted Proteomics." Mol Cell Proteomics. 2019 Apr;18(4):806-817. doi: https://doi.org/10.1074/mcp.TIR118.001132 Epub 2019 Jan 31.
