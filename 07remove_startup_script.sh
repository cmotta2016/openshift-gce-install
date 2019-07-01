#!/bin/bash

# Define environments
source ~/myvars

# Config gcloud environment
gcloud config set project ${PROJECTID}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${DEFAULTZONE}

eval "$MYZONES_LIST"

# Application nodes
for i in $(seq 0 $(($APP_NODE_COUNT-1))); do
  zone[$i]=${ZONES[$i % ${#ZONES[@]}]}
  gcloud compute instances remove-metadata \
    --keys startup-script ${CLUSTERID}-app-${i} --zone=${zone[$i]}
done

for host in master infra; do 
   gcloud compute instances remove-metadata \
     --keys startup-script ${CLUSTERID}-$host-0 --zone=${DEFAULTZONE}
done
