#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: build_and_push_docker_image.sh REGISTRY/REPO:TAG"
    echo "Example: build_and_push_docker_image.sh gcr.io/project/app:1.0.0"
    exit 1
fi

echo ${GCLOUD_SERVICE_KEY} | gcloud auth activate-service-account --key-file=-
gcloud -q auth configure-docker

docker build -t ${1}:${CIRCLE_SHA1} -f Dockerfiles/core/Dockerfile .
docker push ${1}:${CIRCLE_SHA1}