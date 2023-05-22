#!/bin/bash

TAG="fh-all.com/bengal-minimal:3.8"
PROXY_ARG="--build-arg http_proxy=http://10.80.0.238:9999 --build-arg https_proxy=http://10.80.0.238:9999"
sudo docker build ${PROXY_ARG} -t ${TAG} .
sudo docker save $TAG | sudo k3s ctr images import -