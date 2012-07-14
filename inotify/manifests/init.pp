#
# inotify module
#

class inotify {
    if $inotify_notifypath == "" {
        $inotify_notifypath = "/tmp"
    }
    if $inotify_timeout == "" {
        $inotify_timeout = 5
    }
    if $inotify_events == "" {
        $inotify_events = "modify,attrib,create,delete"
    }
    if $inotify_wait_command == "" {
        $inotify_wait_command = "/usr/sbin/inotifywait -e ${inotify_events} -rq \$INOTIFYPATH"
    }
    if $inotify_wait == "" {
        $inotify_wait = 10
    }
    if $inotify_wait_command == "" {
        $inofity_wait_command = "echo \"inotifywait\""
    }
    if $inotify_filename == "" {
        $inotify_filename = "/usr/sbin/inotify.sh"
    }

    file { $inotify_filename:
        mode    => 755,
        content => template("inotify/inotify.sh"),
        require => Package["inotify-tools"],
    }

    package { "inotify-tools": }
}
