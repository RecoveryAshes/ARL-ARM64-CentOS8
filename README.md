# ARL-ARM64-CentOS8

arm64架构的centos8灯塔，可用于mac电脑本地搭建，本地已通过测试
## 源码安装
源码编译文件在 **build/arl.sh**
可国内一键安装

注意需要git到/opt下
```
cd /opt
git clone https://github.com/RecoveryAshes/ARL-ARM64-CentOS8.git
./ARL-ARM64-CentOS8/build/arl.sh 
```

## docker（可能需要国外）
```
docker pull finalhades/arl_arm64:latest
#docker cpus几核，memory内存
docker run --privileged --cpus="6.0" --memory="8g" -it -d -p 5003:5003 --name=arl --restart=always  finalhades/arl_arm64 /usr/sbin/init 
```



