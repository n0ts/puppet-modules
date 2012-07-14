#
# rsyslog module
#

import "rsyslog_server"

class rsyslog {
    #
    # syslog = syslogd + klogd
    #
    service { "syslog":
        enable  => false,
        ensure  => stopped,
        pattern => "klogd",
        before  => Service["rsyslog"],
    }

    #
    # rsyslog
    #
    service { "rsyslog":
        require => Package["rsyslog"],
    }

    package { "rsyslog": }


    define install_conf($module = "rsyslog", $template = false) {
        file { "/etc/rsyslog.conf":
            notify  => Service["rsyslog"],
            require => Package["rsyslog"],
        }

        if $template == false {
            File["/etc/rsyslog.conf"] {
                source +> "puppet:///${module}/etc/rsyslog.conf",
            }
        } else {
            File["/etc/rsyslog.conf"] {
                content +> template("${module}/etc/rsyslog.conf"),
            }
        }
    }
}
