#!/bin/sh

# Set default output directory
OUTPUT_DIR=""

# Define usage function
usage() {
    echo "Usage: $0 [OPTIONS] [APP_NAME] [TAG]"
    echo "Options:"
    echo "  -h          Help"
    echo "  -o PATH     Output directory for the generated zip file"
    exit 1
}

# Parse command-line options
while getopts "o:h" opt; do
    case $opt in
        o) OUTPUT_DIR="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND -1))


ROOT_PATH=$(dirname "$(realpath "$0")")

APP_NAME=$(yq -r '.tool.poetry.name' "${ROOT_PATH}/../pyproject.toml")
VERSION=$(yq -r '.tool.poetry.version' "${ROOT_PATH}/../pyproject.toml")

TAG="v$VERSION"

HTTP_PROXY=http://10.80.0.238:9999
HTTPS_PROXY=http://10.80.0.238:9999

# Set server addresses
STG="stg-k8s-manager-server.stg.gmo.sec:30003"
PROD="k8s-manager-server.gmo.sec:30003"

# Set image names
STG_TAG="$STG/$APP_NAME/$APP_NAME:$TAG"
PROD_TAG="$PROD/$APP_NAME/$APP_NAME:$TAG"

echo "going to build $STG_TAG"
podman build -t $STG_TAG .

echo "Finished building, now pushing $STG_TAG ..."

podman push $STG_TAG --tls-verify=false

if [ -z "$OUTPUT_DIR" ]; then
    echo "OUTPUT_DIR (-o PATH) not passed, so not saving."
    exit
fi

# Tag the image
podman tag "$STG_TAG" "$PROD_TAG"

# Set output file
echo "using output directory: $OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/$APP_NAME-$TAG.tar.gz"

# Save the image to a gzipped tarball in the specified directory
mkdir -p "$OUTPUT_DIR" && podman save "$PROD_TAG" | gzip > "$OUTPUT"
echo "Image $PROD_TAG saved to: $OUTPUT"
