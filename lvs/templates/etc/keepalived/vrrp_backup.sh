#!/bin/sh
/bin/echo 0 > /proc/sys/net/ipv4/conf/eth1/proxy_arp

IP="<%= lvs_vip %>"
for ip in $IP ; do
  /sbin/ip route del $ip dev <%= lvs_internal_interface %>
done
