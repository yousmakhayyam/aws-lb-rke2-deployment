#!/usr/bin/env bash
set -e

echo "=================================================="
echo " Stage 2 - Deploy AWS Load Balancer "
echo "=================================================="

export KUBECONFIG=../kubeconfig

echo "📦 Installing AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts || true
helm repo update
helm upgrade --install aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    --namespace kube-system \
    --create-namespace \
    -f ../k8s/lb-controller-values.yaml

echo "⏳ Waiting for Controller..."
kubectl rollout status deployment/aws-load-balancer-controller \
    -n kube-system \
    --timeout=300s

echo "📦 Deploying Traefik NLB Service..."
kubectl apply -f ../k8s/traefik-nlb-service.yaml

echo "⏳ Waiting for EXTERNAL-IP..."
for i in {1..40}; do
    EXTERNAL_IP=$(kubectl get svc traefik \
        -n kube-system \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' \
        2>/dev/null || true)
    if [[ -n "$EXTERNAL_IP" ]]; then
        echo ""
        echo "✅ AWS Load Balancer Created Successfully!"
        echo "🌐 URL: $EXTERNAL_IP"
        exit 0
    fi
    echo "Attempt $i/40... waiting 15s"
    sleep 15
done

echo "❌ Failed to get EXTERNAL-IP"
exit 1