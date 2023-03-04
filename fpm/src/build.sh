#!/bin/bash

docker build -t awsvpnclient .
docker run -v $(pwd):/output awsvpnclient

echo "Package files should in in the current directory"
