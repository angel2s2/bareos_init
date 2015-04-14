#!/bin/bash

LICENSE='GPLv3'
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; version 2 of the License.
#       
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#       
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.
# 
SCRIPT_NAME='initialize_bareos_configs.sh'
VERSION='0.2015.04.10'            # VER.YEAR.MONTH.DAY
DESCRIPTION="${SCRIPT_NAME} - script for bareos"
AUTHOR='Roman (Angel2S2) Shagrov'
EMAIL='bareos_init.mail@angel2s2.ru'   # для ошибок, замечаний и предложений
BLOG='http://blog.angel2s2.ru/'
HOMEPAGE='https://github.com/angel2s2/bareos_init'

# Защита от случайного запуска
  cat << EOF_MESSAGE

### RUSSIAN ###
Данный скрипт создает первичные конфиги для bareos и настраивает директивы в них, в частности пароли и имена ресурсов.
Перед использованием скрипта нужно установить mariadb/mysql, bareos и (не обязательно) bareos-webui. А так же прописать значения в переменные в этом скрипте.
Подробнее про этот сприпт и его работу можно узнать в моем блоге: http://blog.angel2s2.ru/2016/04/bareos-init.html
или на github'е: ${HOMEPAGE}

### ENGLISH ###
This script creates primary configs for Bareos and configures directives for them, passwords and resource names particulary.
Install mariadb/mysql, bareos and bareos-webui (not necessary) before using the script. Also set variable values in that script.
You can read more about this script and it's work in my blog: http://blog.angel2s2.ru/2016/04/bareos-init.html
or at github: ${HOMEPAGE}

EOF_MESSAGE
read -r -p "Continue? [y/N] " READ_RESULT
if [ "${READ_RESULT}" != "y" -a "${READ_RESULT}" != "Y" -a "${READ_RESULT}" != "yes" -a "${READ_RESULT}" != "YES" ] ; then
  echo "Exiting..."
  exit 1
fi


### >>> Переменные :: можно редактировать {
XXX_ROOT_DB_PASSWORD_XXX=''              # пароль root'а БД (нужен для настройки БД для bareos_webui)
XXX_MAIL_SERVER_XXX=''               # адрес почтового сервера, с которого будем слать email'ы
XXX_BAREOS_EMAIL_XXX=''            # имя отправителя
XXX_ADMIN_EMAIL_XXX=''            # куда слать уведомления

XXX_PATH_TO_XXX='\/mnt\/backups\/bareos_server'  # куда бэкапить данные с bareos server, слэши обязательно экранировать (\/path\/to)
ETH_N='eth0'                                     # на каком интефейсе слушать (нужно для этого скрипта, чтобы правильно определить IP)

### Задаются в ресурсе Catalog{} в bareos-dir.conf
XXX_CATALOG_DBNAME_XXX=''
XXX_CATALOG_DBUSER_XXX=''
XXX_CATALOG_DBPASSWORD_XXX=''         # скриптом автоматически НЕ генерируется!!!

### Настройки веб-интерфейса, задаются в /etc/bareos-webui/directors.ini (см. $BAREOS_WEBUI)
### Как настроить БД можно прочитать в документации https://github.com/bareos/bareos-webui/blob/master/doc/INSTALL.md
### или в моем блоге 
XXX_WEBUI_DBNAME_XXX="${XXX_CATALOG_DBNAME_XXX}"
XXX_WEBUI_DBUSER_XXX=''
XXX_WEBUI_DBPASSWORD_XXX=''             # скриптом автоматически НЕ генерируется!!!

### Фактически, это login для входа в веб-интерфейс
XXX_CONSOLE_WEBUI_NAME_XXX='badmin'

### Этот пароль будет использоваться для входа в веб-интерфейс
XXX_CONSOLE_WEBUI_PASS_XXX=''

# ---> Если эти переменные оставить пустыми или не определять (закомментировать), то они будут сгенерированы автоматически {
XXX_DIRECTOR_PASS_XXX=''
XXX_CLIENT_PASS_XXX=''
XXX_STORAGE_PASS_XXX=''
XXX_CONSOLE_PASS_XXX=''
XXX_DIRECTOR_MONITOR_PASS_XXX=''
XXX_CLIENT_MONITOR_PASS_XXX=''
XXX_STORAGE_MONITOR_PASS_XXX=''
XXX_CONSOLE_MONITORING_PASS_XXX=''

# ---> Если не задано, в качестве адреса будет использован IP адрес присвоенные интерфейсу указанному в переменной $ETH_N
#XXX_DIRECTOR_ADDRESS_XXX='10.1.1.161'
#XXX_CLIENT_ADDRESS_XXX='10.1.1.161'
#XXX_STORAGE_DAEMON_ADDRESS_XXX='10.1.1.161'

# ---> Например, если IP адрес = 10.1.1.161, то эти переменные (которые приведены ниже) будут иметь вид
# ---> director_bareos_161, storage_daemon_bareos_161 и т.д.
#XXX_DIRECTOR_NAME_XXX='director_bareos_161'
#XXX_STORAGE_DAEMON_NAME_XXX='storage_daemon_bareos_161'
#XXX_FILE_DAEMON_NAME_XXX='file_daemon_bareos_161'
#XXX_CLIENT_NAME_XXX='client_bareos_server_161'
#XXX_CONSOLE_ADMIN_NAME_XXX='console_admin_bareos_161'
#XXX_CONSOLE_MONITORING_NAME_XXX='console_monitoring_bareos_161'
# <--- }

BAREOS_DIR="/etc/bareos"                          # Основной каталог
BAREOS_WEBUI="/etc/bareos-webui/directors.ini"    # Конфиг веб-интерфейса
### <<< Переменные }

### >>> Изменять только в случае, если четко понимаешь, что делаешь {
BAREOS_SCRIPTS_DIR="${BAREOS_DIR}/scripts"
BAREOS_TEMPLATES_DIR="${BAREOS_DIR}/templates"
BAREOS_HELPERS_DIR="${BAREOS_DIR}/helpers"
BAREOS_BACKUP_SCRIPTS_DIR="${BAREOS_DIR}/backup_scripts"
BAREOS_INC_D_DIR="${BAREOS_DIR}/inc.d"
BAREOS_DIR_CONF_D_DIR="${BAREOS_DIR}/bareos-dir.conf.d"
BAREOS_FD_CONF_D_GEN_DIR="${BAREOS_DIR}/bareos-fd.conf.d.gen"
BAREOS_SD_CONF_D_DIR="${BAREOS_DIR}/bareos-sd.conf.d"
NOW="$(date +%Y%m%d%H%M%S)"
THIS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"                          # Откуда запущен скрипт
### <<< }


### Наполненение конфигов данными
___set_config_data() {
  local CURRENT_FIND="$1"     # что искать в конфиге
  local CURRENT_DATA="$2"     # чем заполнять шаблон в конфиге
  find "${BAREOS_DIR}" -type f -exec sed -i "s/${CURRENT_FIND}/${CURRENT_DATA}/g" '{}' \;
}

### Получение последнего октета из IP адреса
___get_last_oktet() {
  echo "$1" | awk -F'.' '{print $4}'
}

### Генерирование пароля (-w 45 = длина)
___passwd_gen() {
  head /dev/urandom | tr -dc '0-9a-zA-Z_!@+=.,;:-' | fold -w 45 | head -n 1
}

### Создание бэкапа, если такой каталог уже есть
if [ -d "${BAREOS_DIR}" ] ; then
  mv "${BAREOS_DIR}" "${BAREOS_DIR}.bak_${NOW}"
  mkdir "${BAREOS_DIR}"
fi

### Наполнение основного каталога данными
cp -rf ${THIS_SCRIPT_DIR}/templates/* "${BAREOS_DIR}"
find "${BAREOS_DIR}" -type f -exec chmod 640 '{}' \;
find "${BAREOS_DIR}" -type d -exec chmod 755 '{}' \;

### >>> Проверка заполнения переменных и генерирование паролей {
if [ -z "${XXX_DIRECTOR_PASS_XXX}" ] ; then
  XXX_DIRECTOR_PASS_XXX="$(___passwd_gen)"
fi

if [ -z "${XXX_CLIENT_PASS_XXX}" ] ; then
  XXX_CLIENT_PASS_XXX="$(___passwd_gen)"
fi

if [ -z "${XXX_STORAGE_PASS_XXX}" ] ; then
  XXX_STORAGE_PASS_XXX="$(___passwd_gen)"
fi

if [ -z "${XXX_CONSOLE_PASS_XXX}" ] ; then
  XXX_CONSOLE_PASS_XXX="$(___passwd_gen)"
fi

if [ -z "${XXX_DIRECTOR_MONITOR_PASS_XXX}" ] ; then
  XXX_DIRECTOR_MONITOR_PASS_XXX="$(___passwd_gen)"
fi

if [ -z "${XXX_CLIENT_MONITOR_PASS_XXX}" ] ; then
  XXX_CLIENT_MONITOR_PASS_XXX="$(___passwd_gen)"
fi

if [ -z "${XXX_STORAGE_MONITOR_PASS_XXX}" ] ; then
  XXX_STORAGE_MONITOR_PASS_XXX="$(___passwd_gen)"
fi

if [ -z "${XXX_CONSOLE_MONITORING_PASS_XXX}" ] ; then
  XXX_CONSOLE_MONITORING_PASS_XXX="$(___passwd_gen)"
fi
### <<< }

### >>> Наполнение конфигов паролями {
___set_config_data "XXX_DIRECTOR_PASS_XXX"            "${XXX_DIRECTOR_PASS_XXX}"
___set_config_data "XXX_CLIENT_PASS_XXX"              "${XXX_CLIENT_PASS_XXX}"
___set_config_data "XXX_STORAGE_PASS_XXX"             "${XXX_STORAGE_PASS_XXX}"
___set_config_data "XXX_CONSOLE_PASS_XXX"             "${XXX_CONSOLE_PASS_XXX}"
___set_config_data "XXX_DIRECTOR_MONITOR_PASS_XXX"    "${XXX_DIRECTOR_MONITOR_PASS_XXX}"
___set_config_data "XXX_CLIENT_MONITOR_PASS_XXX"      "${XXX_CLIENT_MONITOR_PASS_XXX}"
___set_config_data "XXX_STORAGE_MONITOR_PASS_XXX"     "${XXX_STORAGE_MONITOR_PASS_XXX}"
___set_config_data "XXX_CONSOLE_MONITORING_PASS_XXX"  "${XXX_CONSOLE_MONITORING_PASS_XXX}"
___set_config_data "XXX_CONSOLE_WEBUI_PASS_XXX"       "${XXX_CONSOLE_WEBUI_PASS_XXX}"
___set_config_data "XXX_CATALOG_DBPASSWORD_XXX"       "${XXX_CATALOG_DBPASSWORD_XXX}"
### <<< }

### Текущий IP адрес, который закреплен за интерфейсом, указанном в $ETH_N
CURRENT_IP="$(ifconfig $ETH_N | awk '/inet addr:/ {print $2}' | awk -F':' '{print $2}')"

### >>> Проверка и установка переменных (адреса и имена) {
if [ -z "${XXX_DIRECTOR_ADDRESS_XXX}" ] ; then
  XXX_DIRECTOR_ADDRESS_XXX="${CURRENT_IP}"
fi

if [ -z "${XXX_STORAGE_DAEMON_ADDRESS_XXX}" ] ; then
  XXX_STORAGE_DAEMON_ADDRESS_XXX="${CURRENT_IP}"
fi

if [ -z "${XXX_CLIENT_ADDRESS_XXX}" ] ; then
  XXX_CLIENT_ADDRESS_XXX="${CURRENT_IP}"
fi

if [ -z "${XXX_DIRECTOR_NAME_XXX}" ] ; then
  XXX_DIRECTOR_NAME_XXX="director_bareos_$(___get_last_oktet "${XXX_DIRECTOR_ADDRESS_XXX}")"
fi

if [ -z "${XXX_STORAGE_DAEMON_NAME_XXX}" ] ; then
  XXX_STORAGE_DAEMON_NAME_XXX="storage_daemon_bareos_$(___get_last_oktet "${XXX_STORAGE_DAEMON_ADDRESS_XXX}")"
fi

if [ -z "${XXX_FILE_DAEMON_NAME_XXX}" ] ; then
  XXX_FILE_DAEMON_NAME_XXX="file_daemon_bareos_$(___get_last_oktet "${XXX_CLIENT_ADDRESS_XXX}")"
fi

if [ -z "${XXX_CLIENT_NAME_XXX}" ] ; then
  XXX_CLIENT_NAME_XXX="client_bareos_server_$(___get_last_oktet "${XXX_CLIENT_ADDRESS_XXX}")"
fi

if [ -z "${XXX_CONSOLE_ADMIN_NAME_XXX}" ] ; then
  XXX_CONSOLE_ADMIN_NAME_XXX="console_admin_bareos_$(___get_last_oktet "${XXX_DIRECTOR_ADDRESS_XXX}")"
fi

if [ -z "${XXX_CONSOLE_MONITORING_NAME_XXX}" ] ; then
  XXX_CONSOLE_MONITORING_NAME_XXX="console_monitoring_bareos_$(___get_last_oktet "${XXX_DIRECTOR_ADDRESS_XXX}")"
fi

### <<< }

### >>> Наполнение конфигов адресами и именами {
___set_config_data "XXX_MAIL_SERVER_XXX"              "${XXX_MAIL_SERVER_XXX}"
___set_config_data "XXX_BAREOS_EMAIL_XXX"             "${XXX_BAREOS_EMAIL_XXX}"
___set_config_data "XXX_ADMIN_EMAIL_XXX"              "${XXX_ADMIN_EMAIL_XXX}"
___set_config_data "XXX_DIRECTOR_ADDRESS_XXX"         "${XXX_DIRECTOR_ADDRESS_XXX}"
___set_config_data "XXX_STORAGE_DAEMON_ADDRESS_XXX"   "${XXX_STORAGE_DAEMON_ADDRESS_XXX}"
___set_config_data "XXX_CLIENT_ADDRESS_XXX"           "${XXX_CLIENT_ADDRESS_XXX}"
___set_config_data "XXX_DIRECTOR_NAME_XXX"            "${XXX_DIRECTOR_NAME_XXX}"
___set_config_data "XXX_STORAGE_DAEMON_NAME_XXX"      "${XXX_STORAGE_DAEMON_NAME_XXX}"
___set_config_data "XXX_FILE_DAEMON_NAME_XXX"         "${XXX_FILE_DAEMON_NAME_XXX}"
___set_config_data "XXX_CLIENT_NAME_XXX"              "${XXX_CLIENT_NAME_XXX}"
___set_config_data "XXX_CONSOLE_WEBUI_NAME_XXX"       "${XXX_CONSOLE_WEBUI_NAME_XXX}"
___set_config_data "XXX_CONSOLE_ADMIN_NAME_XXX"       "${XXX_CONSOLE_ADMIN_NAME_XXX}"
___set_config_data "XXX_CONSOLE_MONITORING_NAME_XXX"  "${XXX_CONSOLE_MONITORING_NAME_XXX}"
___set_config_data "XXX_CATALOG_DBNAME_XXX"           "${XXX_CATALOG_DBNAME_XXX}"
___set_config_data "XXX_CATALOG_DBUSER_XXX"           "${XXX_CATALOG_DBUSER_XXX}"
___set_config_data "XXX_PATH_TO_XXX"                  "${XXX_PATH_TO_XXX}"
mkdir -p "$(echo "${XXX_PATH_TO_XXX}" | tr -d '\\')"
### <<< }

### Наполнение основного каталога дополнительными данными {
cp -rf "${THIS_SCRIPT_DIR}/templates"       "${BAREOS_DIR}"
cp -rf "${THIS_SCRIPT_DIR}/helpers"         "${BAREOS_DIR}"
cp -rf "${THIS_SCRIPT_DIR}/scripts"         "${BAREOS_DIR}"
cp -rf "${THIS_SCRIPT_DIR}/backup_scripts"  "${BAREOS_DIR}"
sed -i "s/XXX_ROOT_DB_PASSWORD_XXX/${XXX_ROOT_DB_PASSWORD_XXX}/g" "${BAREOS_BACKUP_SCRIPTS_DIR}/bareos_mysql_dump.sh"
sed -i   "s/XXX_CATALOG_DBNAME_XXX/${XXX_CATALOG_DBNAME_XXX}/g"   "${BAREOS_BACKUP_SCRIPTS_DIR}/bareos_mysql_dump.sh"
chown --recursive bareos:bareos "${BAREOS_DIR}"
### <<< }

### Просто перестраховка
OUT_FILE="${BAREOS_TEMPLATES_DIR}/.initialize_variables"
if [ -d "${OUT_FILE}" ] ; then
  mv "${OUT_FILE}" "${OUT_FILE}.bak_${NOW}"
fi

### Сохранение использованных переменных и их значений в файл, на всякий случай, вдруг пригодится {
echo "# Generated $(date "+%d.%m.%Y %H:%M:%S")"                                   >  "${OUT_FILE}"
echo ""                                                                           >> "${OUT_FILE}"
echo "XXX_MAIL_SERVER_XXX              = ${XXX_MAIL_SERVER_XXX}"                  >> "${OUT_FILE}"
echo "XXX_BAREOS_EMAIL_XXX             = ${XXX_BAREOS_EMAIL_XXX}"                 >> "${OUT_FILE}"
echo "XXX_ADMIN_EMAIL_XXX              = ${XXX_ADMIN_EMAIL_XXX}"                  >> "${OUT_FILE}"
echo ""                                                                           >> "${OUT_FILE}"
echo "XXX_DIRECTOR_PASS_XXX            = \"${XXX_DIRECTOR_PASS_XXX}\""            >> "${OUT_FILE}"
echo "XXX_CLIENT_PASS_XXX              = \"${XXX_CLIENT_PASS_XXX}\""              >> "${OUT_FILE}"
echo "XXX_STORAGE_PASS_XXX             = \"${XXX_STORAGE_PASS_XXX}\""             >> "${OUT_FILE}"
echo "XXX_CONSOLE_PASS_XXX             = \"${XXX_CONSOLE_PASS_XXX}\""             >> "${OUT_FILE}"
echo "XXX_DIRECTOR_MONITOR_PASS_XXX    = \"${XXX_DIRECTOR_MONITOR_PASS_XXX}\""    >> "${OUT_FILE}"
echo "XXX_CLIENT_MONITOR_PASS_XXX      = \"${XXX_CLIENT_MONITOR_PASS_XXX}\""      >> "${OUT_FILE}"
echo "XXX_STORAGE_MONITOR_PASS_XXX     = \"${XXX_STORAGE_MONITOR_PASS_XXX}\""     >> "${OUT_FILE}"
echo "XXX_CONSOLE_MONITORING_PASS_XXX  = \"${XXX_CONSOLE_MONITORING_PASS_XXX}\""  >> "${OUT_FILE}"
echo "XXX_CONSOLE_WEBUI_PASS_XXX       = \"${XXX_CONSOLE_WEBUI_PASS_XXX}\""       >> "${OUT_FILE}"
echo "XXX_CATALOG_DBPASSWORD_XXX       = \"${XXX_CATALOG_DBPASSWORD_XXX}\""       >> "${OUT_FILE}"
echo "XXX_ROOT_DB_PASSWORD_XXX         = \"${XXX_ROOT_DB_PASSWORD_XXX}\""         >> "${OUT_FILE}"
echo ""                                                                           >> "${OUT_FILE}"
echo "XXX_DIRECTOR_ADDRESS_XXX         = ${XXX_DIRECTOR_ADDRESS_XXX}"             >> "${OUT_FILE}"
echo "XXX_STORAGE_DAEMON_ADDRESS_XXX   = ${XXX_STORAGE_DAEMON_ADDRESS_XXX}"       >> "${OUT_FILE}"
echo "XXX_CLIENT_ADDRESS_XXX           = ${XXX_CLIENT_ADDRESS_XXX}"               >> "${OUT_FILE}"
echo ""                                                                           >> "${OUT_FILE}"
echo "XXX_DIRECTOR_NAME_XXX            = ${XXX_DIRECTOR_NAME_XXX}"                >> "${OUT_FILE}"
echo "XXX_STORAGE_DAEMON_NAME_XXX      = ${XXX_STORAGE_DAEMON_NAME_XXX}"          >> "${OUT_FILE}"
echo "XXX_FILE_DAEMON_NAME_XXX         = ${XXX_FILE_DAEMON_NAME_XXX}"             >> "${OUT_FILE}"
echo "XXX_CLIENT_NAME_XXX              = ${XXX_CLIENT_NAME_XXX}"                  >> "${OUT_FILE}"
echo ""                                                                           >> "${OUT_FILE}"
echo "XXX_CATALOG_DBNAME_XXX           = ${XXX_CATALOG_DBNAME_XXX}"               >> "${OUT_FILE}"
echo "XXX_CATALOG_DBUSER_XXX           = ${XXX_CATALOG_DBUSER_XXX}"               >> "${OUT_FILE}"
echo ""                                                                           >> "${OUT_FILE}"
echo "XXX_CONSOLE_WEBUI_NAME_XXX       = ${XXX_CONSOLE_WEBUI_NAME_XXX}"           >> "${OUT_FILE}"
echo "XXX_CONSOLE_ADMIN_NAME_XXX       = ${XXX_CONSOLE_ADMIN_NAME_XXX}"           >> "${OUT_FILE}"
echo "XXX_CONSOLE_MONITORING_NAME_XXX  = ${XXX_CONSOLE_MONITORING_NAME_XXX}"      >> "${OUT_FILE}"
echo ""                                                                           >> "${OUT_FILE}"
echo "XXX_PATH_TO_XXX                  = ${XXX_PATH_TO_XXX}"                      >> "${OUT_FILE}"

chmod 400 "${OUT_FILE}"
### <<< }

### Создание конфига для веб-интерфейса
if [ -f "${BAREOS_WEBUI}" ] ; then
  mv "${BAREOS_WEBUI}" "${BAREOS_WEBUI}.bak_${NOW}"
  cat << EOF_BAREOS_WEBUI >"${BAREOS_WEBUI}"
[localhost-dir]
enabled = "yes"
dbdriver = "mysql"
dbaddress = "127.0.0.1"
dbport = 3306
dbname = "${XXX_WEBUI_DBNAME_XXX}"
dbuser = "${XXX_WEBUI_DBUSER_XXX}"
dbpassword = "${XXX_WEBUI_DBPASSWORD_XXX}"
diraddress = "${XXX_DIRECTOR_ADDRESS_XXX}"
dirport = 9101
EOF_BAREOS_WEBUI
fi

