#
# iptables module
#

class iptables {
    define install($append_source = "") {
        file { "/etc/sysconfig/iptables":
            owner  => root,
            group  => root,
            mode   => 600,
            source => "puppet:///${name}/etc/sysconfig/iptables${append_source}",
            notify => Exec["iptables-restart"],
        }

        exec { "iptables-restart":
            command     => "/etc/init.d/iptables restart",
            notify      => Exec["iptables-sysctl"],
            refreshonly => true,
        }

        exec { "iptables-sysctl":
            command     => "/sbin/sysctl -p",
            refreshonly => true,
        }
    }
}
