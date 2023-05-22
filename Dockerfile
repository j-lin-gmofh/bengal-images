FROM python:3.8-slim as client

# GMO proxy needs to be added as we need to access internet during build phase in build server
# NOTE: see README on overriding/unsetting the default env vars
# this describes in detail on how to provide a default env variable that allows it to be overridden: https://vsupalov.com/docker-arg-env-variable-guide/
ARG http_proxy=http://10.80.0.238:9999
ARG https_proxy=http://10.80.0.238:9999
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}

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
ARG http_proxy=http://10.80.0.238:9999
ARG https_proxy=http://10.80.0.238:9999
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}

RUN pip install "http://ghe.gmo-sec.jp/kgb57/bengal/releases/download/bengal/bengal-0.1.1-py3-none-any.whl"

# set timezone
ENV TZ=Asia/Tokyo

# oracle lang
ENV NLS_LANG=Japanese_Japan.AL32UTF8