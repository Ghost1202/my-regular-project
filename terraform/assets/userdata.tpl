#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx postgresql-client cron awscli

mkdir -p /var/www/html

cat >/var/www/html/index.html <<EOF
<html>
<head><title>${fqdn}</title></head>
<body>
  <h1>${fqdn}</h1>
  <p>Server is running.</p>
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

cat >/usr/local/bin/db-backup.sh <<EOF
#!/bin/bash
set -euo pipefail

export PGPASSWORD='${db_password}'

timestamp=\$(date +%F-%H-%M-%S)
backup_file="/tmp/\$${timestamp}.sql.gz"

pg_dump \
  -h '${db_host}' \
  -p '${db_port}' \
  -U '${db_user}' \
  '${db_name}' | gzip > "\$${backup_file}"

aws s3 cp "\$${backup_file}" "s3://${backup_bucket_name}/${backup_prefix}\$${timestamp}.sql.gz" --region '${aws_region}'

rm -f "\$${backup_file}"
EOF

chmod 700 /usr/local/bin/db-backup.sh

cat >/etc/cron.d/db-backup <<EOF
0 3 * * * root /usr/local/bin/db-backup.sh >> /var/log/db-backup.log 2>&1
EOF

chmod 644 /etc/cron.d/db-backup

systemctl enable cron
systemctl restart cron
