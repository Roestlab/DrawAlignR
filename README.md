# DrawAlignR

An R package for the visualization of aligned ms2 chromatograms.

## Installation

To install this package, follow these commands:

``` r
## Check if devtools is available, else install it and load it
if(!require("devtools")) install.packages("devtools")
library(devtools)
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
```

## Overview

Illustration of general overview:

![](./inst/extdata/MAHMOODI_A_A1.PNG)

## Docker Image

DrawAlignR has been dockerized, and the latest image can be found at: [singjust/drawalignr](https://hub.docker.com/repository/docker/singjust/drawalignr/tags?page=1)

### Using Docker Image

You first need to ensure you have [docker](https://docs.docker.com/install/) installed. 

#### Pulling Lastest Build
```
docker pull singjust/drawalignr:latest
```

#### Running Docker Image
```
docker run --name=drawalignr --user shiny --rm -v `pwd`:/data/ -p 3838:3838 singjust/drawalignr
```
**Flags**
* --name: assigns name to the container. Not necessary, but useful for reference
* --user: username to run image as
* --rm: automatically removes container when exited
* -v: allows you to mount a local volume to mounting point in container. In the example above, the local working directory (<code>`pwd`</code>) will be mounted to /data/ in the container.
* -p: specify the port from container to connect to local port.
* singjust/drawalignr: this is the docker image to run.

For more information, and for other flags, see [docker run](https://docs.docker.com/engine/reference/commandline/run/)

To view the tool, open a web browser and go to [localhost:3838](http://localhost:3838/)

The docker image also contains a sample test dataset, located at the following directory:
```
/srv/shiny-server/DrawAlignR/inst/extdata/test_data/
```

## Usage and Example

For example useage of DrawAlignR, see our tutorial vignette: [Tutorial_DrawAlignR.md](https://github.com/Roestlab/DrawAlignR/tree/master/vignettes/Tutorial_DrawAlignR.md), under the **DrawAlignR User Manual** section.

### Quick Start
```
## Load DrawAlignR
library(DrawAlignR)
## Run the app
DrawAlignR::runDrawAlignR()
```

## Expected Type of Input Data

DrawAlignR expects extracted ion chromatogram data and feature (peak-group) scoring data, which is generated/extracted from upstream workflows using OpenMS, OpenSWATH and Pyprophet.
Please see [Tutorial_DrawAlignR.md](https://github.com/Roestlab/DrawAlignR/tree/master/vignettes/Tutorial_DrawAlignR.md) for detailed instructions of expected input data, and the upstream workflows, under **Data Preparation** section.

## Example Dataset Availability

We have example datasets hosted on PeptideAtalas [PASS01520](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/PASS_View?identifier=PASS01520)

Please see [Tutorial_DrawAlignR.md](https://github.com/Roestlab/DrawAlignR/tree/master/vignettes/Tutorial_DrawAlignR.md), for instructions on how to download the tutorial dataset, under **Download Tutorial Dataset** section.

## Citation

Gupta, S., Sing, J., Mahmoodi, A., & Röst, H. (2020). DrawAlignR: An interactive tool for across run chromatogram alignment visualization. BioRxiv. https://doi.org/10.1101/2020.01.16.909143

Gupta S, Ahadi S, Zhou W, Röst H. "DIAlignR Provides Precise Retention Time Alignment Across Distant Runs in DIA and Targeted Proteomics." Mol Cell Proteomics. 2019 Apr;18(4):806-817. doi: https://doi.org/10.1074/mcp.TIR118.001132 Epub 2019 Jan 31.
