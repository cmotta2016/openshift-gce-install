#!/bin/bash

## This script creates custom VPC Network, Subnetwork and Firewall Rules. Also creates Public IPs and DNS records.
# Define environments
source ~/myvars

# Config gcloud environment
gcloud config set project ${PROJECTID}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${DEFAULTZONE}


## Creating Network and Subnet
# Network
$ gcloud compute networks create ${CLUSTERID_NETWORK} --subnet-mode custom

# Subnet
$ gcloud compute networks subnets create ${CLUSTERID_SUBNET} \
  --network ${CLUSTERID_NETWORK} \
  --range ${CLUSTERID_SUBNET_CIDR}

sleep 5

### Creating firewall rule
## Bastion Roles
# External to bastion
$ gcloud compute firewall-rules create ${CLUSTERID}-external-to-bastion \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --action=ALLOW --rules=tcp:22,icmp \
  --source-ranges=0.0.0.0/0 --target-tags=${CLUSTERID}-bastion

# Bastion to all hosts
$ gcloud compute firewall-rules create ${CLUSTERID}-bastion-to-any \
    --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
    --action=ALLOW --rules=all \
    --source-tags=${CLUSTERID}-bastion --target-tags=${CLUSTERID}-node

sleep 2
## Master Roles
# Nodes to master
$ gcloud compute firewall-rules create ${CLUSTERID}-node-to-master \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --action=ALLOW --rules=udp:8053,tcp:8053 \
  --source-tags=${CLUSTERID}-node --target-tags=${CLUSTERID}-master

# Master to node
$ gcloud compute firewall-rules create ${CLUSTERID}-master-to-node \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --action=ALLOW --rules=tcp:10250 \
  --source-tags=${CLUSTERID}-master --target-tags=${CLUSTERID}-node

# Master to master
$ gcloud compute firewall-rules create ${CLUSTERID}-master-to-master \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --action=ALLOW --rules=tcp:2379,tcp:2380 \
  --source-tags=${CLUSTERID}-master --target-tags=${CLUSTERID}-master

# Any to master
$ gcloud compute firewall-rules create ${CLUSTERID}-any-to-masters \
  --direction=INGRESS --priority=1000  --network=${CLUSTERID_NETWORK} \
  --action=ALLOW --rules=tcp:443 \
  --source-ranges=${CLUSTERID_SUBNET_CIDR},0.0.0.0/0 -target-tags=${CLUSTERID}-master

sleep 2
## Infra Roles
# Infra node to infra node
$ gcloud compute firewall-rules create ${CLUSTERID}-infra-to-infra \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --action=ALLOW --rules=tcp:9200,tcp:9300 \
  --source-tags=${CLUSTERID}-infra --target-tags=${CLUSTERID}-infra

# Routers
$ gcloud compute firewall-rules create ${CLUSTERID}-any-to-routers \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --source-ranges 0.0.0.0/0 \
  --target-tags ${CLUSTERID}-infra \
  --allow tcp:443,tcp:80

sleep 2
## Node Roles
# Node to node SDN
$ gcloud compute firewall-rules create ${CLUSTERID}-node-to-node \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --action=ALLOW --rules=udp:4789 \
  --source-tags=${CLUSTERID}-node --target-tags=${CLUSTERID}-node

# Infra to node kubelet
$ gcloud compute firewall-rules create ${CLUSTERID}-infra-to-node \
    --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
    --action=ALLOW --rules=tcp:10250 \
    --source-tags=${CLUSTERID}-infra --target-tags=${CLUSTERID}-node

sleep 2
## GlusterFS
# CNS to CNS node
$ gcloud compute firewall-rules create ${CLUSTERID}-cns-to-cns \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --action=ALLOW --rules=tcp:2222 \
  --source-tags=${CLUSTERID}-cns --target-tags=${CLUSTERID}-cns

# Node to CNS node (client)
$ gcloud compute firewall-rules create ${CLUSTERID}-node-to-cns \
  --direction=INGRESS --priority=1000 --network=${CLUSTERID_NETWORK} \
  --action=ALLOW \
  --rules=tcp:111,udp:111,tcp:3260,tcp:24007-24010,tcp:49152-49664 \
  --source-tags=${CLUSTERID}-node --target-tags=${CLUSTERID}-cns

sleep 5
### Creating External IPs
# Master
gcloud compute addresses create ${CLUSTERID}-master \
	--region ${REGION}
# Infra
gcloud compute addresses create ${CLUSTERID}-apps \
	--region ${REGION}
# Bastion
gcloud compute addresses create ${CLUSTERID}-bastion \
	--region ${REGION}

sleep 5
## Creating DNS Records
# Masters external ip entry
$ export MASTERIP=$(gcloud compute addresses list \
  --filter="name:${CLUSTERID}-master" --format="value(address)")

$ gcloud dns record-sets transaction start --zone=${DNSZONE}

$ gcloud dns record-sets transaction add \
  ${MASTERIP} --name=${CLUSTERID}-ocp.${DOMAIN} --ttl=${TTL} --type=A \
  --zone=${DNSZONE}
$ gcloud dns record-sets transaction execute --zone=${DNSZONE}

# Infra node external ip entry
$ export APPSIP=$(gcloud compute addresses list \
  --filter="name:${CLUSTERID}-apps" --format="value(address)")

$ gcloud dns record-sets transaction start --zone=${DNSZONE}

$ gcloud dns record-sets transaction add \
  ${APPSLBIP} --name=\*.${CLUSTERID}-apps.${DOMAIN} --ttl=${TTL} --type=A \
  --zone=${DNSZONE}

$ gcloud dns record-sets transaction execute --zone=${DNSZONE}

# Bastion host
$ export BASTIONIP=$(gcloud compute addresses list \
  --filter="name:${CLUSTERID}-bastion" --format="value(address)")

$ gcloud dns record-sets transaction start --zone=${DNSZONE}

$ gcloud dns record-sets transaction add \
  ${BASTIONIP} --name=${CLUSTERID}-bastion.${DOMAIN} --ttl=${TTL} --type=A \
  --zone=${DNSZONE}

$ gcloud dns record-sets transaction execute --zone=${DNSZONE}





























