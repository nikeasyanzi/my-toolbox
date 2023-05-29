#!/bin/bash
set -e
SCRIPT_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
source $SCRIPT_PATH/settings.sh

function run_http_server() {
    local port=$1

    # Stop previously running process if exist
    stop_http_server
    # Start a new process for http server
    python3 -m http.server $port &

    echo "Python http server running on port $port with PID $pid"
    return 0
}

function stop_http_server() {
    local pid=$(ps -aux | grep "python3 -m http.server $port" | grep -v "grep" | awk '{print $2}')
    [[ $pid != "" ]] && kill -9 $pid
    return 0
}
function gen_file_link(){
    local file_name=$(find . -type f \( -iname '*.sh' -o -iname '*.py' -o -iname '*.tar*' -o -iname '*.zip' -o -iname '*.yaml' \))
    for i in ${file_name[@]}
    do
	tt=("http://$ip_addr:$port/${i:2}")
    	tt+=" "
    	result+=$tt
    done
    echo $result
}


# This function build one container image from the directory - $1, containing a Dockerfile and a compressed file of SDK
function build() {
    local tag=$1
    local ip_addr=$(ip addr show scope global | grep -Po 'inet \K[\d.]+' | head -n 1)
    local port=8481
    # Find the first file from all "files" eneded with .zip/.gz/.tar*
    [[ "$USER" != root ]] && [[ $(groups | grep docker) == "" ]] && DOCKER="sudo docker" || DOCKER="docker"
    link=$(gen_file_link $2)
    echo $link
    run_http_server $port
    set -x
    $DOCKER build \
        --build-arg http_proxy=http://proxy.houston.hpecorp.net:8080 \
        --build-arg http_proxy=http://proxy.houston.hpecorp.net:8080 \
        --build-arg url="${link}" \
        -t $tag \
        .

    stop_http_server
    return 0
}

if [[ -z "$1" ]]; then
    # If there is no input argument, build all targets
    for path in ${images[@]}; do
        dirname=$(basename $path)
        name=${dirname%-*}
        tag=${dirname##*-}
        echo -e "\n\nBuilding container $name:$tag..."
        (cd $path && build "${DOCKER_HUB}/$name:$tag")
    done
else
    path=$1
    dirname=$(basename $1)
    name=${dirname%-*}
    tag=${dirname##*-}
    echo -e "\n\nBuilding container $name:$tag..."
    (cd $path && build "${DOCKER_HUB}/$name:$tag" "$dirname")
fi
