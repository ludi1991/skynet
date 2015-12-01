#!/bin/sh

ip="127.0.0.1"
port="8000"
robot="100"


( sleep 1
echo "addrobot $robot") | telnet $ip $port 

