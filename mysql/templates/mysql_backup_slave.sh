#!/bin/sh

BACKUP_DIR="<%= mysql_backup_dir %>"
DATABASE="<%= mysql_database %>"
SOCKET="<%= mysql_socket %>"
OPT="<%= mysqldump_opt %>"

MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump

# remove old files
find $BACKUP_DIR/*.sql.gz -maxdepth 1 -mtime +1 -exec rm -rf {} \;

# mysqldump backup
$MYSQL --user=root --socket="$SOCKET" --execute='stop slave; flush tables;'

LOG_FILE=`echo 'show slave status\G' | mysql --user=root --socket="$SOCKET" | egrep 'Relay_Master_Log_File:' | tr -d ' ' | cut -d ':' -f 2`
LOG_POS=`echo 'show slave status\G' | mysql --user=root --socket="$SOCKET" | egrep 'Read_Master_Log_Pos:' | tr -d ' ' | cut -d ':' -f 2`
$MYSQLDUMP --user=root --socket="$SOCKET" $OPT --databases "$DATABASE" | gzip > $BACKUP_DIR/${DATABASE}_${LOG_FILE}_${LOG_POS}.sql.gz

$MYSQL --user=root --socket="$SOCKET" --execute='start slave'
