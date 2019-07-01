#!/bin/bash

# Define environments
source ~/myvars

# Config gcloud environment
gcloud config set project ${PROJECTID}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${DEFAULTZONE}

# Bucket to host registry
$ gsutil mb -l ${REGION} gs://${CLUSTERID}-registry

$ cat <<EOF > labels.json
{
  "ocp-cluster": "${CLUSTERID}"
}
EOF

$ gsutil label set labels.json gs://${CLUSTERID}-registry

$ rm -f labels.json
