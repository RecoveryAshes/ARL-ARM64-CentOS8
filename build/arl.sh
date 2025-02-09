set -e

echo "update aliyun repos"
rm -rf /etc/yum.repos.d/*
cp /opt/ARL-ARM64-CentOS8/centos8repos/* /etc/yum.repos.d/
setenforce 0
echo "cd /opt/"
cd /opt/

# tee /etc/resolv.conf <<"EOF"
# nameserver 180.76.76.76
# nameserver 223.5.5.5
# nameserver 1.1.1.1
# EOF

tee /etc/yum.repos.d/mongodb-org-8.0.repo <<"EOF"
[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/8.0/aarch64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-8.0.asc
EOF

echo "install dependencies ..."
yum clean all
yum makecache
yum update -y
yum install epel-release -y

#过代理
yum install mongodb-org-server mongodb-mongosh -y --nogpgcheck

yum install systemd -y
yum install python36 git nginx wqy-microhei-fonts unzip wget -y
yum install fontconfig -y
yum install gcc-c++ -y
yum install python36-devel -y
yum groupinstall "Development Tools" -y

cd /opt/ARL-ARM64-CentOS8/build/rabbitmq
#wget https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh
bash script.rpm.sh
#wget https://github.com/rabbitmq/erlang-rpm/releases/download/v26.2.5.5/erlang-26.2.5.5-1.el8.aarch64.rpm
# rpm -Uvh erlang-26.2.5.5-1.el8.aarch64.rpm
# yum install socat logrotate -y
# yum install -y rabbitmq-server
rpm -Uvh erlang-26.2.5.5-1.el8.aarch64.rpm && yum install socat logrotate -y && yum install -y rabbitmq-server


if [ ! -f /usr/bin/python3.6 ]; then
  echo "link python3.6"
  ln -s /usr/bin/python36 /usr/bin/python3.6
fi

if [ ! -f /usr/local/bin/pip3.6 ]; then
  echo "link  pip3.6"
  ln -s /usr/bin/pip3.6 /usr/local/bin/pip3.6
  # python3.6 -m ensurepip --default-pip
  python3.6 -m pip install --upgrade pip
  # pip3.6 config --global set global.index-url https://mirrors.adysec.com/language/pypi
  pip3.6 --version
fi

if ! command -v nmap &>/dev/null; then
  echo "install nmap ..."
  yum install nmap -y
fi

if ! command -v nuclei &>/dev/null; then
  echo "install nuclei"
  cd /opt/ARL-ARM64-CentOS8/build/nuclei
  cp nuclei /usr/bin/
  chmod +x /usr/bin/nuclei
  nuclei -ut
fi

if ! command -v wih &>/dev/null; then
  echo "install wih ..."
  ## 安装 WIH
  cd /opt/ARL-ARM64-CentOS8/build/wih
  cp wih_linux_arm64 /usr/bin/wih
  chmod +x /usr/bin/wih
  wih --version
fi

cp /opt/ARL-ARM64-CentOS8/build/rabbitmq/advanced.config /etc/rabbitmq/

echo "start services ..."
systemctl enable mongod
systemctl restart mongod
systemctl enable rabbitmq-server
systemctl restart rabbitmq-server

cd /opt
if [ ! -d ARL ]; then
  echo "git clone ARL proj"
  cp -r /opt/ARL-ARM64-CentOS8/ARL /opt/ARL
fi

if [ ! -d "ARL-NPoC" ]; then
  echo "cp  ARL-NPoC proj"
  cp -r /opt/ARL-ARM64-CentOS8/ARL-NPoC /opt/ARL-NPoC
fi

yum install libxml2-devel libxslt-devel -y
cd /opt/ARL-NPoC

echo "install poc requirements ..."
pip3.6 install -r requirements.txt
pip3.6 install -e .
cd ../

if [ ! -f /usr/local/bin/ncrack ]; then
  echo "Download ncrack ..."
  cd /opt/ARL-ARM64-CentOS8/build
  yum localinstall ncrack-0.7-8.el8.aarch64.rpm -y
  ncrack --version
fi

mkdir -p /data/GeoLite2
if [ ! -f /data/GeoLite2/GeoLite2-ASN.mmdb ]; then
  echo "download GeoLite2-ASN.mmdb ..."
  cd /opt/ARL-ARM64-CentOS8/build
  cp GeoLite2-ASN.mmdb /data/GeoLite2
fi

if [ ! -f /data/GeoLite2/GeoLite2-City.mmdb ]; then
  echo "download GeoLite2-City.mmdb ..."
  cd /opt/ARL-ARM64-CentOS8/build
  cp GeoLite2-City.mmdb /data/GeoLite2
fi

cd /opt/ARL
if [ ! -f rabbitmq_user ]; then
  echo "add rabbitmq user"
  rabbitmqctl add_user arl arlpassword
  rabbitmqctl add_vhost arlv2host
  rabbitmqctl set_user_tags arl arltag
  rabbitmqctl set_permissions -p arlv2host arl ".*" ".*" ".*"
  echo "init arl user"
  echo "db.user.drop()" >/opt/ARL/docker/mongo-init.js
  echo "db.user.insert({ username: 'admin',  password: 'fe0a9aeac7e5c03922067b40db984f0e' })" >>/opt/ARL/docker/mongo-init.js
  mongosh 127.0.0.1:27017/arl /opt/ARL/docker/mongo-init.js
  touch rabbitmq_user
fi

cd /opt/ARL
echo "install arl requirements ..."
pip3.6 install -r requirements.txt
if [ ! -f app/config.yaml ]; then
  echo "create config.yaml"
  cp app/config.yaml.example app/config.yaml
fi

if [ ! -f /usr/bin/phantomjs ]; then
  echo "install phantomjs"
  cd /opt/ARL-ARM64-CentOS8/build/phantomjs-install
  bash install.sh
  ln -s /opt/ARL-ARM64-CentOS8/ARL/app/tools/phantomjs /usr/bin/phantomjs
fi
cd /opt/ARL
if [ ! -f /etc/nginx/conf.d/arl.conf ]; then
  echo "copy arl.conf"
  cp misc/arl.conf /etc/nginx/conf.d
fi

if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
  echo "download dhparam.pem"
  #curl https://ssl-config.mozilla.org/ffdhe2048.txt > /etc/ssl/certs/dhparam.pem
  cd /opt/ARL-ARM64-CentOS8/build/ssl
  cat ffdhe2048.txt >/etc/ssl/certs/dhparam.pem
fi

cd /opt/ARL
echo "gen cert ..."
chmod +x docker/worker/gen_crt.sh
./docker/worker/gen_crt.sh

cp /opt/ARL-ARM64-CentOS8/build/rabbitmq/mquseradd.service /etc/systemd/system/
chmod +x /opt/ARL-ARM64-CentOS8/build/rabbitmq/mqadduser.sh
systemctl enable mquseradd.service
systemctl start mquseradd.service

cd /opt/ARL
if [ ! -f /etc/systemd/system/arl-web.service ]; then
  echo "copy arl-web.service"
  cp misc/arl-web.service /etc/systemd/system/
fi

if [ ! -f /etc/systemd/system/arl-worker.service ]; then
  echo "copy arl-worker.service"
  cp misc/arl-worker.service /etc/systemd/system/
fi

if [ ! -f /etc/systemd/system/arl-worker-github.service ]; then
  echo "copy arl-worker-github.service"
  cp misc/arl-worker-github.service /etc/systemd/system/
fi

if [ ! -f /etc/systemd/system/arl-scheduler.service ]; then
  echo "copy arl-scheduler.service"
  cp misc/arl-scheduler.service /etc/systemd/system/
fi

chmod +x /opt/ARL/app/tools/*
cp /opt/ARL-ARM64-CentOS8/build/dns/adddns.service /etc/systemd/system/
chmod +x /opt/ARL-ARM64-CentOS8/build/dns/adddns.sh
systemctl enable adddns.service
systemctl start adddns.service

echo "start arl services ..."

systemctl enable arl-web
systemctl enable arl-worker
systemctl enable arl-worker-github
systemctl enable arl-scheduler
systemctl enable nginx
systemctl restart arl-web
systemctl restart arl-worker
systemctl restart arl-scheduler
systemctl restart arl-worker-github
systemctl restart nginx


echo "----------------------------------------------"
echo "install done"
echo "默认端口0.0.0.0:5003"
echo "默认账号:admin"
echo "默认密码:arlpass"
