#
# sysstat module
#

class sysstat {
    file { "/etc/sysconfig/sysstat":
        source  => "puppet:///sysstat/etc/sysconfig/sysstat",
        require => Package["sysstat"],
    }

    package { "sysstat": }
}
