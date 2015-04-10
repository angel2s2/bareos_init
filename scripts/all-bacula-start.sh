#!/bin/bash

service bareos-dir start
sleep 1s
service bareos-sd start
sleep 1s
service bareos-fd start
sleep 3s
pgrep -fl bareos

