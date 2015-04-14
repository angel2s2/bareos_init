#!/bin/bash

BAREOS_DIR="/etc/bareos"                          # Основной каталог
BACULA_DIR="/etc/bacula"
NOW="$(date +%Y%m%d%H%M%S)"
DATABASE="mysql"
PROXY='HTTP_PROXY=""'

### Создание бэкапа, если каталог bacula уже есть
if [ -d "${BACULA_DIR}" ] ; then
  mv "${BACULA_DIR}" "${BACULA_DIR}.bak_${NOW}"
fi

# удаляем клиента бакулы
service bacula-fd stop
apt-get purge bacula-fd bacula-common bacula-client

# какой у нас дистрибутив?
RELEASE="$(lsb_release --release | awk '{print $2}' | awk -F'.' '{print $1}')"
case "$RELEASE" in
  "7"   ) DIST="Debian_7.0" ;;
  "6"   ) DIST="Debian_6.0" ;;
#  ""    ) DIST="xUbuntu_14.04" ;;
#  ""    ) DIST="xUbuntu_12.04" ;;
#  ""    ) DIST="xUbuntu_10.04" ;;
#  ""    ) DIST="xUbuntu_8.04" ;;
  *         ) echo "I not know your distr..." && exit 1 ;;
esac

# репозиторий
URL=http://download.bareos.org/bareos/release/latest/$DIST/ 

# настройка репозитория
echo "deb $URL /" > /etc/apt/sources.list.d/bareos.list
export PROXY
wget -qO- $URL/Release.key | apt-key add - 
 
# install Bareos packages 
apt-get update 
apt-get install bareos-filedaemon 
