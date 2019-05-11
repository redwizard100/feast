#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: build_and_push_cli.sh GCS_URI"
    echo "Example: build_and_push_cli.sh gs://bucket/path/to/binary/cli"
    exit 1
fi

GCS_URI=${1}

# Install Google Cloud SDK
GOOGLE_CLOUD_SDK_ARCHIVE_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-244.0.0-linux-x86_64.tar.gz
wget -qO- ${GOOGLE_CLOUD_SDK_ARCHIVE_URL} | tar xz -C /
export PATH=/google-cloud-sdk/bin:$PATH
echo ${GCLOUD_SERVICE_KEY} | gcloud auth activate-service-account --key-file=-

# Build CLI and upload to GCS
go build -o ./cli/build/feast ./cli/feast
gsutil cp ./cli/build/feast ${GCS_URI}
