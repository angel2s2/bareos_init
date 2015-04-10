#!/bin/bash

HOST=localhost
USERNAME=root
PASSWORD='XXX_ROOT_DB_PASSWORD_XXX'
BACKUP_DIR=/tmp
DATABASES=("XXX_CATALOG_DBNAME_XXX" "mysql")
RETURN=0

echo
for DATABASE in "${DATABASES[@]}"; do
    if [ -e ${BACKUP_DIR}/$DATABASE.sql ] ; then
    	echo "Found old database dump $DATABASE.sql. Removing..."
	    rm -f ${BACKUP_DIR}/$DATABASE.sql
    	if [ $? -eq 0 ] ; then
	    	echo "Old database dump $DATABASE.sql removed succesfull."
            echo
    	else
	    	echo "Error removing old database dump $DATABASE.sql. Aborting..."
            echo
		    RETURN=2
    	fi
    fi
done

echo
echo

[ $RETURN -gt 0 ] && exit $RETURN

for DATABASE in "${DATABASES[@]}"; do
    echo "Starting dump MySQL Database ${DATABASE} to file ${BACKUP_DIR}/$DATABASE.sql..."
    mysqldump -h${HOST} -u${USERNAME} -p${PASSWORD} ${DATABASE} > ${BACKUP_DIR}/$DATABASE.sql
    if [ $? -eq 0 ] ; then
    	echo "Database dump succesfull (${DATABASE})."
        echo
    	RETURN=0
    else
    	echo "Error database dump (${DATABASE}). Sorry..."
        echo
    	RETURN=1
    fi
done

exit $RETURN

