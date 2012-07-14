#!/bin/sh
# stand-alone bash version of vdsm's ksm.py
# monitor system memory load and tune ksm accordingly
#
# needs testing and ironing. contact danken@redhat.com if something breaks.
#DEBUG=1
KSMCTL="ksmctl"

KSM_MONITOR_INTERVAL=${KSM_MONITOR_INTERVAL:-60}
KSM_NPAGES_BOOST=${KSM_NPAGES_BOOST:-300}
KSM_NPAGES_DECAY=${KSM_NPAGES_DECAY:--50}
KSM_NPAGES_MIN=${KSM_NPAGES_MIN:-64}
KSM_NPAGES_MAX=${KSM_NPAGES_MAX:-1250}
# microsecond sleep between ksm scans for 16Gb server. Smaller servers sleep
# more, bigger sleep less.
KSM_SLEEP=${KSM_SLEEP:<%= ksm_sleep %>}

KSM_THRES_COEF=${KSM_THRES_COEF:-30}
KSM_THRES_CONST=${KSM_THRES_CONST:-2048}

total=`awk '/^MemTotal:/ {print $2}' /proc/meminfo`
[ -n "$DEBUG" ] && echo total $total

npages=0
sleep=$[KSM_SLEEP * 16 * 1024 * 1024 / total]
[ -n "$DEBUG" ] && echo sleep $sleep
thres=$[total * KSM_THRES_COEF / 100]
if [ $KSM_THRES_CONST -gt $thres ]; then
    thres=$KSM_THRES_CONST
fi
[ -n "$DEBUG" ] && echo thres $thres

committed_memory () {
    # calculate how much memory is committed to running qemu processes
    local progname
    progname=${1:-qemu}
    ps -o vsz `pgrep $progname` | awk '{ sum += $1 }; END { print sum }'
}

increase_napges() {
    local delta
    delta=${1:-0}
    npages=$[npages + delta]
    if [ $npages -lt $KSM_NPAGES_MIN ]; then
        npages=$KSM_NPAGES_MIN
    elif [ $npages -gt $KSM_NPAGES_MAX ]; then
        npages=$KSM_NPAGES_MAX
    fi
    echo $npages
}

adjust () {
    local free committed
    free=`awk '/^MemFree:/ { free += $2}; /^Buffers:/ {free += $2}; /^Cached:/{free += $2}; END {print free}' /proc/meminfo`
     committed=`committed_memory`
    [ -n "$DEBUG" ] && echo committed $committed free $free
    if [ $[committed + thres] -lt $total ]; then
        $KSMCTL stop
        [ -n "$DEBUG" ] && echo "$[committed + thres] < $total, stop ksm"
        return 1
    fi
    [ -n "$DEBUG" ] && echo "$[committed + thres] > $total, start ksm"
    if [ $free -lt $thres ]; then
        npages=`increase_napges $KSM_NPAGES_BOOST`
        [ -n "$DEBUG" ] && echo "$free < $thres, boost" else
    else
        npages=`increase_napges $KSM_NPAGES_DECAY`
        [ -n "$DEBUG" ] && echo "$free > $thres, decay"
    fi
    $KSMCTL start $npages $sleep
    [ -n "$DEBUG" ] && echo "$KSMCTL start $npages $sleep"
    return 0
}

usage () {
    echo usage:
    echo "  $0 [-d]"
    echo
    echo inform $0 of qemu-kvm exec/death with
    echo '  pkill -P `pgrep ksm-monitor` sleep'
    exit 1
}

daemon () {
    while true
    do
        sleep $KSM_MONITOR_INTERVAL
        adjust
    done
}
case x"$1" in
    x-d) daemon & echo ksm monitor pid: $! ;;
    x) adjust ;;
    *) usage ;;
esac

