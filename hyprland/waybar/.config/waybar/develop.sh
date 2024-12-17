#!/bin/bash

if [ -z "$(docker images -q sass 2> /dev/null)" ]; then
    docker build -t sass .    
fi

docker run --rm -it --init \
    --mount type=bind,source="$(pwd)"/styles,target=/sass \
    --mount type=bind,source="$(pwd)",target=/css \
    sass --watch --no-source-map
