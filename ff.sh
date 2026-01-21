#!/bin/bash

echo "Enter the IP to which the server will connect :"
read ip

apt update -y ; apt install nginx nginx-full openssl e2fsprogs -y --allow-unauthenticated; unlink /etc/nginx/sites-enabled/default
cd /etc/ssl/ && openssl req -new -x509 -days 1365 -sha1 -newkey rsa:2048 -nodes -keyout server.key -out server.crt -subj '/O=Company/OU=Department/CN=www.example.com'

#PROXY CONFİG FİLE
read -r -d '' ProxyCF << EOM
server {
        listen 80 default;

        server_name _;
        location / {
                access_log off;
                proxy_pass          https://$ip/;
                proxy_set_header    Host             \$http_host;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

                proxy_set_header X-Real-IP \$remote_addr;
                proxy_pass_header Set-Cookie;
                proxy_set_header X-Forwarded-Host \$host;
                proxy_set_header X-Forwarded-Server \$host;
        }
}
server {
        listen 443 default;
        ssl on;
        ssl_certificate /etc/ssl/server.crt;
        ssl_certificate_key /etc/ssl/server.key;

        server_name _;
        location / {
                access_log off;
                proxy_pass          https://$ip/;
                proxy_set_header    Host             \$http_host;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

                proxy_set_header X-Real-IP \$remote_addr;
                proxy_pass_header Set-Cookie;
                proxy_set_header X-Forwarded-Host \$host;
                proxy_set_header X-Forwarded-Server \$host;
        }
}
EOM

echo "$ProxyCF" > /etc/nginx/sites-available/reverse-proxy.conf

ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
sleep 1

sed -i -r 's/access_log.*/access_log off;/' /etc/nginx/nginx.conf
sed -i -r 's/error_log.*/error_log off;/' /etc/nginx/nginx.conf

ufw allow https
ufw allow 443

service nginx restart

# anon block
sed -i -r 's/auth,authpriv.\*/#auth,authpriv.\*/' /etc/rsyslog.conf ;
service rsyslog restart ;
set +o history; history -c ; echo "set +o history" >> ~/.bashrc ; rm ~/.bash_history ;
rm /var/log/wtmp;

nginx -t
nginx -s reload
sleep 0.1
systemctl nginx restart

echo FF is READY !