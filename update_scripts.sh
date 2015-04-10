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
SCRIPT_NAME='update_scripts.sh'
VERSION='0.2015.04.10'                            # VER.YEAR.MONTH.DAY
DESCRIPTION="${SCRIPT_NAME} - script for bareos"
AUTHOR='Roman (Angel2S2) Shagrov'
EMAIL='bareos_init.mail@angel2s2.ru'              # для ошибок, замечаний и предложений
BLOG='http://blog.angel2s2.ru/'
HOMEPAGE='https://github.com/angel2s2/bareos_init'

BAREOS_DIR="/etc/bareos"                          # Основной каталог
BAREOS_SCRIPTS_DIR="${BAREOS_DIR}/scripts"
NOW="$(date +%Y%m%d%H%M%S)"
THIS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"  # Откуда запущен скрипт

# получаем список скриптов
ls -1 "${THIS_SCRIPT_DIR}/scripts" | while read CURRENT_FILE ; do 
  # если такого файла нет в каталоге bareos, значит это новый скрипт => тупо копируем
  if [ ! -f "${BAREOS_SCRIPTS_DIR}/${CURRENT_FILE}" ] ; then
    cp -f "${THIS_SCRIPT_DIR}/scripts/${CURRENT_FILE}" "${BAREOS_SCRIPTS_DIR}"
  else
    # иначе сравниваем и если различаются, делаем бэкап, а потом попируем с заменой
    diff -q "${THIS_SCRIPT_DIR}/scripts/${CURRENT_FILE}" "${BAREOS_SCRIPTS_DIR}/${CURRENT_FILE}" &>/dev/null
    if [ $? -eq 1 ] ; then
      cp -f "${BAREOS_SCRIPTS_DIR}/${CURRENT_FILE}" "${BAREOS_SCRIPTS_DIR}/${CURRENT_FILE}.bak_${NOW}"
      cp -f "${THIS_SCRIPT_DIR}/scripts/${CURRENT_FILE}" "${BAREOS_SCRIPTS_DIR}"
    fi
  fi
done

