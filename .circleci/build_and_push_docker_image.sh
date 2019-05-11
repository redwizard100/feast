#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: build_and_push_docker_image.sh COMPONENT REGISTRY/REPO:TAG"
    echo "Example: build_and_push_docker_image.sh core gcr.io/project/feast-core:1.0.0"
    echo "         build_and_push_docker_image.sh serving gcr.io/project/feast-serving:1.0.0"
    exit 1
fi

COMPONENT=${1}
DOCKER_IMAGE_TAG=${2}

echo ${GCLOUD_SERVICE_KEY} | gcloud auth activate-service-account --key-file=-
gcloud -q auth configure-docker

docker build -t ${DOCKER_IMAGE_TAG} -f Dockerfiles/${COMPONENT}/Dockerfile .
docker push ${DOCKER_IMAGE_TAG}
