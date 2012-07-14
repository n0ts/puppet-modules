#
# snmp module
#

class snmp {
    if $snmp_network_addr == "" {
        $snmp_network_addr = $network_eth0
    }
    if $snmp_disk == "" {
        $snmp_disk = ["/"]
    }
    if $snmp_exec == "" {
        $snmp_exec = []
    }
    if $snmp_extend == "" {
        $snmp_extend = []
    }
    if $snmp_log_facility == "" {
        $snmp_log_facility = "6"
    }

    file { "/etc/snmp/snmpd.conf":
        content => template("snmp/etc/snmp/snmpd.conf"),
        require => Package["net-snmp"],
        notify  => Service["snmpd"],
    }

    if $manufacturer == "HP" {
        File["/etc/snmp/snmpd.conf"] {
            before +> Package["hp-snmp-agents"],
        }
    }

    file { "/etc/sysconfig/snmpd.options":
        content => template("snmp/etc/sysconfig/snmpd.options"),
        require => Package["net-snmp"],
        notify  => Service["snmpd"],
    }

    file { "/etc/logrotate.d/snmpd":
        source  => "puppet:///snmp/etc/logrotate.d/snmpd",
        require => Package["net-snmp"],
    }

    service { "snmpd":
        require => Package["net-snmp"],
    }

    package { "net-snmp": }
}
