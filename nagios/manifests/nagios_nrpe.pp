#
#  nagios_nrpe module
#

class nagios_nrpe {
    file { "/etc/nagios/nrpe.cfg":
        source => "puppet:///nagios/etc/nagios/nrpe.cfg",
        require => Package["nrpe"],
    }

    $packagelist = [ "nrpe", "nrpe-plugin" ]
    package { $packagelist: }

    service { "nrpe":
        subscribe => File["/etc/nagios/nrpe.cfg"],
        require   => [ Package["nrpe"], Package["nrpe-plugin"] ],
    }
}
