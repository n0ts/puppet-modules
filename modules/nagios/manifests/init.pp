#
# nagios module
#

import "nagios_nrpe"


class nagios {
    file { "/var/log/nagios/spool/checkresults":
        ensure => directory,
        owner => nagios,
        group => nagios,
        mode => 755,
        require => Package["nagios"],
    }

    file { "/var/log/nagios/rw":
        ensure => directory,
        owner => nagios,
        group => nagiocmd,
        mode => 2755,
        require => Package["nagios"],
    }

    service { "nagios":
        require   => Package["nagios"],
    }

    $packagelist = [ "nagios", "nagios-www", "nagios-plugins" ]
    package { $packagelist: }


    define do_global_conf() {
        file { "/etc/nagios/${name}":
            source => "puppet:///${global_name}/etc/nagios/${name}",
            notify => Service["nagios"],
        }
    }

    define do_global_object_dir() {
        file { "/etc/nagios/${global_name}":
            ensure => directory,
        }
    }

    define do_global_object_conf() {
        file { "/etc/nagios/${global_name}/${name}":
            source => "puppet:///${global_name}/etc/nagios/${global_name}/${name}",
            notify => Service["nagios"],
        }
    }
}

