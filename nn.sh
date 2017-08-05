#!/bin/bash

# 修正 Coding 的 DNS 错误
echo nameserver 114.114.114.114 | sudo tee /etc/resolv.conf

# 修正 Coding 的 Ubuntu 源错误
#echo 'deb http://au.archive.ubuntu.com/ubuntu/ wily main restricted' | sudo tee /etc/apt/sources.list
#echo 'deb http://au.archive.ubuntu.com/ubuntu/ wily-updates main restricted' | sudo tee -a /etc/apt/sources.list
#sudo apt-get update
#sudo apt-get install --only-upgrade apt -y
#cat << _EOF_ | sudo tee /etc/apt/sources.list
#deb http://mirrors.163.com/ubuntu/ wily main restricted universe multiverse
#deb http://mirrors.163.com/ubuntu/ wily-security main restricted universe multiverse
#deb http://mirrors.163.com/ubuntu/ wily-updates main restricted universe multiverse
#deb http://mirrors.163.com/ubuntu/ wily-proposed main restricted universe multiverse
#deb http://mirrors.163.com/ubuntu/ wily-backports main restricted universe multiverse
#deb-src http://mirrors.163.com/ubuntu/ wily main restricted universe multiverse
#deb-src http://mirrors.163.com/ubuntu/ wily-security main restricted universe multiverse
#deb-src http://mirrors.163.com/ubuntu/ wily-updates main restricted universe multiverse
#deb-src http://mirrors.163.com/ubuntu/ wily-proposed main restricted universe multiverse
#deb-src http://mirrors.163.com/ubuntu/ wily-backports main restricted universe multiverse
#_EOF_
sudo apt-get update

# 安装依赖
sudo apt-get install docker.io wget fortune cowsay -y 

wget -O cf.deb 'https://coding.net/u/tprss/p/bluemix-source/git/raw/master/cf-cli-installer_6.16.0_x86-64.deb' 
sudo dpkg -i cf.deb 

cf install-plugin -f https://coding.net/u/tprss/p/bluemix-source/git/raw/master/ibm-containers-linux_x64

wget 'https://coding.net/u/tprss/p/bluemix-source/git/raw/master/Bluemix_CLI_0.4.3_amd64.tar.gz'
tar -zxf Bluemix_CLI_0.4.3_amd64.tar.gz
cd Bluemix_CLI
sudo ./install_bluemix_cli
cd ..

# 初始化环境
org=$(openssl rand -base64 8 | md5sum | head -c8)
cf login -a https://api.eu-gb.bluemix.net
bx iam org-create $org
sleep 3
cf target -o $org
bx iam space-create dev
sleep 3
cf target -s dev
cf ic namespace set $(openssl rand -base64 8 | md5sum | head -c8)
sleep 3
cf ic init

# 生成密码
# passwd=$(openssl rand -base64 8 | md5sum | head -c12)

# 创建镜像
mkdir ss
cd ss

cat << _EOF2_ >config.json
{
    "server":"0.0.0.0",
    "server_port":443,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"Kh#p*378V",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}
_EOF2_

cat << _EOF_ >Dockerfile
FROM alpine:latest
RUN set -ex && apk add --no-cache libsodium py2-pip && pip --no-cache-dir install https://github.com/shadowsocks/shadowsocks/archive/master.zip
ADD config.json /config.json
EXPOSE 443
ENTRYPOINT ["ssserver", "-c", "/config.json"]
_EOF_

cf ic build -t ss:v1 . 

# 运行容器
cf ic ip bind $(cf ic ip request | cut -d \" -f 2 | tail -1) $(cf ic run -m 512 --name=ss -p 443 registry.ng.bluemix.net/`cf ic namespace get`/ss:v1 | head -1)
