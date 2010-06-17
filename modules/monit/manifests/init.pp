#
# monit module
#

class monit {
    file { "/etc/monit.d":
        ensure => directory,
        mode   => 700,
    }

    do_conf { "dummy": }

    file { "/etc/monitrc":
        mode    => 600,
        source  => "puppet:///monit/etc/monitrc",
        require => Package["monit"],
    }

    service { "monit":
        subscribe => [ File["/etc/monit.d/dummy"], File["/etc/monitrc"] ],
        require   => Package["monit"],
    }

    package { "monit": ensure => installed }


    define do_conf() {
        file { "/etc/monit.d/${name}":
            mode   => 600,
            source => "puppet:///monit/etc/monit.d/${name}",
            before => Service["monit"],
            notify => Service["monit"],
        }
    }

    define do_global_conf() {
        file { "/etc/monit.d/${name}":
            mode   => 600,
            source => "puppet:///${global_name}/etc/monit.d/${name}",
            before => Service["monit"],
            notify => Service["monit"],
        }
    }
}
