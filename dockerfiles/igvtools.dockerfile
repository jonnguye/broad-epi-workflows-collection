############################################################
# Dockerfile for igvtools
# Based on Debian slim
############################################################

FROM debian@sha256:3ecce669b6be99312305bc3acc90f91232880c68b566f257ae66647e9414174f as builder

# To prevent time zone prompt
ENV DEBIAN_FRONTEND=noninteractive

# Install softwares from apt repo
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    liblz4-dev \
    liblzma-dev \
    libncurses5-dev \
    libbz2-dev \
    unzip \
    wget \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

# Make directory for all softwares
RUN mkdir /software
WORKDIR /software
ENV PATH="/software:${PATH}"

RUN wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/wigToBigWig && chmod 750 wigToBigWig
RUN wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig && chmod 750 bedGraphToBigWig
RUN wget https://data.broadinstitute.org/igv/projects/downloads/2.16/IGV_2.16.2.zip && unzip IGV_2.16.2.zip && mv IGV_2.16.2 igvtools && rm IGV_2.16.2.zip

FROM openjdk:11-jre

LABEL maintainer = "Eugenio Mattei"
LABEL software = "igvtools"
LABEL software.version="2.0.0"
LABEL software.organization="Broad Institute of MIT and Harvard"
LABEL software.version.is-production="Yes"
LABEL software.task="igvtools"

# Install softwares from apt repo
RUN apt-get update && apt-get install -y \
    gcc \&& \
    rm -rf /var/lib/apt/lists/*

# Create and setup new user
ENV USER=shareseq
WORKDIR /home/$USER

RUN groupadd -r $USER &&\
    useradd -r -g $USER --home /home/$USER -s /sbin/nologin -c "Docker image user" $USER &&\
    chown $USER:$USER /home/$USER

# Add folder with software to the path
ENV PATH="/software/:/software/igvtools:${PATH}"

# Copy the compiled software from the builder
COPY --from=builder --chown=$USER:$USER /software/* /software/

USER $USER