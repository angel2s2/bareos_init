#!/bin/bash

service bareos-fd stop
sleep 1s
service bareos-sd stop
sleep 1s
service bareos-dir stop
sleep 5s
pkill bareos-fd
sleep 1s
pkill bareos-sd
sleep 3s
pgrep -fl bareos

