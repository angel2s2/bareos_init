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
VERSION=0.2015.04.10
DESCRIPTION="${SCRIPT_NAME} - script for bareos"
AUTHOR='Roman (Angel2S2) Shagrov'
EMAIL='bareos_init.mail@angel2s2.ru'   # для ошибок, замечаний и предложений
BLOG='http://blog.angel2s2.ru/'
HOMEPAGE='https://github.com/angel2s2/bareos_init'



### --> Переменные :: можно менять {

### Если задано, то можно не указывать в ключах запуска
### Ключ запуска имеет приоритет
PATH_TO='/mnt/backups'

### Если задано, то пароль будет взят из этой переменной
### Ключ запуска имеет приоритет
### Если не задано и пароль не указан в ключах запуска, то он будет сгенерирован автоматически
CLIENT_PASS=''

BAREOS_DIR="/etc/bareos"        # Основной каталог

### >>> Изменять только в случае, если четко понимаешь, что делаешь {
BAREOS_SCRIPTS_DIR="${BAREOS_DIR}/scripts"
BAREOS_TEMPLATES_DIR="${BAREOS_DIR}/templates"
BAREOS_HELPERS_DIR="${BAREOS_DIR}/helpers"
BAREOS_BACKUP_SCRIPTS_DIR="${BAREOS_DIR}/backup_scripts"
BAREOS_INC_D_DIR="${BAREOS_DIR}/inc.d"
BAREOS_DIR_CONF_D_DIR="${BAREOS_DIR}/bareos-dir.conf.d"
BAREOS_FD_CONF_D_GEN_DIR="${BAREOS_DIR}/bareos-fd.conf.d.gen"
BAREOS_SD_CONF_D_DIR="${BAREOS_DIR}/bareos-sd.conf.d"

BAREOS_TEMPLATE_JOBS="${BAREOS_DIR_CONF_D_DIR}/zzz_jobs.template"
BAREOS_TEMPLATE_FD="${BAREOS_FD_CONF_D_GEN_DIR}/zzz_bareos-fd.template"
BAREOS_TEMPLATE_DEVICES="${BAREOS_SD_CONF_D_DIR}/zzz_devices.template"

CLIENT_PORT='9102'
### <<< }

### <-- }

### --> Служебные переменные, НЕ ТРОГАТЬ! {
JOB_NAME=''
CLIENT_ADDRESS=''
JOB_NAME_T='###name###'
CLIENT_ADDRESS_T='###client_address###'
CLIENT_PASS_T='###client_pass###'
PATH_TO_T='###path_to###'
GEN_PASS_ENABLE='no'
NOW="$(date +%Y%m%d%H%M%S)"
### <-- }


___help() {
cat << EOF_HELP
Usage: add_job.sh -n job_name -a client_address [-P|-p "pass"] [-d "/path/to"]

  -n|--name job_name            - job name (no spaces)
  -a|--address client_address   - clien hostname or ip address
  -p|--password "pass"          - client password
  -P|--gen-pass                 - forced password generation and set for client (override -p)
  -d|--directory "/path/to"     - directory, where backup's files will be stored
  --version                     - no comments ;)
  --help                        - this help
  --readme                      - a few words from the developer...
EOF_HELP
}

___readme() {
cat << EOF_README
Этот скрипт для того, чтобы можно было быстро добавить новое задение.
Для работы скрипт использует переменные, заданные внутри него, параметры запуска, и файлы: 
${BAREOS_TEMPLATE_JOBS}
${BAREOS_TEMPLATE_DEVICES}
${BAREOS_TEMPLATE_FD}
Вы можете отредактировать эти переменные и файлы "под себя", чтобы скрипт добавлял задания
с нужными вам параметрами. На данный момент, скрипт не умеет создавать ресурсы 'pool' и 'schedule',
поэтому после добавления задания, скрипт предлагает отедактивать файл. Пока у меня нет представления,
как бы это реализовать, а делать по принципу мастера (вопрос-ответ) не хочется 
(не нравится мне такой подход и я считаю его не правильным).
EOF_README
}

___version() {
cat << EOF_VERSION
${SCRIPT_NAME}, version ${VERSION}
${DESCRIPTION}
License ${LICENSE}
Copyright (c) 2015 ${AUTHOR}
Contacts: ${EMAIL} | ${BLOG}
Home: ${HOMEPAGE}
EOF_VERSION
}

### Генерирование пароля (-w 45 = длина)
___passwd_gen() {
  head /dev/urandom | tr -dc '0-9a-zA-Z_!@+=.,;:-' | fold -w 45 | head -n 1
}

### Создание бэкапа, если такой файл уже есть
___backup_config() {
  local CURRENT_FILE="$1"
  if [ -f "${CURRENT_FILE}" ] ; then
    echo "File ${CURRENT_FILE} exist! Backing up..."
    mv "${CURRENT_FILE}" "${CURRENT_FILE}.bak_${NOW}"
  fi
}

### Проверка значений параметров запуска
___param_check() {
  if [ -z "$2" ] ; then 
    echo "Value for \`$1' is not specified! Exiting..." 1>&2
    exit 1
  fi
}

# Парсим параметры запуска
if [ $# -le 0 ] ; then ___help ; exit 255 ; fi
while [ $# -gt 0 ]; do
	case "$1" in
    "-n" | "--name"       ) ___param_check '--name' "$2" ; JOB_NAME="$2" ; shift 2 ;;
    "-a" | "--address"    ) ___param_check '--address' "$2" ; CLIENT_ADDRESS="$2" ; shift 2 ;;
	  "-p" | "--password"	  ) ___param_check '--password' "$2" ; CLIENT_PASS="$2" ; shift 2 ;;
    "-P" | "--gen-pass"	  ) GEN_PASS_ENABLE='yes' ; shift ;;
  	"-d" | "--directory"  ) ___param_check '--directory' "$2" ; PATH_TO="$2" ; shift 2 ;;
	  "--version"	          ) ___version ; exit 255 ;;
  	"--help"	            ) ___help ; exit 255 ;;
  	"--readme"	          ) ___readme ; exit 255 ;;
  	*		                  ) echo "Bad param: $1" 1>&2 ; echo '' ; ___help ; exit 1 ;;
  esac
done
if [ -z "${JOB_NAME}" ] ; then echo 'Job name [-n] is not specified! Exiting...' ; exit 1 ; fi
if [ -z "${CLIENT_ADDRESS}" ] ; then echo 'Client address [-a] is not specified! Exiting...' ; exit 1 ; fi

# Если уже есть задание, то спросить, перезаписать его или нет
if [ -f "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf" -o -f "${BAREOS_SD_CONF_D_DIR}/${JOB_NAME}.conf" -o -f "${BAREOS_FD_CONF_D_GEN_DIR}/${JOB_NAME}.bareos_fd.conf" ] ; then
  READ_RESULT='n'
  read -r -p "Job ${JOB_NAME} already exists. Overwrite? [y/N] " READ_RESULT
  # если ответ отрицательный
  if [ "${READ_RESULT}" != "y" -a "${READ_RESULT}" != "Y" -a "${READ_RESULT}" != "yes" -a "${READ_RESULT}" != "YES" ] ; then
    echo 'Exiting...'
    exit 128
  fi
fi

### Если переменная все еще пустая, значит пароль не задан ни в переменной, ни в параметрах запуска,
### или если задан параметр запуска `--gen-pass', значит генерируем пароль
if [ -z "${CLIENT_PASS}" -o "${GEN_PASS_ENABLE}" = 'yes' ] ; then
  CLIENT_PASS="$(___passwd_gen)"
fi

### Если такой файл уже есть, сделать бэкап
___backup_config "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf"
___backup_config "${BAREOS_FD_CONF_D_GEN_DIR}/${JOB_NAME}.bareos_fd.conf"
___backup_config "${BAREOS_SD_CONF_D_DIR}/${JOB_NAME}.conf"

PATH_TO_N="${PATH_TO}/${JOB_NAME}"
PATH_TO="$(echo "${PATH_TO_N}" | sed 's/\//\\\//g')"

### Копирование шаблонов в новые файлы, которые станут рабочими конфигами
echo 'Setting up config files...'
mkdir -p "${PATH_TO_N}"
cp -f "${BAREOS_TEMPLATE_JOBS}"     "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf"
cp -f "${BAREOS_TEMPLATE_FD}"       "${BAREOS_FD_CONF_D_GEN_DIR}/${JOB_NAME}.bareos_fd.conf"
cp -f "${BAREOS_TEMPLATE_DEVICES}"  "${BAREOS_SD_CONF_D_DIR}/${JOB_NAME}.conf"
chown --recursive bareos:bareos     "${PATH_TO_N}"
chown             bareos:bareos     "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf"
chown             bareos:bareos     "${BAREOS_FD_CONF_D_GEN_DIR}/${JOB_NAME}.bareos_fd.conf"
chown             bareos:bareos     "${BAREOS_SD_CONF_D_DIR}/${JOB_NAME}.conf"

### Настройка include'ов {
SED_DIR="$(echo "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf" | sed -e 's/\//\\\//g;s/\./\\\./g;s/\-/\\\-/g')"
SED_SD="$(echo "${BAREOS_SD_CONF_D_DIR}/${JOB_NAME}.conf"   | sed -e 's/\//\\\//g;s/\./\\\./g;s/\-/\\\-/g')"

# jobs
# Если есть отключенное задание, то предлагаем его включить
egrep -qs "^#@${SED_DIR}" "${BAREOS_DIR}/bareos-dir.conf"
if [ $? -eq 0 ] ; then 
  READ_RESULT='y'
  read -r -p "This job is already present in bareos-dir.conf, it is disabled. Turn On? [Y/n] " READ_RESULT
  if [ "${READ_RESULT}" = "y" -o "${READ_RESULT}" = "Y" -o "${READ_RESULT}" = "yes" -o "${READ_RESULT}" = "YES" ] ; then
    sed -i "s/^@#${SED_DIR}/@${SED_DIR}/g" "${BAREOS_DIR}/bareos-dir.conf"
  fi
# иначе проверяем, есть ли уже такое задание и если нету - добавляем инклюд
else
  egrep -qs "^@${SED_DIR}" "${BAREOS_DIR}/bareos-dir.conf"
  if [ $? -ne 0 ] ; then
    sed -i "s/^\(###ADD_HERE_INCLUDES###\)$/\1\n@${SED_DIR}/g" "${BAREOS_DIR}/bareos-dir.conf"
  fi
fi

# devices
# Если есть отключенное задание, то предлагаем его включить
egrep -qs "^#@${SED_SD}" "${BAREOS_DIR}/bareos-sd.conf"
if [ $? -eq 0 ] ; then 
  READ_RESULT='y'
  read -r -p "This job is already present in bareos-dir.conf, it is disabled. Turn On? [Y/n] " READ_RESULT
  if [ "${READ_RESULT}" = "y" -o "${READ_RESULT}" = "Y" -o "${READ_RESULT}" = "yes" -o "${READ_RESULT}" = "YES" ] ; then
    sed -i "s/^@#${SED_SD}/@${SED_SD}/g" "${BAREOS_DIR}/bareos-sd.conf"
  fi
# иначе проверяем, есть ли уже такое задание и если нету - добавляем инклюд
else
  egrep -qs "^@${SED_SD}" "${BAREOS_DIR}/bareos-sd.conf"
  if [ $? -ne 0 ] ; then
    sed -i "s/^\(###ADD_HERE_INCLUDES###\)$/\1\n@${SED_SD}/g"  "${BAREOS_DIR}/bareos-sd.conf"
  fi
fi
### }

### Установка значений в конфигах {
echo 'Setting values: job_name...'
sed -i "s/${JOB_NAME_T}/${JOB_NAME}/g"              "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf"
sed -i "s/${JOB_NAME_T}/${JOB_NAME}/g"              "${BAREOS_FD_CONF_D_GEN_DIR}/${JOB_NAME}.bareos_fd.conf"
sed -i "s/${JOB_NAME_T}/${JOB_NAME}/g"              "${BAREOS_SD_CONF_D_DIR}/${JOB_NAME}.conf"              

echo 'Setting values: client_address...'
sed -i "s/${CLIENT_ADDRESS_T}/${CLIENT_ADDRESS}/g"  "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf"             
sed -i "s/${CLIENT_ADDRESS_T}/${CLIENT_ADDRESS}/g"  "${BAREOS_FD_CONF_D_GEN_DIR}/${JOB_NAME}.bareos_fd.conf"
                                           
echo 'Setting values: client_password...'
sed -i "s/${CLIENT_PASS_T}/${CLIENT_PASS}/g"        "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf"             
sed -i "s/${CLIENT_PASS_T}/${CLIENT_PASS}/g"        "${BAREOS_FD_CONF_D_GEN_DIR}/${JOB_NAME}.bareos_fd.conf"
                                           
echo 'Setting values: directory...'
sed -i "s/${PATH_TO_T}/${PATH_TO}/g"                "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf"              
sed -i "s/${PATH_TO_T}/${PATH_TO}/g"                "${BAREOS_SD_CONF_D_DIR}/${JOB_NAME}.conf"              
### }

READ_RESULT='y'
read -r -p "Open file '${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf' ? [Y/n] " READ_RESULT
if [ "${READ_RESULT}" = "y" -o "${READ_RESULT}" = "Y" -o "${READ_RESULT}" = "yes" -o "${READ_RESULT}" = "YES" ] ; then
  vim "${BAREOS_DIR_CONF_D_DIR}/${JOB_NAME}.conf"
fi

echo "Client settings saved to the file ${BAREOS_FD_CONF_D_GEN_DIR}/${JOB_NAME}.bareos_fd.conf"

nc -znvvw 3 "${CLIENT_ADDRESS}" "${CLIENT_PORT}" &>/dev/null
IS_CLIENT_AVAILABLE=$?
if [ ${IS_CLIENT_AVAILABLE} -eq 0 ] ; then
  echo "Client ${CLIENT_ADDRESS}:${CLIENT_PORT} is available..."
else
  echo "Client ${CLIENT_ADDRESS}:${CLIENT_PORT} is not available..."
fi

READ_RESULT_RELOAD='y'
read -r -p "Reload bareos, for the new settings take effect? [Y/n] " READ_RESULT_RELOAD
if [ "${READ_RESULT_RELOAD}" = "y" -o "${READ_RESULT_RELOAD}" = "Y" -o "${READ_RESULT_RELOAD}" = "yes" -o "${READ_RESULT_RELOAD}" = "YES" ] ; then
  service bareos-sd reload
  service bareos-dir reload
  if [ ${IS_CLIENT_AVAILABLE} -eq 0 ] ; then
    READ_RESULT_CHECK_FILESET=y
    read -r -p "Want to check fileset now? [Y/n] " READ_RESULT_CHECK_FILESET
    if [ "${READ_RESULT_CHECK_FILESET}" = "y" -o "${READ_RESULT_CHECK_FILESET}" = "Y" -o "${READ_RESULT_CHECK_FILESET}" = "yes" -o "${READ_RESULT_CHECK_FILESET}" = "YES" ] ; then
      echo "estimate job=job_${JOB_NAME} listing client=client_${JOB_NAME} fileset=fileset_${JOB_NAME}" | bconsole | less
    fi
  fi
else
  echo "In order to test the fileset, use the command (bconsole):"
  echo "estimate job=job_${JOB_NAME} listing client=client_${JOB_NAME} fileset=fileset_${JOB_NAME}"
fi

