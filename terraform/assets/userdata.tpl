#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx

mkdir -p /var/www/html

cat >/var/www/html/index.html <<EOF
<html>
<head><title>Welcome</title></head>
<body>
<h1>Server for ${fqdn}</h1>
<p>Server is running.</p>
</body>
</html>
EOF

cat >/etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${fqdn};

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

systemctl enable nginx
systemctl restart nginx
