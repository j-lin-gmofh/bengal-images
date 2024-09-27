# syntax=docker/dockerfile:1.4
ARG BASE_REPO=datascience-notebook
ARG BASE_TAG="python-3.10"
ARG BENGAL_VERSION="0.3.0"

FROM ghcr.io/oracle/oraclelinux8-instantclient:21 as client

FROM jupyter/${BASE_REPO}:${BASE_TAG} as base

USER root

# Copy Oracle instant client from client stage
COPY --from=client /usr/lib/oracle /usr/lib/oracle
COPY --from=client /etc/ld.so.conf.d/oracle-instantclient.conf /etc/ld.so.conf.d/oracle-instantclient.conf
RUN ldconfig

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    # for cython: https://cython.readthedocs.io/en/latest/src/quickstart/install.html
    build-essential \
    # for latex labels
    cm-super \
    dvipng \
    # for matplotlib anim
    ffmpeg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

# Install Python 3 packages
RUN mamba install --quiet --yes -c conda-forge -c pytorch \
    "blpapi=3.16.2" \
    "tensorflow=2.4.1" \
    "tensorboard==2.4.1" \
    "tensorboard-plugin-wit==1.8.0" \
    "theano=1.0.5" \
    "torchvision==0.8.2" \
    "torchaudio==0.7.2" \
    "pytorch=1.7.1" && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# install modules which do not have a conda package at the moment
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt --no-cache-dir
COPY bengal-0.1.1-py3-none-any.whl /tmp/bengal-0.1.1-py3-none-any.whl
RUN pip install /tmp/bengal-0.1.1-py3-none-any.whl --no-cache-dir


# Install facets which does not have a pip or conda package at the moment
WORKDIR /tmp
RUN git clone https://github.com/PAIR-code/facets.git && \
    jupyter nbextension install facets/facets-dist/ --sys-prefix && \
    rm -rf /tmp/facets && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"

RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions "/home/${NB_USER}"

USER ${NB_UID}

# set timezone
ENV TZ=Asia/Tokyo

# oracle lang
ENV NLS_LANG=Japanese_Japan.AL32UTF8

WORKDIR "${HOME}"
