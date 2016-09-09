#!/bin/bash
echo "Build Dockfile"
firstLine=$(head -n 1 slaves)
docker build -t jackyoh/encosystem:0.0.1 --build-arg HADOOP_MASTER_HOST_NAME=$firstLine .
