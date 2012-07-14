#
# syslog module
#

class syslog {
    if $syslog_local0 == "" {
        $syslog_local0 = ""
    }
    if $syslog_local1 == "" {
        $syslog_local1 = ""
    }
    if $syslog_local2 == "" {
        $syslog_local2 = ""
    }
    if $syslog_local3 == "" {
        $syslog_local3 = ""
    }
    if $syslog_local4 == "" {
        $syslog_local4 = ""
    }
    if $syslog_local5 == "" {
       $syslog_local5 = ""
    }
    if $syslog_local6 == "" {
        $syslog_local6 = ""
    }

    file { "/etc/syslog.conf":
        content => template("syslog/etc/syslog.conf"),
        notify  => Service["syslog"],
    }

    service { "syslog": }
}
