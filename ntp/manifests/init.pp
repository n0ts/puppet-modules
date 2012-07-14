#
# ntp module
#

class ntp {
    if $ntp_local_clock_server == "" {
        $ntp_local_clock_server = false
    }
    if $ntp_local_clock_fudge == "" {
        $ntp_local_clock_fudge = true
    }
    if $ntp_use_external_servers == "" {
        $ntp_use_external_servers = false
    }

    if $ntp_use_external_servers == true {
        # default ntp servers for japan
        $ntp_servers = [ "ntp.nict.jp",
                         "0.jp.pool.ntp.org",
                         "1.jp.pool.ntp.org",
                         "2.jp.pool.ntp.org" ]
    } else {
        $ntp_servers = "ntp.${domain}"
    }

    file { "/etc/ntp.conf":
        content => template("ntp/etc/ntp.conf"),
        notify  => Service["ntpd"],
        require => Package["ntp"],
    }

    if $is_virtual == "false" {
        file { "/etc/sysconfig/ntpd":
            source  => "puppet:///ntp/etc/sysconfig/ntpd",
            notify  => Service["ntpd"],
            require => Package["ntp"],
        }
    }

    service { "ntpd":
        require => Package["ntp"],
    }

    package { "ntp": }
}
