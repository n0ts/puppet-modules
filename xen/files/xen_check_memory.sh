#!/bin/sh

XM=/usr/sbin/xm
XEN_CONF=/etc/xen

if [ ! -x $XM ]; then
    echo "Could not found xm."
    exit -1
fi

TOTAL_DOMU_MEMORY=0
for xen_conf in `find $XEN_CONF -maxdepth 1 -type f -name 's*'`
do
    DOMU_NAME=`grep name $xen_conf | tr -d " " | cut -d "=" -f 2`
    DOMU_MEMORY=`grep memory $xen_conf | tr -d " " | cut -d "=" -f 2`
    if [ $DOMU_MEMORY -lt 0 ]; then
        continue
    fi

    echo -e "$DOMU_NAME memory:\t$DOMU_MEMORY MB"
    TOTAL_DOMU_MEMORY=`expr $TOTAL_DOMU_MEMORY + $DOMU_MEMORY`
done

TOTAL_MEMORY=`$XM info | grep total_memory | tr -d " " | cut -d ":" -f 2`
echo -e "Total physical memory:\t$TOTAL_MEMORY MB"

FREE_MEMORY=`$XM info | grep free_memory | tr -d " " | cut -d ":" -f 2`
echo -e "Free memory:\t$FREE_MEMORY MB"

echo -e "Total DomU memory:\t$TOTAL_DOMU_MEMORY MB"

DOM0_MEMORY=`expr $TOTAL_MEMORY - $TOTAL_DOMU_MEMORY`
echo -e "DomO memory must be $DOM0_MEMORY MB (Recommand 2048MB)."
