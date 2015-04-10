#!/bin/bash

grep -i --no-filename 'FD Address' /etc/bareos/bareos-fd.conf.d.gen/*.conf | grep -Ev '10\.1\.1\.161|FDAddresses|127\.0\.0\.1' | awk -F'=' '{print $2}' | while read ADR ; do nc -znvvw 3 $ADR 9102 ; done

