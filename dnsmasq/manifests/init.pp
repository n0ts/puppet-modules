#
# dnsmasq module
#

class dnsmasq {
    if $dnsmasq_server == "" {
        $dnsmasq_server = ""
    }
    if $dnsmasq_interface == "" {
        $dnsmasq_interface = "eth0"
    }
    if $dnsmasq_listen_address == "" {
        $dnsmasq_listen_address = ""
    }
    if $dnsmasq_domain == "" {
        $dnsmasq_domain = $domain
    }
    if $dnsmasq_no_dhcp_interface == "" {
        $dnsmasq_no_dhcp_interface = true
    }
    if $dnsmasq_domain_needed == "" {
        $dnsmasq_domain_needed = true
    }
    if $dnsmasq_bogus_priv == "" {
        $dnsmasq_bogus_priv = true
    }
    if $dnsmasq_no_resolv == "" {
        $dnsmasq_no_resolv = false
    }

    file { "/etc/dnsmasq.conf":
        content => template("dnsmasq/etc/dnsmasq.conf"),
        notify  => Service["dnsmasq"],
    }

    service { "dnsmasq":
        require => Package["dnsmasq"],
    }

    package { "dnsmasq": }
}
