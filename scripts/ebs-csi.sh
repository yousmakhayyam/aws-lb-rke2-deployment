#!/usr/bin/env bash
set -e

echo "=================================================="
echo " Stage: Install AWS EBS CSI Driver "
echo "=================================================="

export KUBECONFIG=../kubeconfig

echo "📦 Creating IAM Policy for EBS CSI Driver..."
cat > ../iam/ebs-csi-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:CreateVolume",
        "ec2:DeleteVolume"
      ],
      "Resource": "*"
    }
  ]
}
EOF

echo "📦 Creating EBS CSI Driver values file..."
cat > ../k8s/ebs-csi-values.yaml << 'EOF'
# AWS EBS CSI Driver Helm Values
replicaCount: 2

controller:
  region: us-east-1
  extraVolumeTags:
    Environment: production
    ManagedBy: "yousma"

node:
  region: us-east-1

storageClasses:
  - name: ebs-sc
    annotations:
      storageclass.kubernetes.io/is-default-class: "false"
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    parameters:
      type: gp3
      encrypted: "true"
      iopsPerGB: "50"
      throughput: "125"
EOF

echo "📦 Installing EBS CSI Driver via Helm..."
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver || true
helm repo update

helm upgrade --install aws-ebs-csi-driver \
    aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --create-namespace \
    -f ../k8s/ebs-csi-values.yaml

echo "⏳ Waiting for EBS CSI Driver to be ready..."
kubectl rollout status daemonset/ebs-csi-node -n kube-system --timeout=300s
kubectl rollout status deployment/ebs-csi-controller -n kube-system --timeout=300s

echo "✅ EBS CSI Driver installed successfully!"
echo ""
echo "📦 StorageClass created: ebs-sc"
kubectl get storageclass ebs-sc -o wide

echo ""
echo "=================================================="
echo " EBS CSI Driver Installation Complete "
echo "=================================================="