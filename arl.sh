set -e
echo "cd /opt/"
mkdir -p /opt/
cd /opt/



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
yum update --nobest -y
yum install epel-release -y
yum install  mongodb-org-server  mongodb-mongosh -y
yum install systemd -y
yum install python36  git nginx  wqy-microhei-fonts unzip wget -y
yum install fontconfig -y
yum install gcc-c++ -y 
yum install python36-devel -y 
yum groupinstall "Development Tools" -y

wget https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh
bash script.rpm.sh
wget https://github.com/rabbitmq/erlang-rpm/releases/download/v26.2.5.5/erlang-26.2.5.5-1.el8.aarch64.rpm
rpm -Uvh erlang-26.2.5.5-1.el8.aarch64.rpm
yum install socat logrotate -y
yum install -y rabbitmq-server


if [ ! -f /usr/bin/python3.6 ]; then
  echo "link python3.6"
  ln -s /usr/bin/python36 /usr/bin/python3.6
fi

if [ ! -f /usr/local/bin/pip3.6 ]; then
  echo "link  pip3.6"
  ln -s /usr/bin/pip3.6  /usr/local/bin/pip3.6
  # python3.6 -m ensurepip --default-pip
  python3.6 -m pip install --upgrade pip
  # pip3.6 config --global set global.index-url https://mirrors.adysec.com/language/pypi
  pip3.6 --version
fi


if ! command -v nmap &> /dev/null
then
    echo "install nmap ..."
    yum install nmap -y
fi

if ! command -v nuclei &> /dev/null
then
  echo "install nuclei"
  wget https://github.com/adysec/ARL/raw/master/tools/nuclei.zip 
  unzip nuclei.zip && mv nuclei /usr/bin/ && rm -f nuclei.zip
  nuclei -ut
fi



if ! command -v wih &> /dev/null
then
  echo "install wih ..."
  ## 安装 WIH
  git clone https://github.com/Aabyss-Team/arl_files.git
  mv /opt/arl_files/wih/wih_linux_arm64 /usr/bin/wih
  chmod +x /usr/bin/wih
  wih --version
fi

echo "start services ..."
systemctl enable mongod
systemctl restart mongod
systemctl enable rabbitmq-server
systemctl restart rabbitmq-server

cd /opt
if [ ! -d ARL ]; then
  echo "git clone ARL proj"
  git clone https://github.com/adysec/ARL.git
fi

if [ ! -d "ARL-NPoC" ]; then
  echo "mv ARL-NPoC proj"
  mv ARL/tools/ARL-NPoC ARL-NPoC
fi

cd /opt/ARL-NPoC
echo "install poc requirements ..."
pip3.6 install -r requirements.txt
pip3.6 install -e .
cd ../

if [ ! -f /usr/local/bin/ncrack ]; then
  echo "Download ncrack ..."
  wget https://dl.fedoraproject.org/pub/epel/8/Everything/aarch64/Packages/n/ncrack-0.7-8.el8.aarch64.rpm
  yum localinstall ncrack-0.7-8.el8.aarch64.rpm  -y
fi

mkdir -p /data/GeoLite2
if [ ! -f /data/GeoLite2/GeoLite2-ASN.mmdb ]; then
  echo "download GeoLite2-ASN.mmdb ..."
  wget -c https://github.com/adysec/ARL/raw/master/tools/GeoLite2-ASN.mmdb -O /data/GeoLite2/GeoLite2-ASN.mmdb
fi

if [ ! -f /data/GeoLite2/GeoLite2-City.mmdb ]; then
  echo "download GeoLite2-City.mmdb ..."
  wget -c https://github.com/adysec/ARL/raw/master/tools/GeoLite2-City.mmdb -O /data/GeoLite2/GeoLite2-City.mmdb
fi

cd /opt/ARL
if [ ! -f rabbitmq_user ]; then
  echo "add rabbitmq user"
  rabbitmqctl add_user arl arlpassword
  rabbitmqctl add_vhost arlv2host
  rabbitmqctl set_user_tags arl arltag
  rabbitmqctl set_permissions -p arlv2host arl ".*" ".*" ".*"
  echo "init arl user"
  echo "db.user.drop()" > docker/mongo-init.js 
  echo "db.user.insert({ username: 'admin',  password: 'fe0a9aeac7e5c03922067b40db984f0e' })" >> docker/mongo-init.js 
  mongosh 127.0.0.1:27017/arl docker/mongo-init.js
  touch rabbitmq_user
fi

echo "install arl requirements ..."
pip3.6 install -r requirements.txt
if [ ! -f app/config.yaml ]; then
  echo "create config.yaml"
  cp app/config.yaml.example  app/config.yaml
fi

if [ ! -f /usr/bin/phantomjs ]; then
  echo "install phantomjs"
  ln -s `pwd`/app/tools/phantomjs  /usr/bin/phantomjs
fi

if [ ! -f /etc/nginx/conf.d/arl.conf ]; then
  echo "copy arl.conf"
  cp misc/arl.conf /etc/nginx/conf.d
fi

if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
  echo "download dhparam.pem"
  curl https://ssl-config.mozilla.org/ffdhe2048.txt > /etc/ssl/certs/dhparam.pem
fi



echo "gen cert ..."
chmod +x docker/worker/gen_crt.sh
./docker/worker/gen_crt.sh


cd /opt/ARL/


if [ ! -f /etc/systemd/system/arl-web.service ]; then
  echo  "copy arl-web.service"
  cp misc/arl-web.service /etc/systemd/system/
fi

if [ ! -f /etc/systemd/system/arl-worker.service ]; then
  echo  "copy arl-worker.service"
  cp misc/arl-worker.service /etc/systemd/system/
fi


if [ ! -f /etc/systemd/system/arl-worker-github.service ]; then
  echo  "copy arl-worker-github.service"
  cp misc/arl-worker-github.service /etc/systemd/system/
fi

if [ ! -f /etc/systemd/system/arl-scheduler.service ]; then
  echo  "copy arl-scheduler.service"
  cp misc/arl-scheduler.service /etc/systemd/system/
fi

chmod +x /opt/ARL/app/tools/*

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

echo "install done"
echo "默认端口0.0.0.0:5003"
echo "默认账号:admin"
echo "默认密码:arlpass"