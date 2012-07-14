#
# bind module
#

class bind {
    if $bind_internal_master_zones == "" {
        $bind_internal_master_zones = []
    }
    if $bind_internal_rev_zones == "" {
        $bind_internal_rev_zones = []
    }
    if $bind_internal_slave_zones == "" {
        $bind_internal_slave_zones = []
    }
    if $bind_internal_slave_masters == "" {
        $bind_internal_slave_masters = []
    }
    if $bind_external_master_zones == "" {
        $bind_external_master_zones = []
    }
    if $bind_external_slave_zones == "" {
        $bind_external_slave_zones = []
    }
    if $bind_external_slave_masters == "" {
        $bind_external_slave_masters = []
    }
    if $bind_install_zone == "" {
        $bind_install_zone = true
    }

    $vardir = "/var/named/chroot"

    $internal_master_zones = $bind_internal_master_zones
    $internal_rev_zones = $bind_internal_rev_zones
    $internal_slave_zones = $bind_internal_slave_zones
    $internal_slave_masters = $bind_internal_slave_masters
    $external_master_zones = $bind_external_master_zones
    $external_slave_zones = $bind_external_slave_zones
    $external_slave_masters = $bind_external_slave_masters

    case $bind_install_zone {
        true: {
            install_zone { $internal_master_zones: }
            install_zone { $internal_slave_zones: }
            install_zone { $external_master_zones: }
            install_zone { $external_slave_zones: }
        }
    }

    install_conf {
        "/etc/named.root.hints": ;
        "/etc/named.rfc1912.zones": ;
        "/var/named/localdomain.zone": ;
        "/var/named/localhost.zone": ;
        "/var/named/named.broadcast": ;
        "/var/named/named.ip6.local": ;
        "/var/named/named.local": ;
        "/var/named/named.root": ;
        "/var/named/named.zero": ;
    }

    create_symlink {
        "/etc/named.conf": ;
        "/etc/named.root.hints": ;
        "/etc/named.rfc1912.zones": ;
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


    define install_zone($module = "bind", $type = "internal.zone", $template = false) {
        if $template == false {
            file { "${vardir}/var/named/chroot/var/named/${name}.${type}":
                owner   => named,
                group   => named,
                mode    => 640,
                source  => "puppet:///${module}/var/named/${name}.${type}",
                notify  => Service["named"],
                require => Package["bind"],
            }
         }
         else {
            file { "${vardir}/var/named/chroot/var/named/${name}.${type}":
                owner   => named,
                group   => named,
                mode    => 640,
                content => template("${module}/var/named/${name}.${type}"),
                notify  => Service["named"],
                require => Package["bind"],
            }
        }
    }

    define install_rev_zone($module = "bind") {
        file { "${vardir}/var/named/chroot/var/named/${name}.in-addr.arpa":
            owner   => named,
            group   => named,
            mode    => 640,
            content => template("${module}/var/named/in-addr.arpa"),
            notify  => Service["named"],
            require => Package["bind"],
        }
    }

    define create_symlink() {
        file { $name:
            owner   => named,
            group   => named,
            ensure  => "${vardir}${name}",
            require => Package["bind"],
        }
    }

    define install_conf() {
        file { "${vardir}${name}":
            owner   => named,
            group   => named,
            mode    => 640,
            source  => "puppet:///bind${name}",
            require => Package["bind"],
            notify  => Service["named"],
        }
    }

    define install_resolv_conf($nameserver = "127.0.0.1") {
        file { "/etc/resolv.conf":
            content => template("bind/etc/resolv.conf"),
        }
    }
}
