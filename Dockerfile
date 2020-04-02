# get shiny serves plus tidyverse packages image
FROM rocker/shiny-verse:latest


# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libnetcdf-dev &&\
mkdir -p /var/lib/shiny-server/bookmarks/shiny
    
# install R packages required 
# (change it dependeing on the packages you need)
RUN R -e "install.packages('shiny', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('shinyjs')"
RUN R -e "install.packages('shinyBS')"
RUN R -e "install.packages('shinyWidgets')"
RUN R -e "install.packages('shinyFiles')"
RUN R -e "install.packages('plotly')"
RUN R -e "install.packages('parallel')"
#RUN R -e "devtools::install_github('singjc/mstools', force=T, upgrade='never')"
#RUN R -e "devtools::install_github('shubham1637/DIAlignR', upgrade='never')"
RUN R -e "devtools::install_github('singjc/DrawAlignR', force=T)"

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
RUN sudo chown -R shiny:shiny /srv/shiny-server/DrawAlignR/

# run app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/DrawAlignR/inst/shiny-script/app.R', host='0.0.0.0', port=3838)"]
