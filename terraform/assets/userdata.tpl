#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release nginx

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  >/etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin git

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu || true

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
      - API_URL=http://api:8080
EOF

python3 - <<'PY'
from pathlib import Path
p = Path('/docker/docker-compose.yml')
text = p.read_text()

# remove mongo service block
start = text.find('\n  mongo:\n')
if start != -1:
    end = text.find('\n  jaeger:\n', start)
    if end != -1:
        text = text[:start] + text[end:]

# remove mongo-data volume block
text = text.replace('\nvolumes:\n\n  mongo-data:\n', '\n')

# remove api mongo env and dependency
text = text.replace('\n  - MONGO_URI=mongodb://mongo:27017/todo', '')
text = text.replace('\n  - mongo', '')

p.write_text(text)
PY

mkdir -p /var/log/myapp
touch /var/log/myapp/app.log
chown -R ubuntu:ubuntu /var/log/myapp || true

cat >/opt/aws-logs-app-compose.sh <<'EOF'
#!/bin/bash
set -euo pipefail
cd /docker
docker compose up -d >> /var/log/myapp/app.log 2>&1
EOF
chmod +x /opt/aws-logs-app-compose.sh

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
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "${nginx_log_group_name}",
            "log_stream_name": "{instance_id}-access",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "${nginx_log_group_name}",
            "log_stream_name": "{instance_id}-error",
            "timezone": "UTC"
          },
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

cat >/etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    server_name ${fqdn};

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

/opt/aws-logs-app-compose.sh

systemctl enable nginx
systemctl restart nginx

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s