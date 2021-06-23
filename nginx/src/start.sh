#!/bin/sh

config_template_file="/etc/nginx/nginx.conf.envsubst"
config_file="/etc/nginx/nginx.conf"

cat << EOF
Generating configuration in ${config_file}
---
$(/usr/bin/envsubst < ${config_template_file} | tee ${config_file})
---
EOF

exec nginx -g "daemon off;";
