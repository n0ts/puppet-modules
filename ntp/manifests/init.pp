#
# ntp module
#

$ntp_servers = [ "ntp.nict.jp",
                 "ntp.nc.u-tokyo.ac.jp",
                 "clock.nc.fukuoka-u.ac.jp",
                 "clock.tl.fukuoka-u.ac.jp",
                 "time.nuri.net" ]

class ntp {
    file { "/etc/ntp.conf":
        content => template("ntp/etc/ntp.conf"),
    }

    service { "ntpd":
        subscribe => File["/etc/ntp.conf"],
        require   => Package["ntp"],
    }

    package { "ntp": }
}

