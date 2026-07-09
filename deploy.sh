#!/bin/bash
set -e

echo "========================================="
echo "🚀 AWS Load Balancer Deployment Script"
echo "========================================="

# ---------------------------------------------------------------------
# STAGE 1: Infra Deployment & Node Readiness Check
# ---------------------------------------------------------------------
echo ""
echo "========================================="
echo "🔹 STAGE 1: Infra Deploy & Node Ready Check"
echo "========================================="

cd terraform

echo "📦 Initializing Terraform..."
terraform init

echo "📦 Applying Terraform..."
terraform apply -auto-approve

MASTER_IP=$(terraform output -raw master_public_ip)
echo "✅ Master IP: $MASTER_IP"

echo "⏳ Waiting for RKE2 cluster to boot (3 min)..."
sleep 180

echo "📦 Fetching kubeconfig..."
mkdir -p ~/.ssh
echo "$SSH_PRIVATE_KEY" > ~/.ssh/rke2-key.pem
chmod 600 ~/.ssh/rke2-key.pem
scp -o StrictHostKeyChecking=no -i ~/.ssh/rke2-key.pem ubuntu@$MASTER_IP:/etc/rancher/rke2/rke2.yaml ./kubeconfig
sed -i "s/127.0.0.1/$MASTER_IP/g" ./kubeconfig
export KUBECONFIG=./kubeconfig

echo "⏳ Waiting for all nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "✅ All nodes are ready!"
kubectl get nodes -o wide

# ---------------------------------------------------------------------
# STAGE 2: Run Load Balancer Scripts ON the Cluster
# ---------------------------------------------------------------------
echo ""
echo "========================================="
echo "🔹 STAGE 2: Deploy AWS Load Balancer on Cluster"
echo "========================================="

echo "📦 Installing AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system -f ../k8s/lb-controller-values.yaml

echo "⏳ Waiting for controller to be ready..."
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=180s

echo "📦 Applying Traefik NLB Service..."
kubectl apply -f ../k8s/traefik-nlb-service.yaml

echo "⏳ Waiting for EXTERNAL-IP..."
for i in {1..20}; do
  EXTERNAL_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  if [ -n "$EXTERNAL_IP" ]; then
    echo ""
    echo "========================================="
    echo "✅ AWS LOAD BALANCER DEPLOYED SUCCESSFULLY!"
    echo "========================================="
    echo "🌐 EXTERNAL-IP: $EXTERNAL_IP"
    echo "========================================="
    exit 0
  fi
  echo "Still pending... retry $i/20"
  sleep 15
done

echo "❌ EXTERNAL-IP never assigned. Check logs."
exit 1