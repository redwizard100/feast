#!/usr/bin/env bash

export FEAST_WAREHOUSE_DATASET=feast_build_${CIRCLE_SHA1}
export FEAST_CORE_URL=build-${CIRCLE_SHA1}.drone.feast.ai:80
export FEAST_SERVING_URL=build-${CIRCLE_SHA1}.drone.feast.ai:80
export FEAST_CLI_GCS_URI=gs://feast-templocation-kf-feast/build/1117ce5af6e75fe3cb3c75240474d312a07856d7/cli/feast

# Install Google Cloud SDK
GOOGLE_CLOUD_SDK_ARCHIVE_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-244.0.0-linux-x86_64.tar.gz
wget -qO- ${GOOGLE_CLOUD_SDK_ARCHIVE_URL} | tar xz -C /
export PATH=$PATH:/google-cloud-sdk/bin

# Install Feast SDK
gsutil cp ${FEAST_CLI_GCS_URI} /usr/local/bin/feast
chmod +x /usr/local/bin/feast
feast config set coreURI ${FEAST_CORE_URI}

cd integration-tests

feast apply entity testdata/entity_specs/entity_1.yaml
feast apply feature testdata/feature_specs/entity_1.feature_*.yaml
feast jobs run testdata/import_specs/batch_from_gcs.yaml --wait

python -m testutils.validate_feature_values \
--entity_spec_file=testdata/entity_specs/entity_1.yaml \
--feature_spec_files=testdata/feature_specs/entity_1*.yaml \
--expected-warehouse-values-file=testdata/feature_values/ingestion_1.csv \
--expected-serving-values-file=testdata/feature_values/serving_1.csv \
--bigquery-dataset-for-warehouse=${FEAST_WAREHOUSE_DATASET} \
--feast-serving-url=${FEAST_SERVING_URI} \
--project=kf-feast
