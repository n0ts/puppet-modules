#!/bin/sh
/bin/echo 1 > /proc/sys/net/ipv4/conf/eth1/proxy_arp

IP="<%= lvs_vip %>"
for ip in $IP ; do
  /sbin/ip route add $ip dev <%= lvs_internal_interface %>
  /bin/echo "garp -i eth1 -a $ip -n 10" | logger -t GARP
  /usr/bin/garp -i eth1 -a $ip -n 10
done

