# ARL-ARM64-CentOS8
```
docker run --privileged --cpus="6.0" --memory="8g" -it -d -p 5003:5003 --name=arl --restart=always  docker.adysec.com/library/centos /usr/sbin/init 
```
arm64架构的centos8灯塔，可用于mac电脑本地搭建
源码编译文件在 **build/arl.sh**
还是编写一键化脚本中，目前工具以成功全部转sarm64架构，除了截图，自己这以成功运行。建议一行一行手动运行，连不通的情况下挂一下代理

