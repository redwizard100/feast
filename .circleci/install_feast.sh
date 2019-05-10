#!/usr/bin/env bash

export FEAST_BUILD_NUMBER=${CIRCLE_SHA1:0:7}
export FEAST_IMAGE_TAG=1890cb04688a3e10f6de7305992e71ee7ba1793d
# export FEAST_IMAGE_TAG=${CIRCLE_SHA1}
export FEAST_WAREHOUSE_DATASET=feast_build_${CIRCLE_SHA1:0:7}
export FEAST_CORE_URL=build-${CIRCLE_SHA1}.drone.feast.ai:80
export FEAST_SERVING_URL=build-${CIRCLE_SHA1}.drone.feast.ai:80
export FEAST_RELEASE_NAME=feast-${CIRCLE_SHA1:0:7}

echo ${GCLOUD_SERVICE_KEY} | gcloud auth activate-service-account --key-file=-
gcloud container clusters get-credentials feast-test-cluster --zone us-central1-a --project kf-feast

cd integration-tests
envsubst < feast-helm-values.yaml.template > feast-helm-values.yaml
helm install --name ${FEAST_RELEASE_NAME} --wait --timeout 210 ../charts/feast -f feast-helm-values.yaml
