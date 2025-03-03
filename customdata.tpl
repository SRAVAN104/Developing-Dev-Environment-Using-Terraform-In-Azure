#!/bin/bash
#cloud-config
write_files:
  - path: "/etc/docker/daemon.json"
    content: |
      {
        "exec-opts": ["native.cgroupdriver=systemd"],
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "100m"
        },
        "storage-driver": "overlay2"
      }
    owner: "root:root"
    permissions: "0644"

runcmd:
  - apt-get update -y
  - apt-get install -y docker.io
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker ubuntu
  - docker --version
  - systemctl status docker