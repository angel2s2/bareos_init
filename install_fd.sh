#!/bin/bash

BAREOS_DIR="/etc/bareos"                          # Основной каталог
BACULA_DIR="/etc/bacula"
NOW="$(date +%Y%m%d%H%M%S)"
PROXY='HTTP_PROXY=""'

### Создание бэкапа, если каталог bacula уже есть
if [ -d "${BACULA_DIR}" ] ; then
  mv "${BACULA_DIR}" "${BACULA_DIR}.bak_${NOW}"
fi

if [ ! -f /etc/issue ] ; then
  echo "I not know your distr..."
  exit 1
fi

DIST_NAME="$(head -1 /etc/issue | awk '{print $1}')"
DIST_RELEASE="$(head -1 /etc/issue | awk '{print $3}' | awk -F'.' '{print $1}')"

### debian 6,7 && xubuntu 12.04,14.04
___debian() {
  # delete bacula-fd
  service bacula-fd stop
  apt-get purge bacula-fd bacula-common bacula-client

  # add the Bareos repository 
  URL="http://download.bareos.org/bareos/release/latest/${DIST}/"
  echo "deb ${URL} /" > /etc/apt/sources.list.d/bareos.list
  export PROXY
  wget -qO- "${URL}/Release.key" | apt-key add - 
 
  # install Bareos packages 
  apt-get update 
  apt-get install bareos-filedaemon 
}

### centos 5,6,7 && redhat 5,6,7 && redora 20
___centos() {
  # delete bacula-fd
  service bacula-fd stop
  yum remove bacula-client bacula-common

  # add the Bareos repository 
  URL="http://download.bareos.org/bareos/release/latest/${DIST}"
  export PROXY
  wget -qO "/etc/yum.repos.d/bareos.repo" "${URL}/bareos.repo"
 
  # install Bareos packages 
  yum install bareos-filedaemon
}

# >>>>> NOT TESTED <<<<< #
### opensuse 11 sp3, 12, 13.1
#___opensuse() {
#  # delete bacula-fd
#  service bacula-fd stop
#  zipper ...
#
#  # add the Bareos repository 
#  URL="http://download.bareos.org/bareos/release/latest/${DIST}"
#  export PROXY
#  zypper addrepo --refresh "${URL}/bareos.repo"
# 
#  # install Bareos packages 
#  zypper install bareos-filedaemon
#}

# какой у нас дистрибутив?
case "${DIST_NAME}" in
  "Debian"    ) DIST="${DIST_NAME}_${DIST_RELEASE}.0" && ___debian ;;                # tested only debian 7
  #"xUbuntu"   ) DIST="${DIST_NAME}_${DIST_RELEASE}.04" && ___debian ;;              # NOT TESTED
  "CentOS"    ) DIST="${DIST_NAME}_${DIST_RELEASE}" && ___centos ;;                  # tested only centos 6
  #"RHEL"      ) DIST="${DIST_NAME}_${DIST_RELEASE}" && ___centos ;;                 # NOT TESTED
  #"Fedora"    ) DIST="${DIST_NAME}_${DIST_RELEASE}" && ___centos ;;                 # NOT TESTED
  #"SLE"       )  && ___opensuse ;;                                                  # NOT TESTED
  *           ) echo "I not know your distr..." && exit 1 ;;
esac



