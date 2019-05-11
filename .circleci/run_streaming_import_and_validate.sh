#!/usr/bin/env bash

set -e

apt-get -qq update; apt-get -y install gettext

export FEAST_CLI_GCS_URI=gs://feast-templocation-kf-feast/build/1117ce5af6e75fe3cb3c75240474d312a07856d7/cli/feast
export FEAST_CORE_URI=localhost:50051
export FEAST_SERVING_URI=localhost:50052
export FEAST_RELEASE_NAME=feast-${CIRCLE_SHA1:0:7}
export KAFKA_BROKERS=kafka-headless.default.svc.cluster.local:9092
export KAFKA_TOPICS=feast-${CIRCLE_SHA1:0:7}
export KAFKA_RELEASE_NAME=kafka

cd integration-tests/testdata

# Prepare import spec
envsubst < import_specs/stream_from_kafka.yaml.template > import_specs/stream_from_kafka.yaml
export KAFKA_BROKERS=localhost:31090

# Register entity, features and job
feast apply entity entity_specs/entity_2.yaml
feast apply feature feature_specs/entity_2.feature_*.yaml
feast jobs run import_specs/stream_from_kafka.yaml &

sleep 20
cd ..

# Produce streaming data to be ingested by Feast ingestion job
python -m testutils.kafka_producer \
--bootstrap_servers=${KAFKA_BROKERS} \
--topic=${KAFKA_TOPICS} \
--entity_spec_file=testdata/entity_specs/entity_2.yaml \
--feature_spec_files=testdata/feature_specs/entity_2*.yaml \
--feature_values_file=testdata/feature_values/ingestion_2.csv

sleep 20

# Validate feature values
python -m testutils.validate_feature_values \
--entity_spec_file=testdata/entity_specs/entity_2.yaml \
--feature_spec_files=testdata/feature_specs/entity_2*.yaml \
--expected-serving-values-file=testdata/feature_values/serving_2.csv \
--feast-serving-url=${FEAST_SERVING_URI}