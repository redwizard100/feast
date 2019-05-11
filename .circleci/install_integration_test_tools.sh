#!/usr/bin/env bash

set -e

export FEAST_CLI_GCS_URI=gs://feast-templocation-kf-feast/build/1117ce5af6e75fe3cb3c75240474d312a07856d7/cli/feast
export FEAST_CORE_URI=localhost:50051
export GOOGLE_CLOUD_SDK_ARCHIVE_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-244.0.0-linux-x86_64.tar.gz

# Install gettext utility so we can use envsubst
apt-get -qq update; apt-get -y install gettext

# Install Google Cloud SDK
wget -qO- ${GOOGLE_CLOUD_SDK_ARCHIVE_URL} | tar xz -C /
export PATH=/google-cloud-sdk/bin:$PATH
gcloud -q components install kubectl

# Setup authentication and access to cluster where Feast is going to be installed
gcloud config set project kf-feast
echo ${GCLOUD_SERVICE_KEY} > /etc/service_account.json
gcloud -q auth activate-service-account --key-file=/etc/service_account.json
export GOOGLE_APPLICATION_CREDENTIALS=/etc/service_account.json
gcloud -q auth configure-docker
gcloud -q container clusters get-credentials feast-test-cluster --zone us-central1-a --project kf-feast

# Install Helm
wget -qO- https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz | tar xz
mv linux-amd64/helm /usr/local/bin/helm

# Install Feast CLI
gsutil cp ${FEAST_CLI_GCS_URI} /usr/local/bin/feast
chmod +x /usr/local/bin/feast
feast config set coreURI ${FEAST_CORE_URI}

# Install Feast Python SDK
pip install -qe sdk/python
pip install -qr integration-tests/testutils/requirements.txt
