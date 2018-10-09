# Illinois Cancer

Here is a description of the files in this repository

## Data
Contains all of the csv files (original data and data cleaned by me. Some of them are in a .zip because they were too large to upload to Github)
* il_2010_populations.csv - Population data from US Census Bureau
* il_cancer_statistics.csv - Normalized Cancer Rates per ZIP code in Illinois
* il_cancer and zpcd8615.zip - contain the il_cancer.csv and zpcd8615.dat files
  * il_cancer.csv - Cleaned, user-friendly output of the zpcd8615.dat file
  * zpcd8615.dat - Raw data from the Illinois Department of Public Health

## cancer.ipynb
iPython notebook. Compatible with Jupyter Notebooks (Anaconda) or any other iPython notebook reader

## cancer.py
Python script created from the cancer.ipynb file

## cancer.R
R script, fully commented. Contains information on how to download the files from the IDPH website and the US Census websites. Gives motivation and logic behind all decisions made. The outputs from this R file and the Python files are the EXACT same, just done in different environments.

## cancer_python.html
HTML output of the iPython notebook file. Open it in a web browser

## il_cancer.html
HTML output of the R Markdown. This is the same output as the PDF.

## il_cancer.pdf
**THE PDF IS NOT CONSISTENT WITH THE il_cancer.html FILE. I HAVE ADDED INTERACTIVE GRAPHS AND MAPS IN THE HTML SINCE CREATING THE PDF, AND THEY CAN'T RENDER INTO A PDF. I MAY ADD STATIC VERSIONS OF THE PLOTS LATER ON FOR A PDF VERISON TO BE POSSIBLE**

PDF output of the R Markdown.

## il_cancer.Rmd
R Markdown file containing the code which created the il_cancer.html and il_cancer.pdf files

## READMEv25.pdf
README file provided by the Illinois Department of Public Health to explain the raw data files for the cancer data.
