#!/usr/bin/env bash

export FEAST_BUILD_NUMBER=${CIRCLE_SHA1:0:7}
export FEAST_IMAGE_TAG=1890cb04688a3e10f6de7305992e71ee7ba1793d
# export FEAST_IMAGE_TAG=${CIRCLE_SHA1}
export FEAST_WAREHOUSE_DATASET=feast_build_${CIRCLE_SHA1:0:7}
export FEAST_RELEASE_NAME=feast-${CIRCLE_SHA1:0:7}

envsubst < integration-tests/feast-helm-values.yaml.template > integration-tests/feast-helm-values.yaml
helm install --name ${FEAST_RELEASE_NAME} --wait --timeout 210 ./charts/feast -f integration-tests/feast-helm-values.yaml

kubectl port-forward service/${FEAST_RELEASE_NAME}-core 50051:6565 &
kubectl port-forward service/${FEAST_RELEASE_NAME}-serving 50052:6565 &

# Setup port forwarding to Kafka server for testing streaming import
export KAFKA_RELEASE_NAME=kafka
kubectl port-forward service/${KAFKA_RELEASE_NAME}-0-external 31090:19092 &
