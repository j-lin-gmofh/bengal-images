#!/bin/bash

VERSION=$1;

if [ -z "$VERSION" ]
    then
        echo "Need to provide a version"
        exit 1
fi

case $VERSION in
    stg)
        TAG="fh-all.com/bengal:${VERSION}-stg"
        PROXY_ARG="--build-arg http_proxy=http://10.80.0.238:9999 --build-arg https_proxy=http://10.80.0.238:9999"
        ;;
    *)
        TAG="fh-all.com/bengal:${VERSION}"
        PROXY_ARG="--build-arg http_proxy=http://10.50.1.192:9999 --build-arg https_proxy=http://10.50.1.192:9999"
        ;;
esac

sudo docker build ${PROXY_ARG} -t ${TAG} .
sudo docker save $TAG | sudo k3s ctr images import -
