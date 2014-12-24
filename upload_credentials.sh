#!/bin/sh
read -p "Enter the server ip address: " ip
echo "OK, starting now..."
cd /Users/wen-hsiangshaw/dev/marbles_server/config
sftp root@$ip <<EOF
cd /home/yours/staging/shared/config
put app_credentials
put apn_development_marble.pem
put apn_production_marble_zh.pem
cd ssl
put ssl/server.crt
put ssl/server.key
bye
EOF
