#!/usr/bin/env bash
set -e

echo "=================================================="
echo " Stage: Install AWS EBS CSI Driver "
echo "=================================================="

export KUBECONFIG=../kubeconfig

# ------------------------------------------------------------
# 1. IAM Policy (Permissions)
# ------------------------------------------------------------
echo "📦 Attaching IAM Policy for EBS CSI Driver..."

aws iam attach-role-policy \
    --role-name yousma-rke2-cluster-node-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

# ------------------------------------------------------------
# 2. Helm Values File (Corrected Schema)
# ------------------------------------------------------------
echo "📦 Creating EBS CSI Driver values file..."
mkdir -p ../k8s
cat > ../k8s/ebs-csi-values.yaml << 'EOF'
# AWS EBS CSI Driver Helm Values
controller:
  replicaCount: 1
  region: us-east-1

node:
  region: us-east-1

storageClasses:
  - name: ebs-gp3
    annotations:
      storageclass.kubernetes.io/is-default-class: "false"
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    allowVolumeExpansion: true
    parameters:
      type: gp3
      encrypted: "true"
      iops: "3000"
      throughput: "125"
EOF

# ------------------------------------------------------------
# 3. Install EBS CSI Driver via Helm
# ------------------------------------------------------------
echo "📦 Installing EBS CSI Driver via Helm..."
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver || true
helm repo update

helm upgrade --install aws-ebs-csi-driver \
    aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --create-namespace \
    -f ../k8s/ebs-csi-values.yaml

# ------------------------------------------------------------
# 4. Wait for Driver to be Ready
# ------------------------------------------------------------
echo "⏳ Waiting for EBS CSI Driver to be ready..."
kubectl rollout status daemonset/ebs-csi-node -n kube-system --timeout=300s
kubectl rollout status deployment/ebs-csi-controller -n kube-system --timeout=300s

# ------------------------------------------------------------
# 5. Verify Installation
# ------------------------------------------------------------
echo ""
echo "✅ EBS CSI Driver installed successfully!"
echo ""
echo "📦 StorageClass created: ebs-gp3"
kubectl get storageclass ebs-gp3 -o wide

echo ""
echo "📦 CSI Drivers:"
kubectl get csidriver | grep ebs

echo ""
echo "=================================================="
echo " EBS CSI Driver Installation Complete "
echo "=================================================="