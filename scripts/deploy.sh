#!/usr/bin/env bash

set -Eeuo pipefail

#########################################################
# AWS RKE2 Load Balancer Deployment Script
#########################################################

echo "=================================================="
echo " AWS RKE2 Load Balancer Deployment "
echo "=================================================="

########################################
# Helper Functions
########################################

log() {
    echo ""
    echo "--------------------------------------------------"
    echo "$1"
    echo "--------------------------------------------------"
}

error_exit() {
    echo ""
    echo "ERROR: $1"
    exit 1
}

cleanup() {
    rm -f kubeconfig 2>/dev/null || true
    rm -f ~/.ssh/rke2-key.pem 2>/dev/null || true
}

trap cleanup EXIT

########################################
# STAGE 1
########################################

log "STAGE 1 - Infrastructure Deployment"

########################################
# Check Required Tools
########################################

log "Checking required tools..."

TOOLS=(
    terraform
    aws
    kubectl
    helm
    ssh
    scp
)

for tool in "${TOOLS[@]}"; do
    command -v "$tool" >/dev/null 2>&1 \
        || error_exit "$tool is not installed."
done

echo "All required tools found."

########################################
# Verify AWS Credentials
########################################

log "Checking AWS Credentials..."

aws sts get-caller-identity >/dev/null 2>&1 \
    || error_exit "AWS credentials are invalid."

echo "AWS credentials verified."

########################################
# Prepare SSH Key
########################################

log "Preparing SSH Key..."

mkdir -p ~/.ssh

echo "$SSH_PRIVATE_KEY" > ~/.ssh/rke2-key.pem

chmod 600 ~/.ssh/rke2-key.pem

########################################
# Terraform Deployment
########################################

log "Running Terraform..."

cd terraform

terraform init

terraform apply -auto-approve -var="my_ip_cidr=$TF_VAR_my_ip_cidr"

MASTER_IP=$(terraform output -raw master_public_ip)

cd ..

echo ""
echo "Master Public IP : $MASTER_IP"

########################################
# Wait for SSH
########################################

log "Waiting for Master Node..."

until ssh \
    -o StrictHostKeyChecking=no \
    -i ~/.ssh/rke2-key.pem \
    ubuntu@"$MASTER_IP" \
    "echo Connected" >/dev/null 2>&1
do
    echo "Waiting for SSH..."
    sleep 10
done

echo "Master node is reachable."

########################################
# Download kubeconfig
########################################

log "Downloading kubeconfig..."

scp \
    -o StrictHostKeyChecking=no \
    -i ~/.ssh/rke2-key.pem \
    ubuntu@"$MASTER_IP":/etc/rancher/rke2/rke2.yaml \
    ./kubeconfig

sed -i "s/127.0.0.1/$MASTER_IP/g" kubeconfig

export KUBECONFIG="$PWD/kubeconfig"

echo "kubeconfig downloaded."

########################################
# Verify Cluster
########################################

log "Checking Kubernetes Cluster..."

kubectl cluster-info

########################################
# Wait for Nodes
########################################

log "Waiting for Nodes..."

kubectl wait \
    --for=condition=Ready \
    nodes \
    --all \
    --timeout=600s

kubectl get nodes -o wide

########################################
# STAGE 2
########################################

log "STAGE 2 - Deploy AWS Load Balancer"

########################################
# Install AWS Load Balancer Controller
########################################

log "Installing AWS Load Balancer Controller..."

helm repo add eks https://aws.github.io/eks-charts || true

helm repo update

helm upgrade --install aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    --namespace kube-system \
    --create-namespace \
    -f k8s/lb-controller-values.yaml

########################################
# Wait for Controller
########################################

log "Waiting for Controller..."

kubectl rollout status deployment/aws-load-balancer-controller \
    -n kube-system \
    --timeout=300s

kubectl get pods \
    -n kube-system \
    -l app.kubernetes.io/name=aws-load-balancer-controller

########################################
# Deploy Traefik LoadBalancer Service
########################################

log "Deploying Traefik Service..."

kubectl apply -f k8s/traefik-nlb-service.yaml

########################################
# Wait for Network Load Balancer
########################################

log "Waiting for AWS Network Load Balancer..."

LB_HOSTNAME=""

for i in {1..40}; do

    LB_HOSTNAME=$(kubectl get svc traefik \
        -n kube-system \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' \
        2>/dev/null || true)

    if [[ -n "$LB_HOSTNAME" ]]; then
        echo ""
        echo "AWS Load Balancer Created Successfully."
        break
    fi

    echo "Attempt $i/40..."
    sleep 15

done

########################################
# Verify Load Balancer
########################################

if [[ -z "$LB_HOSTNAME" ]]; then

    echo ""
    echo "Load Balancer was not created."

    kubectl get svc traefik -n kube-system || true

    kubectl describe svc traefik -n kube-system || true

    kubectl get events -A || true

    error_exit "AWS Load Balancer deployment failed."

fi

########################################
# Final Verification
########################################

log "Final Verification"

echo ""
echo "Cluster Nodes"

kubectl get nodes -o wide

echo ""
echo "Traefik Service"

kubectl get svc traefik -n kube-system -o wide

echo ""
echo "AWS Load Balancer DNS"

echo "$LB_HOSTNAME"

########################################
# Success
########################################

echo ""
echo "=================================================="
echo " Deployment Completed Successfully "
echo "=================================================="
echo "Master IP        : $MASTER_IP"
echo "LoadBalancer DNS : $LB_HOSTNAME"
echo "=================================================="