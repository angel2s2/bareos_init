#!/bin/bash

THIS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"                          # Откуда запущен скрипт
INIT_SCRIPT="${THIS_SCRIPT_DIR}/initialize_bareos_configs.sh"
MVERSION=0
#VERSION="${MVERSION}.$(date +%Y.%m.%d)"

rm -rf "${THIS_SCRIPT_DIR}/backup_scripts/old"
#find "${THIS_SCRIPT_DIR}/scripts" -type f -name '*.sh' -exec sed -i "s/^\(VERSION=\).*$/\1${VERSION}/g" '{}' \;
sed -i 's/\(HTTP_PROXY="\).*"/\1"/g'                                 "${THIS_SCRIPT_DIR}/install_fd.sh"

sed -i "s/^\([#]\?XXX_ROOT_DB_PASSWORD_XXX='\)[^']*'/\1'/g"          "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_MAIL_SERVER_XXX='\)[^']*'/\1'/g"               "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_BAREOS_EMAIL_XXX='\)[^']*'/\1'/g"              "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_ADMIN_EMAIL_XXX='\)[^']*'/\1'/g"               "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_CATALOG_DBNAME_XXX='\)[^']*'/\1'/g"            "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_CATALOG_DBUSER_XXX='\)[^']*'/\1'/g"            "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_CATALOG_DBPASSWORD_XXX='\)[^']*'/\1'/g"        "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_WEBUI_DBUSER_XXX='\)[^']*'/\1'/g"              "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_WEBUI_DBPASSWORD_XXX='\)[^']*'/\1'/g"          "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_CONSOLE_WEBUI_PASS_XXX='\)[^']*'/\1'/g"        "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_DIRECTOR_PASS_XXX='\)[^']*'/\1'/g"             "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_CLIENT_PASS_XXX='\)[^']*'/\1'/g"               "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_STORAGE_PASS_XXX='\)[^']*'/\1'/g"              "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_CONSOLE_PASS_XXX='\)[^']*'/\1'/g"              "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_DIRECTOR_MONITOR_PASS_XXX='\)[^']*'/\1'/g"     "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_CLIENT_MONITOR_PASS_XXX='\)[^']*'/\1'/g"       "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_STORAGE_MONITOR_PASS_XXX='\)[^']*'/\1'/g"      "${INIT_SCRIPT}"
sed -i "s/^\([#]\?XXX_CONSOLE_MONITORING_PASS_XXX='\)[^']*'/\1'/g"   "${INIT_SCRIPT}"

#sed -i "s/^\([#]\?XXX_DIRECTOR_ADDRESS_XXX='\)[^']*'/\1'/g"          "${INIT_SCRIPT}"
#sed -i "s/^\([#]\?XXX_CLIENT_ADDRESS_XXX='\)[^']*'/\1'/g"            "${INIT_SCRIPT}"
#sed -i "s/^\([#]\?XXX_STORAGE_DAEMON_ADDRESS_XXX='\)[^']*'/\1'/g"    "${INIT_SCRIPT}"
#sed -i "s/^\([#]\?XXX_DIRECTOR_NAME_XXX='\)[^']*'/\1'/g"             "${INIT_SCRIPT}"
#sed -i "s/^\([#]\?XXX_STORAGE_DAEMON_NAME_XXX='\)[^']*'/\1'/g"       "${INIT_SCRIPT}"
#sed -i "s/^\([#]\?XXX_FILE_DAEMON_NAME_XXX='\)[^']*'/\1'/g"          "${INIT_SCRIPT}"
#sed -i "s/^\([#]\?XXX_CLIENT_NAME_XXX='\)[^']*'/\1'/g"               "${INIT_SCRIPT}"
#sed -i "s/^\([#]\?XXX_CONSOLE_ADMIN_NAME_XXX='\)[^']*'/\1'/g"        "${INIT_SCRIPT}"
#sed -i "s/^\([#]\?XXX_CONSOLE_MONITORING_NAME_XXX='\)[^']*'/\1'/g"   "${INIT_SCRIPT}"


git diff --color
read -p 'Press Enter to continue...'

if [ "$(git tag -l v${MVERSION})" = "v${MVERSION}" ] ; then
  if [ $# -gt 0 ] ; then
    git add . && git commit --message="$*" && git push
  else
    git add . && git commit && git push
  fi
else
  if [ $# -gt 0 ] ; then
    git add . && git tag "v${MVERSION}" && git commit --message="$*" && git push
  else
    git add . && git tag "v${MVERSION}" && git commit && git push
  fi
fi

