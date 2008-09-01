#
# lvs module
#

class lvs {

    #
    # load balancer setting
    #
    $sysctl = "/etc/sysctl.conf"

    file { $sysctl:
        source => "puppet:///lvs${sysctl}",
        notify => Exec['sysctl'],
        before => Exec['sysctl'],
    }

    exec { "sysctl":
        command     => "/sbin/sysctl -p",
        refreshonly => true,
    }


    #
    # keepalived
    #
    file { "/etc/init.d/keepalived":
        mode   => 755,
        source => "puppet:///lvs/etc/init.d/keepalived",
        notify => Service["keepalived"],
        before => Service["keepalived"],
    }

    file { "/etc/keepalived/conf.d":
        ensure => directory,
    }

    file { "/etc/logrotate.d/syslog":
        source => "puppet:///lvs/etc/logrotate.d/syslog",
    }

    do_conf { [
               "/etc/keepalived/keepalived.conf",
               "/etc/sysconfig/keepalived"
               ]:
    }

    service { "keepalived":
        restart => "/etc/init.d/keepalived condrestart",
        require => Package["keepalived"],
    }

    $packagelist = ["ipvsadm", "keepalived"]
    package { $packagelist: }

    file { "/etc/syslog.conf":
        source => "puppet:///lvs/etc/syslog.conf",
        notify => Service["syslog"],
        before => Service["syslog"],
    }

    service { "syslog": }


    define do_conf() {
        file { $name:
            mode   => 600,
            source => "puppet:///lvs/${name}",
            notify => Service["keepalived"],
            before => Service["keepalived"],
        }
    }

    define do_global_conf() {
        file { $name:
            mode   => 600,
            source => "puppet:///${global_name}/${name}",
            notify => Service["keepalived"],
            before => Service["keepalived"],
        }
    }
}
