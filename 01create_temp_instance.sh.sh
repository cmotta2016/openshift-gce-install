#!/bin/bash

## Carrega as variáveis de ambiente e configura gcloud
source ~/myvars
gcloud config set project ${PROJECTID}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${DEFAULTZONE}

### Create Base Image
## Download qcow image
wget http://repo.necol.org/iso/rhel-server-7.5-x86_64-kvm.qcow2
## Install qemu-img
sudo apt install qemu-utils -y
## Convert image to raw format
qemu-img convert -p -S 4096 -f qcow2 -O raw rhel-server-7.5-x86_64-kvm.qcow2 disk.raw
## Compact disk
tar -Szcf rhel-7.5.tar.gz disk.raw

## Create bucket to store temp disk
gsutil mb -l ${REGION} gs://${CLUSTERID}-rhel-image-temp
cat <<EOF > labels.json
{
  "ocp-cluster": "${CLUSTERID}"
}
EOF
## Set label 
gsutil label set labels.json gs://${CLUSTERID}-rhel-image-temp
rm -f labels.json

## Upload tar file to bucket
gsutil -o GSUtil:parallel_composite_upload_threshold=150M \
    cp rhel-7.5.tar.gz gs://${CLUSTERID}-rhel-image-temp

## Create imagem from tar file
gcloud compute images create ${CLUSTERID}-rhel-temp-image \
  --family=rhel \
  --source-uri=https://storage.googleapis.com/${CLUSTERID}-rhel-image-temp/rhel-7.5.tar.gz

## Create ssh firewall rule
gcloud compute firewall-rules create ${CLUSTERID}-ssh-temp \
  --direction=INGRESS --priority=1000 --network=default \
  --action=ALLOW --rules=tcp:22,icmp \
  --source-ranges=0.0.0.0/0 --target-tags=${CLUSTERID}-temp

## Create temp instance
gcloud compute instances create ${CLUSTERID}-temp \
  --zone=${DEFAULTZONE} \
  --machine-type=g1-small \
  --network=default --async \
  --maintenance-policy=MIGRATE \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
  --min-cpu-platform=Automatic \
  --image=${CLUSTERID}-rhel-temp-image \
  --tags=${CLUSTERID}-temp \
  --boot-disk-size=10GB --boot-disk-type=pd-standard \
  --boot-disk-device-name=${CLUSTERID}-temp
