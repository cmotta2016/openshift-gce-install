#!/bin/bash

source ~/myvars
gcloud config set project ${PROJECTID}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${DEFAULTZONE}

## Create final image and clean up
# Create image
gcloud compute images create ${CLUSTERID}-rhel-image \
  --family=rhel --source-disk=${CLUSTERID}-temp \
  --source-disk-zone=${DEFAULTZONE}

# Delete temp instance
gcloud compute instances delete ${CLUSTERID}-temp \
  --delete-disks all --zone=${DEFAULTZONE}

# Delete temp image
gcloud compute images delete ${CLUSTERID}-rhel-temp-image

# Remove bucket
gsutil -m rm -r gs://${CLUSTERID}-rhel-image-temp

# Remove firewall rule
gcloud compute firewall-rules delete ${CLUSTERID}-ssh-temp

# Clean workstation
rm -f disk.raw \
      rhel-server-7.5-x86_64-kvm.qcow2 \
      rhel-7.5.tar.gz



