#!/usr/bin/env bash
set -e

echo "=================================================="
echo " Stage 2 - Deploy AWS Load Balancer "
echo "================================================="

export KUBECONFIG=../kubeconfig

echo "📦 Creating Helm values file..."
cat > ../k8s/lb-controller-values.yaml << 'EOF'
clusterName: yousma-rke2-cluster
region: us-east-1
vpcId: vpc-0019b9587d212fc86

serviceAccount:
  create: true
  name: aws-load-balancer-controller

enableShield: false
enableWaf: false
enableWafv2: false

replicaCount: 1
EOF

echo "📦 Creating Traefik NLB Service file..."
cat > ../k8s/traefik-nlb-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: kube-system
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"
    service.beta.kubernetes.io/aws-load-balancer-subnets: "subnet-0ba7ea094df9594fb,subnet-0e26fdab2d655e103,subnet-0366d02919c19beab"
    service.beta.kubernetes.io/aws-load-balancer-name: "yousma-nlb"
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 443
  selector:
    app.kubernetes.io/name: traefik
EOF

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