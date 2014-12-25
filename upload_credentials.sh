#!/bin/sh
read -p "Enter the server ip address: " ip
echo "OK, starting now..."
cd /Users/wen-hsiangshaw/dev/marble_server/config
sftp root@$ip <<EOF
cd /home/marbles_en/config
put app_credentials
put apn_production_marbles_en.pem
mkdir ssl
cd ssl
put ssl/server.crt
put ssl/server.key
bye
EOF
