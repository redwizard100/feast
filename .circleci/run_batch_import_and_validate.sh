#!/usr/bin/env bash

set -e

export FEAST_RELEASE_NAME=feast-${CIRCLE_SHA1:0:7}
export FEAST_WAREHOUSE_DATASET=feast_build_${CIRCLE_SHA1:0:7}
export FEAST_CLI_GCS_URI=gs://feast-templocation-kf-feast/build/1117ce5af6e75fe3cb3c75240474d312a07856d7/cli/feast
export FEAST_CORE_URI=localhost:50051
export FEAST_SERVING_URI=localhost:50052
export FEAST_BATCH_IMPORT_GCS_URI=gs://feast-templocation-kf-feast/build/1117ce5af6e75fe3cb3c75240474d312a07856d7/ingestion_1.csv

# Setup port forwarding to access Feast core and serving service in Kube
kubectl port-forward service/${FEAST_RELEASE_NAME}-core 50051:6565 &
kubectl port-forward service/${FEAST_RELEASE_NAME}-serving 50052:6565 &

cd integration-tests/testdata

# Prepare import spec
gsutil cp feature_values/ingestion_1.csv ${FEAST_BATCH_IMPORT_GCS_URI}
envsubst < import_specs/batch_from_gcs.yaml.template > import_specs/batch_from_gcs.yaml

# Register entity, features and job
feast apply entity entity_specs/entity_1.yaml
feast apply feature feature_specs/entity_1.feature_*.yaml
feast jobs run import_specs/batch_from_gcs.yaml --wait

cd ..

# Validate feature values
python -m testutils.validate_feature_values \
--entity_spec_file=testdata/entity_specs/entity_1.yaml \
--feature_spec_files=testdata/feature_specs/entity_1*.yaml \
--expected-warehouse-values-file=testdata/feature_values/ingestion_1.csv \
--expected-serving-values-file=testdata/feature_values/serving_1.csv \
--bigquery-dataset-for-warehouse=${FEAST_WAREHOUSE_DATASET} \
--feast-serving-url=${FEAST_SERVING_URI} \
--project=kf-feast
