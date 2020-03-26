#!/bin/bash

yum -y install git
systemctl stop firewalld
chkconfig firewalld off
cd /root && git clone https://github.com/shadowsocks/shadowsocks.git -b master
echo "python /root/shadowsocks/shadowsocks/server.py -m aes-256-cfb -p 443 -k $1" >> /etc/rc.local
chmod +x /etc/rc.local
/etc/rc.local
