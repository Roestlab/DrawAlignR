# get shiny serves plus tidyverse packages image
#FROM rocker/shiny-verse:latest
#FROM ubuntu:18.04
FROM openanalytics/r-base:3.6.1

MAINTAINER "Justin Sing" github.com/singjc/DrawAlignR

## Make build no interactive
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USEAGE=1

#######################
##      System
####################### 

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/*

#RUN apt-get update

#RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 

#RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu xenial-cran35/' 

#RUN apt-get upate



# system libraries of general use
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    build-essential \
    gfortran \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libnetcdf-dev \
    libxml2-dev \
    r-base \
    python3.6 \
    python3-pip \
    python3-setuptools \
    python3-dev &&\
mkdir -p /var/lib/shiny-server/bookmarks/shiny

#######################
##      Python
#######################
# get python image
#FROM python:3.7.5-slim
# install required python modules
RUN pip3 install \
    numpy \
    pandas \
    click \
    pymsnumpress

#######################
##      R language
#######################
# install R packages required 
# (change it dependeing on the packages you need)
RUN R -e  "install.packages('caTools')"
RUN R -e  "install.packages('cowplot')"
RUN R -e  "install.packages('xml2')"
RUN R -e  "install.packages('roxygen2')"
RUN R -e  "install.packages('rversions')"
RUN R -e  "install.packages('devtools')"
#RUN R -e "install.packages('shiny', repos='http://cran.rstudio.com/')"
#RUN R -e "install.packages('shinyjs')"
#RUN R -e "install.packages('shinyBS')"
#RUN R -e "install.packages('shinyWidgets')"
##RUN R -e "install.packages('shinyFiles')"
#RUN R -e "install.packages('plotly')"
#RUN R -e "install.packages('parallel')"
#RUN R -e "devtools::install_github('singjc/mstools', force=T, upgrade='never')"
#RUN R -e "devtools::install_github('shubham1637/DIAlignR', upgrade='never')"
RUN R -e "library(devtools); devtools::install_github('singjc/DrawAlignR', upgrade='default', force=T, build_opts = c('--no-build-vignettes'))"

# copy the app to the image
#COPY ./DrawAlignR.Rproj /srv/shiny-server/
#COPY ./inst/shiny-script/app.R /srv/shiny-server/
#COPY ./inst/shiny-script/external /srv/shiny-server/external/
#COPY ./inst/shiny-script/www /srv/shiny-server/www/
#COPY ./R /srv/shiny-server/R
#COPY ./inst/extdata/Synthetic_Dilution_Phosphoproteomics/ /srv/shiny-server/data/

COPY ./ /srv/shiny-server/DrawAlignR/

# select port
EXPOSE 3838

# Make all app files readable
RUN chmod -R +r /srv/shiny-server/DrawAlignR/

# allow permission
#RUN sudo chown -R shiny:shiny /srv/shiny-server/DrawAlignR/

# run app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/DrawAlignR/inst/shiny-script/app.R', host='0.0.0.0', port=3838)"]
