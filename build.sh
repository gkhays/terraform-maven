#!/bin/bash

set -e

command -v docker >/dev/null 2>&1 || { echo >&2 "ERROR: docker could not be found."; exit 1; }
# Check if error (E.g. WSL if Docker Desktop not running)
command docker >/dev/null 2>&1 || { echo >&2 "ERROR: docker not ready."; exit 1; }

readonly image_name="tf/maven-java"
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\nBuilding Docker image in $script_dir and tagging it with name $image_name"
cd "$script_dir"
docker build -t "$image_name" "$script_dir"

echo -e "\nCreating Docker container from image $image_name"
container_id=$(docker create "$image_name")

# Note that we put a /. (slash, dot) at the end of the container build dir to ensure its contents are always copied
# into the host build folder. Without the /., the behavior would differ based on whether the host build folder already
# existed. See the docker cp documentation for details: https://docs.docker.com/engine/reference/commandline/cp/#extended-description
readonly build_dir_host="$script_dir/java/target"
readonly build_dir_container="/app/java/target/."

# Clear any existing build dir on host
if [ -d "$build_dir_host" ]; then
    rm -r "$build_dir_host"
fi

echo -e "\nCopying '$build_dir_container' from Docker container '$container_id' to '$build_dir_host' on host"
docker cp "$container_id:$build_dir_container" "$build_dir_host"

echo -e "\nRemoving container $container_id"
# Due to a CircleCI limitation, docker rm operations will fail. This doesn't matter during a CI job, so for now, just
# add the || true at the end to make sure the whole build doesn't fail as a result. For more info, see:
# https://discuss.circleci.com/t/docker-error-removing-intermediate-container/70
docker rm "$container_id" || true
