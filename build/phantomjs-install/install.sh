#安装依赖
yum install gcc gcc-c++ make flex bison ruby openssl-devel freetype-devel fontconfig-devel libicu-devel sqlite-devel libpng-devel libjpeg-devel -y

#安装 ssl 库
cp -rp ssl /usr/local/
echo "/usr/local/ssl/lib" >>/etc/ld.so.conf
ldconfig -v

#安装 phantomjs
cp -rp phantomjs /usr/local/bin
chmod a+x /usr/local/bin/phantomjs

echo "Phantomjs installed."
