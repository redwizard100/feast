#!/usr/bin/env bash

set -e

apt-get -qq update; apt-get -y install gettext

export FEAST_CORE_URI=localhost:50051
export FEAST_SERVING_URI=localhost:50052
export FEAST_RELEASE_NAME=feast-${CIRCLE_SHA1:0:7}
export KAFKA_BROKERS=kafka-headless.default.svc.cluster.local:9092
export KAFKA_TOPICS=feast-${CIRCLE_SHA1:0:7}
export KAFKA_RELEASE_NAME=kafka

# Install Google Cloud SDK
GOOGLE_CLOUD_SDK_ARCHIVE_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-244.0.0-linux-x86_64.tar.gz
wget -qO- ${GOOGLE_CLOUD_SDK_ARCHIVE_URL} | tar xz -C /
export PATH=$PATH:/google-cloud-sdk/bin
gcloud -q components install kubectl
echo ${GCLOUD_SERVICE_KEY} | gcloud auth activate-service-account --key-file=-
echo ${GCLOUD_SERVICE_KEY} > /etc/service_account.json
export GOOGLE_APPLICATION_CREDENTIALS=/etc/service_account.json
gcloud container clusters get-credentials feast-test-cluster --zone us-central1-a --project kf-feast

# Prepare connections and import spec
kubectl port-forward service/${FEAST_RELEASE_NAME}-core 50051:6565 &
kubectl port-forward service/${FEAST_RELEASE_NAME}-serving 50052:6565 &
kubectl port-forward service/${KAFKA_RELEASE_NAME}-0-external 31090:19092 &
envsubst < integration-tests/testdata/import_specs/stream_from_kafka.yaml.template > integration-tests/testdata/import_specs/stream_from_kafka.yaml.yaml
export KAFKA_BROKERS=localhost:31090

cd integration-tests
feast apply entity testdata/entity_specs/entity_2.yaml
feast apply feature testdata/feature_specs/entity_2.feature_*.yaml
feast jobs run testdata/import_specs/stream_from_kafka.yaml &

sleep 20

python -m testutils.kafka_producer \
--bootstrap_servers=${KAFKA_BROKERS} \
--topic=${KAFKA_TOPICS} \
--entity_spec_file=testdata/entity_specs/entity_2.yaml \
--feature_spec_files=testdata/feature_specs/entity_2*.yaml \
--feature_values_file=testdata/feature_values/ingestion_2.csv

sleep 20

python -m testutils.validate_feature_values \
--entity_spec_file=testdata/entity_specs/entity_2.yaml \
--feature_spec_files=testdata/feature_specs/entity_2*.yaml \
--expected-serving-values-file=testdata/feature_values/serving_2.csv \
--feast-serving-url=${FEAST_SERVING_URI}