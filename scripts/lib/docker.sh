#!/usr/bin/env bash

docker_build() {
  local image="$1"
  local tag="$2"

  docker build \
    -t "${image}:${tag}" \
    "$ROOT_DIR/app"
}

docker_tag() {
  local source_image="$1"
  local tag="$2"
  local target_repository="$3"

  docker tag \
    "${source_image}:${tag}" \
    "${target_repository}:${tag}"
}

docker_push() {
  local repository="$1"
  local tag="$2"

  docker push "${repository}:${tag}"
}