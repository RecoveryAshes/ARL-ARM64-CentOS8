tee /etc/resolv.conf <<"EOF"
nameserver 192.168.65.7
nameserver 119.29.29.29
nameserver 223.5.5.5
nameserver 223.6.6.6
nameserver 114.114.114.114
nameserver 114.114.115.115
nameserver 8.8.8.8
nameserver 1.2.4.8
nameserver 210.2.4.8
nameserver 1.1.1.1
EOF

systemctl stop adddns.service