#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: build_and_push_cli.sh GCS_URI"
    echo "Example: build_and_push_cli.sh gs://bucket/path/to/binary/cli"
    exit 1
fi

GCS_URI=${1}

# Install Google Cloud SDK
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. ${SCRIPT_DIR}/install_google_cloud_sdk.sh

# Build CLI and upload to GCS
go build -o ./cli/build/feast ./cli/feast
gsutil cp ./cli/build/feast ${GCS_URI}
