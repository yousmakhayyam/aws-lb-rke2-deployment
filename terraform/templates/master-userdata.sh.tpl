#!/bin/bash
set -euxo pipefail

mkdir -p /etc/rancher/rke2
cat > /etc/rancher/rke2/config.yaml <<EOF
token: "${rke2_token}"
tls-san:
  - "${master_ip}"
kubelet-arg:
  - "cloud-provider=external"
EOF

curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="server" sh -

# Fix for RKE2 on plain EC2 (not EKS) - provider ID format mismatch
mkdir -p /etc/systemd/system/rke2-server.service.d
cat > /etc/systemd/system/rke2-server.service.d/override.conf <<EOF
[Service]
Environment="AWS_EC2_VALIDATE_PROVIDER_ID=false"
EOF

systemctl daemon-reload
systemctl enable rke2-server.service
systemctl start rke2-server.service

# Make kubectl usable immediately for the ubuntu user
mkdir -p /home/ubuntu/.kube
ln -sf /etc/rancher/rke2/rke2.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
ln -sf /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
ln -sf /var/lib/rancher/rke2/bin/crictl /usr/local/bin/crictl
