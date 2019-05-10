#!/usr/bin/env bash

FEAST_RELEASE_NAME=feast-${CIRCLE_BUILD_NUM}

echo ${GCLOUD_SERVICE_KEY} | gcloud auth activate-service-account --key-file=-
gcloud container clusters get-credentials feast-test-cluster --zone us-central1-a --project kf-feast

helm delete --purge ${FEAST_RELEASE_NAME}
