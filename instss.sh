#!/bin/bash

passwd=$1
port=$2

if [ $# -ne 2 ];then
    echo "[Usage] $0 password port"
    echo "e.g.:"
    echo "    $0 yourpasswd 443"
    exit
fi

yum -y install git
systemctl stop firewalld
chkconfig firewalld off
cd /root && git clone https://github.com/shadowsocks/shadowsocks.git -b master
echo "python /root/shadowsocks/shadowsocks/server.py -m aes-256-cfb -p $port -k $passwd" >> /etc/rc.local
chmod +x /etc/rc.local
/etc/rc.local
