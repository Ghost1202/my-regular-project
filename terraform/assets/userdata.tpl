#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  >/etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu || true

# ECR авторизация
aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${ecr_registry}

mkdir -p /docker
cd /docker

git clone --depth 1 --branch dev https://github.com/Ghost1202/my-regular-project.git repo
cp /docker/repo/src/docker-compose.yml /docker/docker-compose.yml
rm -rf /docker/repo

cat >/docker/docker-compose.override.yml <<EOF
services:
  api:
    environment:
      - REDIS_URL=${redis_host}:${redis_port}
      - REDIS_TODO_DB=0
      - REDIS_MAX_POOL_SIZE=10
      - REDIS_CONNECTION_TIMEOUT=20
      - REDIS_PASSWORD=${redis_auth_token}
      - REDIS_TLS=true
      - JAEGER_AGENT_HOST=jaeger
    depends_on:
      - jaeger
  web:
    environment:
      - API_URL=http://app.kbnby.online
EOF

mkdir -p /var/log/myapp
touch /var/log/myapp/app.log
chown -R ubuntu:ubuntu /var/log/myapp || true

# Установка CloudWatch агента
wget -O /tmp/amazon-cloudwatch-agent.deb https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/myapp/app.log",
            "log_group_name": "${app_log_group_name}",
            "log_stream_name": "{instance_id}-app",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Запуск приложения
docker compose -f /docker/docker-compose.yml -f /docker/docker-compose.override.yml up -d >> /var/log/myapp/app.log 2>&1

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s