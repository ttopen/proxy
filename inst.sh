#!/bin/bash

domain=$1
path=$2
passwd=$3

if [ $# -ne 3 ];then
    echo "[Usage] $0 domain path UUID"
    echo "e.g.:"
    echo "    $0 yourdomain.com yourpath c97881e0-2816-5e82-2041-262a08ddf0ed"
    exit
fi

function close_firewall(){
systemctl stop firewalld
chkconfig firewalld off
}

function download_v2ray(){
    cd /tmp
    mkdir -p /tmp/v2ray
    wget https://git.io/JelP1 -O v2ray.tgz
    mv v2ray.tgz /tmp/v2ray/v2ray.tgz

    cd /tmp/v2ray
    tar zxf v2ray.tgz
}

function install_v2ray(){
    cd /tmp/v2ray
    mkdir /usr/bin/v2ray/
    cp -f v2ray /usr/bin/v2ray/v2ray
    chmod +x /usr/bin/v2ray/v2ray
    cp -f v2ctl /usr/bin/v2ray/v2ctl
    chmod +x /usr/bin/v2ray/v2ctl
}

function config_v2ray(){
    cd /tmp/v2ray
    sed -i "s/TT_PATH/$path/g" config.json
    sed -i "s/TT_PASSWD/$passwd/g" config.json
    mkdir -p /etc/v2ray/ 
    cp -f config.json /etc/v2ray/config.json
    cp -f v2ray.service /etc/systemd/system/v2ray.service
}

function check_domain(){
    yum install -y bind-utils &>/dev/null
    while [ true ]
    do 
        domain_ip=$(dig +short $domain)
        host_ip=$(hostname -I|awk '{print$1}')
        if [ "$domain_ip" = "$host_ip" ];then
            break
        fi
        sleep 5
        echo "    domain $domain not point to ip $host_ip"
    done
}

function install_certbot(){
    yum install -y certbot
    certbot certonly --standalone -d $domain --non-interactive --agree-tos -m webmaster@$domain
}

function install_nginx(){
    cd /tmp/v2ray
    yum install -y nginx
    sed -i "s/TT_DOMAIN/$domain/g" nginx.conf
    sed -i "s/TT_PATH/$path/g" nginx.conf
    rm -f /etc/nginx/nginx.conf
    cp -f nginx.conf /etc/nginx/nginx.conf
}

function install_service(){
    chkconfig v2ray on
    chkconfig nginx on
    service v2ray start
    service nginx start
}

function set_cron(){
    cd /tmp/v2ray
    crontab -l > mycron
    echo "1 1 1 * * /usr/bin/certbot renew --post-hook 'service nginx reload' &>/dev/null" >> mycron
    crontab -r
    crontab mycron
    rm mycron
}

function clean(){
    rm -rf $0 inst.sh /tmp/inst.sh /tmp/v2ray
}

clean
echo "Start"

echo "1. Check domain ..."
check_domain
close_firewall &>/dev/null

echo "2. Download v2ray ..."
download_v2ray &> /dev/null

echo "3. Install v2ray ..."
install_v2ray &> /dev/null

echo "4. Config v2ray ..."
config_v2ray &> /dev/null

echo "5. Config https ..."
install_certbot &> /dev/null
set_cron

echo "6. Install nginx ..."
install_nginx &> /dev/null

echo "7. Enable service ..."
install_service &> /dev/null

echo "8. Clean environment ..."
clean

echo "Stop."