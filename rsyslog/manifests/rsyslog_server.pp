#
# rsyslog_server module
#

class rsyslog_server {
    file { "/var/log/syslog":
        ensure => directory,
        mode   => 755,
    }

    file { "/etc/logrotate.d/syslog":
        source  => "puppet:///rsyslog/etc/logrotate.d/syslog",
        require => File["/var/log/syslog"],
    }
}
