#!/bin/sh

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

PROGNAME=`basename $0`
VERSION="Version 1.0,"
AUTHOR="2009, Mike Adolphs (http://www.matejunkie.com/)"

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

path_sh="/usr/local/sbin"

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "$PROGNAME is a Nagios plugin to check the status of HDFS, Hadoop's"
	echo "underlying, redundant, distributed file system."
    echo ""
    echo "$PROGNAME -s /usr/local/sbin [-w 10] [-c 5]"
    echo ""
    echo "Options:"
    echo "  -s|--path-sh)"
    echo "     Path to the shell script that is mentioned in the"
	echo "     documentation. Default is: /usr/local/sbin"
	echo "  -w|--warning)"
	echo "     Defines the warning level for available datanodes. Default"
	echo "     is: off"
	echo "  -c|--critical)"
	echo "     Defines the critical level for available datanodes. Default"
	echo "     is: off"
    exit $ST_UK
}

while test -n "$1"; do
    case "$1" in
        -help|-h)
            print_help
            exit $ST_UK
            ;;
        --version|-v)
            print_version $PROGNAME $VERSION
            exit $ST_UK
            ;;
        --path-sh|-s)
            path_sh=$2
			shift
			;;
        --warning|-w)
            warning=$2
            shift
            ;;
        --critical|-c)
            critical=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
        esac
    shift
done

get_wcdiff() {
    if [ ! -z "$warning" -a ! -z "$critical" ]
    then
        wclvls=1

        if [ ${warning} -lt ${critical} ]
        then
            wcdiff=1
        fi
    elif [ ! -z "$warning" -a -z "$critical" ]
    then
        wcdiff=2
    elif [ -z "$warning" -a ! -z "$critical" ]
    then
        wcdiff=3
    fi
}

val_wcdiff() {
    if [ "$wcdiff" = 1 ]
    then
        echo "Please adjust your warning/critical thresholds. The warning \
must be higher than the critical level!"
        exit $ST_UK
    elif [ "$wcdiff" = 2 ]
    then
        echo "Please also set a critical value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    elif [ "$wcdiff" = 3 ]
    then
        echo "Please also set a warning value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    fi
}

get_vals() {
    tmp_vals=`sudo ${path_sh}/get-dfsreport.sh`
    dn_avail=`echo -e "$tmp_vals" | grep -m1 "Datanodes available:" | awk '{print $3}'`
    dfs_used=`echo -e "$tmp_vals" | grep -m1 "Used raw bytes:" | awk '{print $4}'`
    dfs_used=`expr ${dfs_used} / 1024 / 1024`
    dfs_used_p=`echo -e "$tmp_vals" | grep -m1 "% used:" | awk '{print $3}'`
    dfs_total=`echo -e "$tmp_vals" | grep -m1 "Total raw bytes:" | awk '{print $4}'`
    dfs_total=`expr ${dfs_total} / 1024 / 1024`
}

do_output() {
	output="Datanodes up and running: ${dn_avail}, DFS total: \
${dfs_total} MB, DFS used: ${dfs_used} MB (${dfs_used_p})"
}

do_perfdata() {
	perfdata="'datanodes_available'=${dn_avail} 'dfs_total'=${dfs_total} \
'dfs_used'=${dfs_used}"
}

# Here we go!
get_wcdiff
val_wcdiff

get_vals

do_output
do_perfdata

if [ -n "$warning" -a -n "$critical" ]
then
    if [ "$dn_avail" -le "$warning" -a "$dn_avail" -gt "$critical" ]
    then
        echo "WARNING - ${output} | ${perfdata}"
	exit $ST_WR
    elif [ "$dn_avail" -le "$critical" ]
    then
        echo "CRITICAL - ${output} | ${perfdata}"
	exit $ST_CR
    else
        echo "OK - ${output} | ${perfdata} "
	exit $ST_OK
    fi
else
    echo "OK - ${output} | ${perfdata}"
    exit $ST_OK
fi
