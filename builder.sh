#!/bin/bash

VERSION=$1;

if [ -z "$VERSION" ]
    then
        echo "Need to provide a version"
        exit 1
fi

TAG="fh-all.com/bengal-images:${VERSION}"
PROXY_ARG="--build-arg http_proxy=http://10.50.1.192:9999 --build-arg https_proxy=http://10.50.1.192:9999"

sudo docker build ${PROXY_ARG} -t ${TAG} .
sudo docker save $TAG | sudo k3s ctr images import -
