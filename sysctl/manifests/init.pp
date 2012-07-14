#
# sysctl module
#

class sysctl {
    define install() {
        file { "/etc/sysctl.conf":
            owner  => root,
            group  => root,
            mode   => 644,
            source => "puppet:///${name}/etc/sysctl.conf",
            notify => Exec["sysctl"],
        }

        exec { "sysctl":
            command     => "sysctl -p",
            refreshonly => true,
        }
    }
}
