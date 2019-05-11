#!/usr/bin/env bash

export FEAST_BUILD_NUMBER=${CIRCLE_SHA1:0:7}
export FEAST_IMAGE_TAG=${CIRCLE_SHA1}
export FEAST_WAREHOUSE_DATASET=feast_build_${CIRCLE_SHA1:0:7}
export FEAST_RELEASE_NAME=feast-${CIRCLE_SHA1:0:7}

envsubst < integration-tests/feast-helm-values.yaml.template > integration-tests/feast-helm-values.yaml
helm install --name ${FEAST_RELEASE_NAME} --wait --timeout 210 ./charts/feast -f integration-tests/feast-helm-values.yaml
