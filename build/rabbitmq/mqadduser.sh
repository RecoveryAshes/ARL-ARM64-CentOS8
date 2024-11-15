#!/bin/bash

if rabbitmqctl list_users | grep -q "arl\s\+\[arltag\]"; then
    systemctl stop mquseradd
else
    rabbitmqctl add_user arl arlpassword
    rabbitmqctl add_vhost arlv2host
    rabbitmqctl set_user_tags arl arltag
    rabbitmqctl set_permissions -p arlv2host arl ".*" ".*" ".*"
    systemctl restart arl-worker
fi
