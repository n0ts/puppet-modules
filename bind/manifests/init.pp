#
# bind module
#

$bind_internal_master_zones = []
$bind_internal_slave_zones = []
$bind_internal_slave_masters = []
$bind_external_master_zones = []
$bind_external_slave_zones = []
$bind_external_slave_masters = []

class bind {
    $vardir = "/var/named/chroot"

    $internal_master_zones = $bind_internal_master_zones
    $internal_slave_zones = $bind_internal_slave_zones
    $internal_slave_masters = $bind_internal_slave_masters
    $external_master_zones = $bind_external_master_zones
    $external_slave_zones = $bind_external_slave_zones
    $external_slave_masters = $bind_external_slave_masters

    do_zone { $internal_master_zones: }
    do_zone { $internal_slave_zones: }
    do_zone { $external_master_zones: }
    do_zone { $external_slave_zones: }

    do_conf {
        [
         "/etc/named.root.hints",
         "/etc/named.rfc1912.zones",
         "/var/named/localdomain.zone",
         "/var/named/localhost.zone",
         "/var/named/named.broadcast",
         "/var/named/named.ip6.local",
         "/var/named/named.local",
         "/var/named/named.root",
        "/var/named/named.zero"
         ]:
    }

    do_symlink {
        [
         "/etc/named.conf",
         "/etc/named.root.hints",
         "/etc/named.rfc1912.zones"
         ]:
    }


    file { "${vardir}/etc/named.conf":
        group   => named,
        content => template("bind/etc/named.conf"),
        require => Package["bind"],
    }

    service { "named":
        subscribe => File["${vardir}/etc/named.conf"],
        require   => Package["bind"],
    }

    $packagelist = ["bind", "bind-chroot"]
    package { $packagelist: }

    file { "/etc/resolv.conf":
        content => template("bind/etc/resolv.conf"),
    }


    define do_zone() {
        file { "${vardir}/var/named/${name}.internal.zone":
            group  => named,
            source => "puppet:///bind/var/named/${name}.internal.zone",
            before => Service["named"],
            notify => Service["named"],
        }
    }

    define do_symlink() {
        file { $name:
            ensure  => "${vardir}${name}",
            require => Package["bind"],
        }
    }

    define do_conf() {
        file { "${vardir}${name}":
            group   => named,
            source  => "puppet:///bind${name}",
            require => Package["bind"],
        }
    }
}
