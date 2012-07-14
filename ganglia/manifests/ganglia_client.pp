#
# ganglia_client module
#

class ganglia::client {
    if $ganglia_cluster_name == "" {
        $ganglia_cluster_name = "unspecified"
    }
    if $ganglia_cluster_owner == "" {
        $ganglia_cluster_owner = "unspecified"
    }
    if $ganglia_cluster_url == "" {
        $ganglia_cluster_url = "unspecified"
    }
    if $ganglia_host_location == "" {
        $ganglia_host_location = "unspecified"
    }
    if $ganglia_mcast_addr == "" {
        $ganglia_mcast_addr = "224.0.0.1"
    }
    if $ganglia_mcast_port == "" {
        $ganglia_mcast_port = "8649"
    }
    if $ganglia_iface == "" {
        $ganglia_iface = "eth0"
    }
    if $ganglia_use_gmond_conf == "" {
        $ganglia_use_gmond_conf = true
    }
    if $ganglia_install_static_routes == "" {
        $ganglia_install_static_routes = true
    }
    if $ganglia_collect_every == "" {
        $ganglia_collect_every = "20"
    }
    if $ganglia_time_threshold == "" {
        $ganglia_time_threshold = "60"
    }

    if $ganglia_use_gmond_conf == true {
        file { "/etc/ganglia/gmond.conf":
            content => template("ganglia/etc/ganglia/gmond.conf"),
            notify  => Service["gmond"],
            require => Package["ganglia-gmond"],
        }
    }

    if $ganglia_install_static_routes == true {
        file { "/etc/sysconfig/network-scripts/route-${ganglia_iface}":
            content => template("ganglia/etc/sysconfig/network-scripts/route"),
        }
    }

    service { "gmond":
        require => Package["ganglia-gmond"],
    }

    package { [ "ganglia-gmond", "ganglia-gmond-modules-python" ]: }

    file { "/etc/ganglia/conf.d/tcpconn.pyconf":
        content => template("ganglia/etc/ganglia/conf.d/tcpconn.pyconf"),
        require => Package["ganglia-gmond-modules-python"],
    }

    # FIXME: added local package
    # - ganglia-gmond-modules-python-apache-status
    # - ganglia-gmond-modules-python-memcached
    # - ganglia-gmond-modules-python-mysqld
    # - ganglia-gmond-modules-python-multi_traffic
    # and more
}

