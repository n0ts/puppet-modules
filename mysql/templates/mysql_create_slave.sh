#!/bin/sh

DATABASE=<%= mysql_database %>
MASTER_HOST=<%= mysql_master_host %>
MASTER_USER=<%= mysql_repl_user %>
MASTER_PASSWORD=<%= mysql_repl_password %>
SOCKET=<%= mysql_socket %>

function create_slave()
{
    SQL_FILE=$1
    if [ ! -f $SQL_FILE ]; then
        echo Could not found sql file - $SQL_FILE
        exit -1
    fi

    LOG_FILE=`echo $SQL_FILE | cut -d '.' -f 2 | cut -d '_' -f 1`
    if [ -z $LOG_FILE ]; then
        echo Log file name is empty
        exit -1
    fi
    LOG_POS=`echo $SQL_FILE | cut -d '.' -f 2 | cut -d '_' -f 2`
    if [ -z $LOG_POS ]; then
        echo Log position is empty
        exit -1
    fi

    mysql --user=root --socket=$SOCKET $DATABASE < $1
    mysql --user=root --socket=$SOCKET --execute="CHANGE MASTER TO MASTER_HOST='$MASTER_HOST', MASTER_USER='$MASTER_USER', MASTER_PASSWORD='$MASTER_PASSWORD', MASTER_LOG_FILE='mysql-bin.$LOG_FILE', MASTER_LOG_POS=$LOG_POS, MASTER_CONNECT_RETRY=10"
    mysql --user=root --socket=$SOCKET --execute="START SLAVE"
}


SQL_FILE=$1

if [ ! -f $SQL_FILE ]; then
    echo Usage: `basename $0` \"SQL file\":
    exit -1
fi

echo -n "Are you sure want to create mysql slave server? [y/N] "
read INPUT
if [ -z $INPUT ]; then
    INPUT=n
fi

if [ $INPUT == 'y' ]; then
    BASENAME=${SQL_FILE##*/}
    EXTENSION=${BASENAME##*.}
    if [ $EXTENSION == 'gz' ]; then
        gzip -d $SQL_FILE
        SQL_FILE=`echo $SQL_FILE | sed -e 's/\.gz//'`
    fi

    create_slave $SQL_FILE
    exit 0
else
    exit -1
fi

