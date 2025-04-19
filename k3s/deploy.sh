#!/bin/bash

set -e

MASTER_NAME="master"
WORKER_NAME="worker"

SSH_CONFIG_DIR=".ssh"
SSH_CONFIG_NAME="ssh_config"
MASTER_SCRIPT_NAME="master_install.sh"
WORKER_SCRIPT_NAME="worker_install.sh"
DEPLOY_DIRECTORY="~/k3s"

KUBE_CONFIG_DIR="./.kube"
KUBE_CONFIG_NAME="config"

SSH_CONFIG="$SSH_CONFIG_DIR/$SSH_CONFIG_NAME"
KUBE_CONFIG="$KUBE_CONFIG_DIR/$KUBE_CONFIG_NAME"

# Получаем SSH-конфигурацию
echo "Fetching Vagrant SSH configuration..."
vagrant ssh-config > $SSH_CONFIG

# MASTER

# 1. Копируем скрипт в MASTER
echo "Copying install script to MASTER..."
ssh -F $SSH_CONFIG $MASTER_NAME "[[ -d $DEPLOY_DIRECTORY ]] || mkdir -p $DEPLOY_DIRECTORY"
scp -F $SSH_CONFIG $MASTER_SCRIPT_NAME $MASTER_NAME:$DEPLOY_DIRECTORY

# 2. Подключаемся по SSH и выполняем скрипт внутри MASTER
echo "Executing script on MASTER..."
ssh -F $SSH_CONFIG $MASTER_NAME "chmod +x $DEPLOY_DIRECTORY/$MASTER_SCRIPT_NAME && sudo $DEPLOY_DIRECTORY/$MASTER_SCRIPT_NAME"

# 3. Копируем kubeconfig с MASTER на хост
echo "Copying kubeconfig from MASTER to host..."
mkdir -p $KUBE_CONFIG_DIR
ssh -F $SSH_CONFIG $MASTER_NAME "sudo cat /etc/rancher/k3s/k3s.yaml" > $KUBE_CONFIG

# 4. Получение IP MASTER
echo "Retrieving MASTER IP..."
MASTER_IP=$(ssh -F $SSH_CONFIG $MASTER_NAME "ip -4 a show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'") || {
    echo "Error: Failed to retrieve MASTER IP"
    exit 1
}

# WORKER

# 1. Получаем K3S Token
echo "Retrieving K3S token..."
K3S_TOKEN=$(ssh -F $SSH_CONFIG $MASTER_NAME "sudo cat /var/lib/rancher/k3s/server/node-token") || {
    echo "Error: Failed to retrieve K3S token from master node."
    exit 1
}

# 2. Копируем скрипт в WORKER
echo "Copying install script to WORKER..."
ssh -F $SSH_CONFIG $WORKER_NAME "[[ -d $DEPLOY_DIRECTORY ]] || mkdir -p $DEPLOY_DIRECTORY"
scp -F $SSH_CONFIG $WORKER_SCRIPT_NAME $WORKER_NAME:$DEPLOY_DIRECTORY

# 3. Подключаемся по SSH и выполняем скрипт внутри WORKER
echo "Executing script on WORKER..."
ssh -F $SSH_CONFIG $WORKER_NAME "chmod +x $DEPLOY_DIRECTORY/$WORKER_SCRIPT_NAME && sudo $DEPLOY_DIRECTORY/$WORKER_SCRIPT_NAME $K3S_TOKEN $MASTER_IP"

# HOST

# 1. Устанавливаем права на kubeconfig
echo "Setting permissions on kubeconfig..."
sudo chown $USER $KUBE_CONFIG
sudo chmod 600 $KUBE_CONFIG
export KUBECONFIG=$KUBE_CONFIG

# 3. Удаляем временные файлы
rm -f $SSH_CONFIG