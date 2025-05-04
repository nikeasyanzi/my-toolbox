#!/bin/bash
set -e

SCRIPT_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
source $SCRIPT_PATH/settings.sh

function publish() {
    local tag=$1
    docker push $tag
}

if [[ -z "$1" ]]; then
    # If there is no input argument, build all targets
    for path in ${images[@]}; do
        dirname=$(basename $path)
        name=${dirname%-*}
        tag=${dirname##*-}
        echo -e "\n\nPublish container $name:$tag..."
        publish "${DOCKER_HUB}/$name:$tag"
    done
else
    path=$1
    dirname=$(basename $1)
    name=${dirname%-*}
    tag=${dirname##*-}
    echo -e "\n\nPublish container $name:$tag..."
    publish "${DOCKER_HUB}/$name:$tag"
fi
