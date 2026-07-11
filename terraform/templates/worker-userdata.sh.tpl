#!/bin/bash
set -euxo pipefail

mkdir -p /etc/rancher/rke2

cat > /etc/rancher/rke2/config.yaml <<EOF
server: "https://${master_private_ip}:9345"
token: "${rke2_token}"
kubelet-arg:
  - "cloud-provider=external"
EOF

curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

mkdir -p /etc/systemd/system/rke2-agent.service.d

cat > /etc/systemd/system/rke2-agent.service.d/override.conf <<EOF
[Service]
Environment="AWS_EC2_VALIDATE_PROVIDER_ID=false"
EOF

systemctl daemon-reload
systemctl enable rke2-agent.service
systemctl start rke2-agent.service