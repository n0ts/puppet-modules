#!/bin/sh

if [ ! -x /usr/bin/inotifywait ]; then
    echo "Could not found /usr/bin/inotifywait."
    exit -1
fi

INOTIFYPATH=<%= inotify_notifypath %>
if [ ! -d $INOTIFYPATH ]; then
    echo "Could not found $INOTIFYPATH."
    exit -1
fi

INOTIFYWAIT="<%= inotify_wait_command %>"

PREV_INOTIFYWAIT_PID=`pgrep -f "$INOTIFYWAIT"`
if [ "$PREV_INOTIFYWAIT_PID" ]; then
    kill -TERM "$PREV_INOTIFYWAIT_PID"
fi

while $INOTIFYWAIT; do
    sleep <%= inotify_wait %>

    <%= inotify_wait_command %>
done
