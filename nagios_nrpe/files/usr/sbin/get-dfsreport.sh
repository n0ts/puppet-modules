#!/bin/sh

#
# Added /etc/sudoers
# nagios              ALL = (ALL)        NOPASSWD: /usr/sbin/get-dfsreport.sh
#
sudo -u hadoop /usr/bin/hadoop dfsadmin -report
