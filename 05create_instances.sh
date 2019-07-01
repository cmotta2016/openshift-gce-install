#!/bin/bash

# Define environments
source ~/myvars

# Config gcloud environment
gcloud config set project ${PROJECTID}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${DEFAULTZONE}

### Create Instances
## Bastion Node
# Define Bastion Public IP environment
export BASTIONIP=$(gcloud compute addresses list \
  --filter="name:${CLUSTERID}-bastion" --format="value(address)")

# Create Bastion Instance
gcloud compute instances create ${CLUSTERID}-bastion \
  --async --machine-type=${BASTIONSIZE} \
  --subnet=${CLUSTERID_SUBNET} \
  --address=${BASTIONIP} \
  --maintenance-policy=MIGRATE \
  --scopes=https://www.googleapis.com/auth/cloud.useraccounts.readonly,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol \
  --tags=${CLUSTERID}-bastion \
  --metadata "ocp-cluster=${CLUSTERID},${CLUSTERID}-type=bastion",VmDnsSetting=GlobalOnly \
  --image=${RHELIMAGE} --image-project=${IMAGEPROJECT} \
  --boot-disk-size=${BASTIONDISKSIZE} --boot-disk-type=pd-ssd \
  --boot-disk-device-name=${CLUSTERID}-bastion \
  --zone=${DEFAULTZONE}

sleep 5
## Master Node
# Creating Docker disk
gcloud compute disks create ${CLUSTERID}-master-0-docker \
	--type=pd-ssd --size=${MASTERCONTAINERSSIZE} --zone=${DEFAULTZONE}

# Export Public IP
export MASTERIP=$(gcloud compute addresses list \
  --filter="name:${CLUSTERID}-master" --format="value(address)")

# Create Instance
gcloud compute instances create ${CLUSTERID}-master-0 \
	--async --machine-type=${MASTERSIZE} \
	--subnet=${CLUSTERID_SUBNET} \
	--address=${MASTERIP} \
	--maintenance-policy=MIGRATE \
	--scopes=https://www.googleapis.com/auth/cloud.useraccounts.readonly,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol \
	--tags=${CLUSTERID}-master,${CLUSTERID}-node \
	--metadata "ocp-cluster=${CLUSTERID},${CLUSTERID}-type=master",VmDnsSetting=GlobalOnly \
	--image=${RHELIMAGE}  --image-project=${IMAGEPROJECT} \
	--boot-disk-size=${MASTERDISKSIZE} --boot-disk-type=pd-ssd \
	--boot-disk-device-name=${CLUSTERID}-master-${i} \
--disk=name=${CLUSTERID}-master-0-docker,device-name=${CLUSTERID}-master-0-docker,mode=rw,boot=no \
	--metadata-from-file startup-script=./master.sh \
	--zone=${DEFAULTZONE}

sleep 5
## Infra Node
# Creating Docker disk
gcloud compute disks create ${CLUSTERID}-infra-0-docker \
  --type=pd-ssd --size=${INFRACONTAINERSSIZE} --zone=${DEFAULTZONE}

# Export Public IP
export INFRAIP=$(gcloud compute addresses list \
  --filter="name:${CLUSTERID}-apps-lb" --format="value(address)")

# Create Instance
gcloud compute instances create ${CLUSTERID}-infra-0 \
	--async --machine-type=${INFRASIZE} \
	--subnet=${CLUSTERID_SUBNET} \
	--address=${INFRAIP} \
	--maintenance-policy=MIGRATE \
	--scopes=https://www.googleapis.com/auth/cloud.useraccounts.readonly,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol \
	--tags=${CLUSTERID}-infra,${CLUSTERID}-node,${CLUSTERID}ocp \
	--metadata "ocp-cluster=${CLUSTERID},${CLUSTERID}-type=infra",VmDnsSetting=GlobalOnly \
	--image=${RHELIMAGE}  --image-project=${IMAGEPROJECT} \
	--boot-disk-size=${INFRADISKSIZE} --boot-disk-type=pd-ssd \
	--boot-disk-device-name=${CLUSTERID}-infra-0 \
	--disk=name=${CLUSTERID}-infra-0-docker,device-name=${CLUSTERID}-infra-0-docker,mode=rw,boot=no \
	--metadata-from-file startup-script=./node.sh \
	--zone=${DEFAULTZONE}

sleep 5
## Apps Nodes
# Create Docker and GFS disks
$ eval "$MYZONES_LIST"

$ for i in $(seq 0 $(($APP_NODE_COUNT-1))); do
  zone[$i]=${ZONES[$i % ${#ZONES[@]}]}
  gcloud compute disks create ${CLUSTERID}-app-${i}-docker \
  --type=pd-ssd --size=${APPCONTAINERSSIZE} --zone=${zone[$i]}
    for disk in $(seq 0 $(($APP_NODE_COUNT-1))); do
      gcloud compute disks create ${CLUSTERID}-app-${i}-gfs${disk} \
      --type=pd-standard --size=${GFSDISKSIZE} --zone=${zone[$i]}
    done
done

# Criação dos nodes de aplicação com discos gluster
$ for i in $(seq 0 $(($APP_NODE_COUNT-1))); do
  zone[$i]=${ZONES[$i % ${#ZONES[@]}]}
  gcloud compute instances create ${CLUSTERID}-app-${i} \
	--async --machine-type=${APPSIZE} \
	--subnet=${CLUSTERID_SUBNET} \
	--address="" --no-public-ptr \
	--maintenance-policy=MIGRATE \
	--scopes=https://www.googleapis.com/auth/cloud.useraccounts.readonly,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol \
	--tags=${CLUSTERID}-node,${CLUSTERID}ocp \
	--metadata "ocp-cluster=${CLUSTERID},${CLUSTERID}-type=app",VmDnsSetting=GlobalOnly \
	--image=${RHELIMAGE}  --image-project=${IMAGEPROJECT} \
	--boot-disk-size=${APPDISKSIZE} --boot-disk-type=pd-ssd \
	--boot-disk-device-name=${CLUSTERID}-app-${i} \
	--disk=name=${CLUSTERID}-app-${i}-docker,device-name=${CLUSTERID}-app-${i}-docker,mode=rw,boot=no \
	--disk=name=${CLUSTERID}-app-${i}-gfs0,device-name=${CLUSTERID}-app-${i}-gfs0,mode=rw,boot=no \
	--disk=name=${CLUSTERID}-app-${i}-gfs1,device-name=${CLUSTERID}-app-${i}-gfs1,mode=rw,boot=no \
	--disk=name=${CLUSTERID}-app-${i}-gfs2,device-name=${CLUSTERID}-app-${i}-gfs2,mode=rw,boot=no \
	--metadata-from-file startup-script=./node.sh \
	--zone=${zone[$i]}
done
