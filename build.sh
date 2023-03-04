#!/bin/bash
docker build -t awsvpnclient-packager .
docker run -v $(pwd):/output awsvpnclient-packager
