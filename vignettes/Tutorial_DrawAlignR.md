# Using/ Calling DrawAlignR

The visualization tool can be called via two methods, either via installing the repository using devtools github package installer or by calling shiny::runGitHub.

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