#!/usr/bin/env bash

export FEAST_RELEASE_NAME=feast-${CIRCLE_SHA1:0:7}
export FEAST_WAREHOUSE_DATASET=feast_build_${CIRCLE_SHA1:0:7}
export FEAST_CLI_GCS_URI=gs://feast-templocation-kf-feast/build/1117ce5af6e75fe3cb3c75240474d312a07856d7/cli/feast
export FEAST_CORE_URI=localhost:50051
export FEAST_SERVING_URI=localhost:50052
export FEAST_BATCH_IMPORT_GCS_URI=gs://feast-templocation-kf-feast/build/1117ce5af6e75fe3cb3c75240474d312a07856d7/ingestion_1.csv

# Install Google Cloud SDK
GOOGLE_CLOUD_SDK_ARCHIVE_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-244.0.0-linux-x86_64.tar.gz
wget -qO- ${GOOGLE_CLOUD_SDK_ARCHIVE_URL} | tar xz -C /
export PATH=$PATH:/google-cloud-sdk/bin
gcloud -q components install kubectl
echo ${GCLOUD_SERVICE_KEY} | gcloud auth activate-service-account --key-file=-
echo ${GCLOUD_SERVICE_KEY} > /etc/service_account.json
export GOOGLE_APPLICATION_CREDENTIALS=/etc/service_account.json
gcloud container clusters get-credentials feast-test-cluster --zone us-central1-a --project kf-feast

# Prepare connections and import csv
kubectl port-forward service/${FEAST_RELEASE_NAME}-core 50051:6565 &
kubectl port-forward service/${FEAST_RELEASE_NAME}-serving 50052:6565 &
gsutil cp integration-tests/feature_values/ingestion_1.csv ${FEAST_BATCH_IMPORT_GCS_URI}
envsubst < integration-tests/import_specs/batch_from_gcs.yaml.template > integration-tests/import_specs/batch_from_gcs.yaml

# Install Feast CLI
gsutil cp ${FEAST_CLI_GCS_URI} /usr/local/bin/feast
chmod +x /usr/local/bin/feast
feast config set coreURI ${FEAST_CORE_URI}

# Install Feast Python SDK
pip install -qe sdk/python
pip install -qr integration-tests/testutils/requirements.txt

cd integration-tests

feast apply entity testdata/entity_specs/entity_1.yaml
feast apply feature testdata/feature_specs/entity_1.feature_*.yaml

tree testdata
cat import_specs/batch_from_gcs.yaml

feast jobs run testdata/import_specs/batch_from_gcs.yaml --wait

python -m testutils.validate_feature_values \
--entity_spec_file=testdata/entity_specs/entity_1.yaml \
--feature_spec_files=testdata/feature_specs/entity_1*.yaml \
--expected-warehouse-values-file=testdata/feature_values/ingestion_1.csv \
--expected-serving-values-file=testdata/feature_values/serving_1.csv \
--bigquery-dataset-for-warehouse=${FEAST_WAREHOUSE_DATASET} \
--feast-serving-url=${FEAST_SERVING_URI} \
--project=kf-feast
