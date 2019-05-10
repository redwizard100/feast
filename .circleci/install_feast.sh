#!/usr/bin/env bash

FEAST_BUILD_NUMBER=${CIRCLE_BUILD_NUM}
FEAST_IMAGE_TAG=${CIRCLE_SHA1}
FEAST_WAREHOUSE_DATASET=feast_build_${CIRCLE_BUILD_NUM}
FEAST_CORE_URL=build-${CIRCLE_BUILD_NUM}.feast.dragonin.me:80
FEAST_SERVING_URL=build-${CIRCLE_BUILD_NUM}.feast.dragonin.me:80
FEAST_RELEASE_NAME=feast-${CIRCLE_BUILD_NUM}

echo ${GCLOUD_SERVICE_KEY} | gcloud auth activate-service-account --key-file=-
gcloud container clusters get-credentials feast-test-cluster --zone us-central1-a --project kf-feast

cd $FEAST_HOME/integration-tests
envsubst < feast-helm-values.yaml.template > feast-helm-values.yaml
helm install --name $FEAST_RELEASE_NAME --wait --timeout 210 ../charts/feast -f feast-helm-values.yaml
