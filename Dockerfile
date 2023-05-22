FROM python:3.8-slim as client

# GMO proxy needs to be added as we need to access internet during build phase in build server
# NOTE: see README on overriding/unsetting the default env vars
# this describes in detail on how to provide a default env variable that allows it to be overridden: https://vsupalov.com/docker-arg-env-variable-guide/
# ARG http_proxy=http://10.80.0.238:9999
# ARG https_proxy=http://10.80.0.238:9999
# ENV http_proxy=${http_proxy}
# ENV https_proxy=${https_proxy}

RUN apt-get update && apt-get install -y apt-utils unzip libaio1 build-essential wget

RUN mkdir -p /opt/oracle && cd /opt/oracle && \
    wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-basic-linux.x64-21.6.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-21.6.0.0.0dbru.zip && \
    rm instantclient-basic-linux.x64-21.6.0.0.0dbru.zip && \
    sh -c "echo /opt/oracle/instantclient_21_6 > /etc/ld.so.conf.d/oracle-instantclient.conf" && \
    ldconfig


FROM jupyter/minimal-notebook:python-3.8

COPY --from=client /opt/oracle /opt/oracle

# GMO proxy needs to be added as we need to access internet during build phase in build server
# NOTE: see README on overriding/unsetting the default env vars
# this describes in detail on how to provide a default env variable that allows it to be overridden: https://vsupalov.com/docker-arg-env-variable-guide/
# ARG http_proxy=http://10.80.0.238:9999
# ARG https_proxy=http://10.80.0.238:9999
# ENV http_proxy=${http_proxy}
# ENV https_proxy=${https_proxy}

# COPY from https://github.com/jupyter/docker-stacks/blob/main/scipy-notebook/Dockerfile
# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

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
    "beautifulsoup4=4.9.3" \
    "blpapi=3.16.2" \
    "bokeh=2.3.0" \
    "bottleneck=1.3.2" \
    "cryptography=3.4.7" \
    "cx_Oracle=8.1.0" \
    "cython=0.29.22" \
    "dask=2021.3.1" \
    "datashape=0.5.4" \
    "decorator=4.4.2" \
    "dill=0.3.3" \
    "dtreeviz=1.2" \
    "graphviz=2.47.0" \
    "img2pdf=0.3.6" \
    "ipykernel=5.5.0" \
    "ipython=7.20.0" \
    "ipywidgets=7.6.3" \
    "jdcal=1.4.1" \
    "jedi=0.18.0" \
    "joblib=1.0.1" \
    "matplotlib=3.4.1" \
    "more-itertools=8.7.0" \
    "mpmath=1.2.1" \
    "networkx=2.5" \
    "numexpr=2.7.3" \
    "numpy=1.20.1" \
    "olefile=0.46" \
    "openpyxl=3.0.7" \
    "orange3=3.28.0" \
    "pandas=1.2.2" \
    "partd=1.1.0" \
    "patsy=0.5.1" \
    "pillow=8.1.2" \
    "plotly=4.14.3" \
    "ptyprocess=0.7.0" \
    "pymc3=3.11.2" \
    "pypdf2=1.26.0" \
    "pyqtgraph=0.12.0" \
    "python-dateutil=2.8.1" \
    "pytz=2021.1" \
    "requests=2.25.1" \
    "scikit-image=0.18.1" \
    "scikit-learn=0.24.1" \
    "scipy=1.6.2" \
    "seaborn=0.11.1" \
    "statsmodels=0.12.2" \
    "sympy=1.7.1" \
    "ta-lib=0.4.19" \
    "tensorflow=2.4.1" \
    "tensorboard==2.4.1" \
    "tensorboard-plugin-wit==1.8.0" \
    "theano=1.0.5" \
    "toolz=0.11.1" \
    "unicodecsv=0.14.1" \
    "xlrd=2.0.1" \
    "xlsxWriter=1.3.8" \
    "xlwt=1.3" \
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
