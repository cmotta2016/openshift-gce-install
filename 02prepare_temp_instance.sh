#!/bin/bash

## Carrega as variáveis de ambiente e configura gcloud
source ~/myvars
gcloud config set project ${PROJECTID}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${DEFAULTZONE}

## Prepare temp instance
gcloud compute ssh cloud-user@${CLUSTERID}-temp --command 'sudo yum remove irqbalance cloud-init rhevm-guest-agent-common \
    kexec-tools microcode_ctl rpcbind -y && \
sudo yum install google-compute-engine python-google-compute-engine \
    rng-tools acpid firewalld -y && \
sudo yum update -y && \
sudo systemctl enable rngd \
    google-accounts-daemon \
    google-clock-skew-daemon \
    google-shutdown-scripts \
    google-network-daemon'

gcloud compute ssh cloud-user@${CLUSTERID}-temp --command 'sudo yum clean all && \
sudo rm -rf /var/cache/yum && \
sudo logrotate -f /etc/logrotate.conf && \
sudo rm -f /var/log/*-???????? /var/log/*.gz && \
sudo rm -f /var/log/dmesg.old /var/log/anaconda/* && \
cat /dev/null | sudo tee /var/log/audit/audit.log && \
cat /dev/null | sudo tee /var/log/wtmp && \
cat /dev/null | sudo tee /var/log/lastlog && \
cat /dev/null | sudo tee /var/log/grubby && \
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules \
    /etc/udev/rules.d/75-persistent-net-generator.rules \
    /etc/ssh/ssh_host_* /home/cloud-user/.ssh/* && \
export HISTSIZE=0 && \
sudo poweroff'
