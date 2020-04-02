<center> 
<h1> 
DrawAlignR: An interactive tool for across run chromatogram alignment visualization
</h1> 
</center>
<br/>
<center> 
<h2>
Justin Sing, Shubham Gupta, Arshia Mahmoodi, and Hannes Rӧst
</h2>
<h3>

</h3>
</center>

<div style="page-break-after: always;"></div>

# Contents

<br/>

1. [<h2> Data Preparation </h2>](#Data_Preparation)
    * [<h2> Performing Full OpenSwathWorkflow </h2>](#osw_top)
        * [<h2> Generating Library / Targeted Assay </h2>](#PQP_Gen)
        * [<h2> Running an OpenSwathWorkflow </h2>](#run_osw)
        * [<h2> Scoring with PyProphet </h2>](#pyprophet_score)
    * [<h2> Required Input Data for DrawAlignR </h2>](#Expected_Data_DrawAlignR)
    * [<h2> Downloading Tutorial Dataset </h2>](#Tutorial_Data)
2. [<h2> DrawAlignR User Manual </h2>](#User_Manual)
    * [<h2> Getting Started </h2>](#Getting_Started)
    * [<h2> Performing Alignment </h2>](#Performing_Alignment)
    * [<h2> Graphical Elements </h2>](#Graphical_Elements)

<div style="page-break-after: always;"></div>

<a name="Data_Preparation"></a>
# Data Preparation

DrawAlignR requires three types of files that are generated through an OpenSWATH Workflow using OpenMS tools.

For more information on OpenMS, please visit [https://www.openms.de/](https://www.openms.de/)

For more informaiton on the OpenSWATH workflow, please visit [http://openswath.org/en/latest/](http://openswath.org/en/latest/)

Before running an OpenSwathWorkflow, you will need to ensure you have the correct input formats.
You can convert all raw MS data to standard mzML/mzXML format using [ProteoWizard-MSConvert](http://proteowizard.sourceforge.net/tools.shtml).

<a name="osw_top"></a>

<a name="PQP_Gen"></a>
## Library / Assay Generation

### Generating the Target Assay Library

To generate the Targeted Assay library you need to run two OpenMS tools. `OpenSwathAssayGenerator` and 
`OpenSwathDecoyGenerator`. The former will generate assays for each target pepetide in the dda spectral library, the 
latter will append decoys to the targeted assay library from FDR estimation.

#### OpenSwathAssayGenerator

This tool has several parameters that you can adjust to tweak your target library. To understand what the parameters are, you can visit `[https://abibuilder.informatik.uni-tuebingen.de/archive/openms/Documentation/release/latest/html/OpenMS_tutorial.html](https://abibuilder.informatik.uni-tuebingen.de/archive/openms/Documentation/release/latest/html/OpenMS_tutorial.html).
This includes the documentation for the rest of OpenMS tools.

```
$ ./build/openms_build/bin/OpenSwathAssayGenerator -in ./dda_spectral_library/psgs_standard_consensus_Phospho_pep.TraML -out ./psgs_phospho_optimized.TraML
```

#### OpenSwathDecoyGenerator

To estimate true signal (true peptides at feature x), we need to differentiate/separate true positives from false
positives. In order to do this, we use the decoy model that puts in false signal/peptides. This tool also has several
different flags that you can set, such as different decoy methods: `shuffling`, `reverse`, `pseudo-reverse`, etc. and
switchKR which switches lysine/argine ends. You can also adjust the ratio of decoy:targets.

```
$ ./build/openms_build/bin/OpenSwathDecoyGenerator -in ./psgs_phospho_optimized.TraML -out ./psgs_phospho_optimized_decoys.TraML
```

<div style="page-break-after: always;"></div>

#### TargetedFileConverter

Newer versions of OpenMS have moved towards sqlite data structures, due to more efficient data storage useage. You
should convert the TraML target assay library generated in the previous step to the `pqp` sqlite format.

```
$ ./build/openms_build/bin/TargetedFileConverter -in psgs_phospho_optimized_decoys.TraML -out psgs_phospho_optimized_decoys.pqp
```

<a name="run_osw"></a>
## OpenSwathWorkflow

Now that you have generated the targeted assay library, you are ready to run OpenSwathWorkflow.

### Default OpenSwathWorkflow

File names below are used as an example, make the output names more understandable.

**NOTE:** You need to run the OpenSwathWorkflow for each raw MS run file you have.
```
$ ./build/openms_build/bin/OpenSwathWorkflow \
        -in ./run1.mzXML \ ## Raw mzXML data file
        -tr ./lib/psgs/pqp \ ## Targeted assay library file
        -tr_irt ./IRT.TraML \ ## IRT peptides library file
        -out_osw ./run1_MSDATA_RESULTS.osw \ ## name of output file, output can be .tsv file or .osw (sqlite) file.
        -out_chrom run1.chrom.mzML  \ ## if you want to generate chromatogram output file. Can be .mzMl or sqMass (sqlite).
        -batchSize 1000 \ ## Size in which to split the data up into for extraction and scoring
        -readOptions cacheWorkingInMemory \ ## read the data on the fly, or read from cached in memory
        -tempDirectory ~/scratch/ \ ## temporary directroy to store cached files
        -threads 6 \ ## number of threads to use for computation
        -debug 10 ## debug level, debug 10 will spit out verbose information, helpful for debugging
```

<div style="page-break-after: always;"></div>

<a name="pyprophet_score"></a>
## Pyprophet

After running OpenSwathWorkflow you want to score the results (extracted peak groups from OpenSwathWorkflow) and estimate the FDR distribution. To do that you can use
[pyprophet](http://openswath.org/en/latest/docs/pyprophet.html). 

Pyprophet contains several steps of it's own.

### Pyprophet Merge

You first want to merge each individual osw run file into one osw file, this make things easier for running the workflow
and getting global estimates. You can also run it on each file indivdiually, but generally we run the workflow on a
merged.osw file.

```
pyprophet merge --template=./lib/psgs_phospho_optimized_decoys.pqp --out=merged.osw $(find ./results/ -maxdepth 2 -type f -name *_MSDATA_RESULTS.osw)
```

The command above will call the pyprophet merge function, and merge all the osw files (that are found using the bash
find function to return all the files matching "*_MSDATA_RESULTS.osw"), into one osw file using the library file as a
template.

### Pyprophet Scoring

After you have a merged osw file, you want to perform the semi-supervised scoring algorithm.

Generally you would only need to score on the MS2 level. However, you can also use an integrated scoring on the
--level=`ms1ms2`, this will integrate the scores between MS1 features and MS2 features.
```
pyprophet score --in=./merged.osw --level=ms2 --ss_num_iter=10 --xeval_num_iter=10 --threads=10
```
The command above will score on the merged_runs.osw file, using the MS2 features, using the semi-supervised learning on
10 iterations (this is the default) and performing 10 cross-validations (this is the default) using 10 threads.

<div style="page-break-after: always;"></div>

<a name="Expected_Data_DrawAlignR"></a>
## Required Input Data for DrawAlignR

### Directory Structure

To make things easier, and to have a contained experiment, DrawAlignR utilizes a structured directory as input. \
The top level experiment directory should contain sub-directories: 
* containing the merged pyprophet scored `osw` file obtained from the OpenSwathWorkflow and pyprophet scoring workflow, 
* the extracted chromatogram files (`mzML` or `sqMass`) obtained from OpenSwathWorkflow, and 
* the `pqp` library assay file obtained from OpenSwathAssayGenerator and OpenSwathDecoyGenerator. 

DrawAlignR, can alternatively also allow for individual file input without having a structured working directory, however, it is suggested to have one. \
Please see below for an example structured working directory.

#### An example Working Directory should be ideally structured and named as below:
```
/Project_Working_Directory
|__/mzml
|   |__/run0.chrom.mzML
|   |__/run1.chrom.mzML
|__/osw
|   |__/merged.osw
|__/pqp
|   |__/assay_library.pqp
|__/sqmass(Optional, either mzml or sqmass format is acceptable)
|   |__/run1.chrom.sqMass
|   |__/run1.chrom.sqMass

```

### Data Size

Depending on how complex your experiments are and how many runs you may have, the extracted chromatogram files may be large files. The larger your files are, the longer it may take for DrawAlignR to cache all chromatographic data into memory, this is something to keep in mind.

<div style="page-break-after: always;"></div>

<a name="Tutorial_Data"></a>
## Downloading Tutorial Dataset

We have example datasets hosted on PeptideAtalas [PASS01520](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/PASS_View?identifier=PASS01520) 

This dataset contains two datasets, which both have a full dataset and a smaller data subset:
* Spyogenes
    * Spyogenes_Full
    * Spyogenes_Small_Subset
* Synthetic_Phosphopeptide_Dataset
    * Synthetic_Dilution_Phosphoproteomics_Full
    * Synthetic_Dilution_Phosphoproteomics_Small_Subset

**NOTE:** Using the smaller data subsets, will be quicker for tests, and alignment parameter checks, since loading full extracted chromatogram data may take longer to cache into memory.

The easiest and most straight forward way of downloading the data is to use your browser's FTP mode: ftp://PASS01520:HE7445u@ftp.peptideatlas.org/

### Retrieving Data on MacOS

MacOS is capable of establishing a connection to a remote FTP server using the native Finder application.
* Open a **Finder Window**
* From the main menu, select **Go** -> **connect to Server**
* In the pop-up dialog box, type `ftp://PASS01520:HE7445u@ftp.peptideatlas.org/` in the *Server Address:* field
* Press **Connect**
* enter Username/Password
    * Username: PASS01520
    * Password: HE7445u

Alternatively, you can type the ftp address into a safari browser.

### Retrieve Data on Windows

On Windows, you can use the Windows file manager/ File Explorer to connect to a remote FTP server.
* Open a **File Explorer**
* Right click on **This PC / Computer**
    ** Select **Add a network location**
* Go through pop-up wizard and select **Choose a custom network location**
* In the “Specify the location of your website” dialog, enter `ftp://PASS01520:HE7445u@ftp.peptideatlas.org/`
* enter Username/Password
    * Username: PASS01520
    * Password: HE7445u

<div style="page-break-after: always;"></div>

### Retrieve Data on Linux/ Ubuntu

On Ubuntu, you can use nautilus file manager to connect to a remote FTP server.
* Click on  **Other Locations**
* In the bottom field to the right of *Connect to Server**, enter `ftp://PASS01520:HE7445u@ftp.peptideatlas.org/`
* enter Username/Password
    * Username: PASS01520
    * Password: HE7445u

<div style="page-break-after: always;"></div>

<a name="User_Manual"></a>
# Using/ Calling DrawAlignR

The visualization tool can be called via two methods, either via installing the repository using devtools github package installer or by calling shiny::runGitHub.

<a name="Getting_Started"></a>

## Calling tool via Installing DrawAlignR
```
### Install devtools if not already installed.
## install.packages("devtools")
## Install DrawAlignR from Roestlab Github Repository
devtools::install_github("Roestlab/DrawAlignR")
## To run the tool
DrawAlignR::runDrawAlignR()
```

OR

## Calling tool via Github repo
```
### Install shiny
## install.packages("shiny")
shiny::runGitHub(repo = "Roestlab/DrawAlignR/", username = "Roestlab", subdir = "inst/shiny-script")
```

# User Interface

There are three major tabs in the left side pannel:
* **General Settings**
    * These are general settings for uploading chromatogram files (.mzML or .sqMass), library assay files (.pqp), OpenSwathWorkflow results file (.osw). The user can also set the working directory that contains sub-directroys for osw and mzml files. 
    * The user selects the peptide and charge state to visualize.
    * The user selects how many plots to show for each chromatogram run file suppled.
    * The user can select the alignment option to perform an alignment for the selected peptide.
    * The user can visualize the reference plot, experiment plot and the experiment aligned plot.
* **Alignment Settings**
    * The user can change various alignment parameters
* **Plot Settings**
    * The user can change various plot visualization settings

![](../inst/extdata/tutorial_figures/Tutorial_Fig_1v2.png)

<div style="page-break-after: always;"></div>

<a name="Performing_Alignment"></a>

# Tutorial for Performing Alignment
## Set Working Directory

Use the Set Working Directory button to set the working directory that contains an mzml folder with .chrom.mzml files and an osw file with a merged.osw file, and optionally a library file in the .pqp format. Or you can directly enter the path to the working directory using the input textbox area. DrawAlignR will parse the working directory and look for `../osw`, `../mzml` ( or `../sqmass` ), and `../pqp` subfolders containing their corresponding file types. You can alternatively toggle the **Working Directory** button to enter chromatogram, library and osw files seprately. 
**Note:** For alignment it is preferred if you enter a working directory. 

### An example Working Directory should be ideally structured and named as below:
```
/Project_Working_Directory
|__/mzml
|   |__/run0.chrom.mzML
|   |__/run1.chrom.mzML
|__/osw
|   |__/merged.osw
|__/pqp
|   |__/assay_library.pqp
|__/sqmass(Optional, either mzml or sqmass format is acceptable)
|   |__/run1.chrom.sqMass
|   |__/run1.chrom.sqMass
```

![](../inst/extdata/tutorial_figures/Tutorial_Fig_2v2.png)

<div style="page-break-after: always;"></div>

## Select a Peptide to visualize Chromatogram alignment

Choose which peptide you want to visualze using the Peptide dropdown list. The dropdown list is searchable, so you can easily search for a specific peptide to visualize.
The list of peptides is extracted from either the input library file if abailable, or an osw file if available.

![](../inst/extdata/tutorial_figures/Tutorial_Fig_4v2.png)

<div style="page-break-after: always;"></div>

## Select a Charge State for Selected Peptide

Choose which charge state to visualize for the selcted peptide.

![](../inst/extdata/tutorial_figures/Tutorial_Fig_5v2.png)

<div style="page-break-after: always;"></div>

## Select Reference Run 

Choose which chromatogram file to use as the reference run. These are set through the searchable dropdown lists, which extracts the filenames from the supplied chromatogram files without the .chrom.mzml extension

![](../inst/extdata/tutorial_figures/Tutorial_Fig_6v2.png)

<div style="page-break-after: always;"></div>

## Select Experiment Run(s)

Choose which chromatogram file to use as the experiment run. These are set through the searchable dropdown lists, which extracts the filenames from the supplied chromatogram files without the .chrom.mzml extension

![](../inst/extdata/tutorial_figures/Tutorial_Fig_6.2v2.png)

<div style="page-break-after: always;"></div>

## Select Which Chromatogram Runs to Display

Choose which chromatogram runs to display by checking or unchecking the Run `n` checkbox.

![](../inst/extdata/tutorial_figures/Tutorial_Fig_6.3v2.png)

<div style="page-break-after: always;"></div>

## Select Plot Align checkbox to perform alignment

Check the Plot Aligned checkbox to perform the alignment of the two runs for the seleected peptide
You can also use the 

* Show Original Peak Annotation to show where the original peak was annotated before alginment.

![](../inst/extdata/tutorial_figures/Tutorial_Fig_7v2.png)

<div style="page-break-after: always;"></div>

## Change Alignment Parameters

Select the Alignment settings tab to change various alignment settings

![](../inst/extdata/tutorial_figures/Tutorial_Fig_9v2.png)

<div style="page-break-after: always;"></div>

## Zoom into each chromatogram for further inspection

![](../inst/extdata/tutorial_figures/Tutorial_Fig_10v2.png)

<div style="page-break-after: always;"></div>

## Use the Hover-tooltip

You can hover over the chromatogram traces to see information such as Retention time and Intensity

![](../inst/extdata/tutorial_figures/Tutorial_Fig_11v2.png)

<div style="page-break-after: always;"></div>

<a name="Graphical_Elements"></a>

# Visualizing Chromatograms

The user can also just visualize the chromatograms alone without performing alignment to visually inspect each trace. If the user has an IPF dataset, they can visualize site-determining ions (unique identifying transitions) of the modified peptide.

![](../inst/extdata/tutorial_figures/Tutorial_Fig_12v2.png)

<div style="page-break-after: always;"></div>

## Precursor, Detecting, Identifying

The user can choose to display the precursor tace, or the 6 detecting traces, or the unique identifying traces. The precursor trace is displayed in `black`, the detecting traces are displayed in a `light gray` and the unique identifying transitions are `colored`

![](../inst/extdata/tutorial_figures/Tutorial_Fig_13.png)

<div style="page-break-after: always;"></div>

## Displaying Transition Scores

The user can hover of the traces to display the transition scores such as the transitions posterior error probability, q-value and score.

![](../inst/extdata/tutorial_figures/Tutorial_Fig_14.png)

<div style="page-break-after: always;"></div>

## Displaying all Peak-Group Ranks

The user can choose to display the other potential peak-group ranks found by OpenSWATH

![](../inst/extdata/tutorial_figures/Tutorial_Fig_15.png)

<div style="page-break-after: always;"></div>

## Unselecting a Few Transitions to Display

The user can click on the legend to hide transitions they don't want to display

![](../inst/extdata/tutorial_figures/Tutorial_Fig_16.png)

<div style="page-break-after: always;"></div>

## Displaying a Single Transition

The user can choose to display a single transition by double clicking on the transition legend they wish to dispaly

![](../inst/extdata/tutorial_figures/Tutorial_Fig_17.png)