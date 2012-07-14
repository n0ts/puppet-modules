#!/bin/bash

/bin/date > /var/run/vrrp_status
/bin/echo "$@" >> /var/run/vrrp_status
