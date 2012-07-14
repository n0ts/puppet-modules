#
# lvs module
#

class lvs {
    if $lvs_vip == "" {
        $lvs_vip = ""
    }
    if $lvs_ip_conntrack_max == "" {
        $lvs_ip_conntrack_max = 0
    }
    if $lvs_ip_conntrack_tcp_timeout_established == "" {
        $lvs_ip_conntrack_tcp_timeout_established = 0
    }
    if $lvs_enable_notification_email == "" {
        $lvs_enable_notification_email = false
    }
    if $lvs_keepalived_service == "" {
        $lvs_keepalived_service = "sysinit"
    }
    if $lvs_internal_only == "" {
        $lvs_internal_only = false
    }
    if $lvs_internal_interface == "" {
        $lvs_internal_interface = "eth0"
    }

    #
    # device lo ip rules
    #
    file { "/etc/sysconfig/network-scripts/ifup-local":
        mode   => 700,
        source => "puppet:///lvs/etc/sysconfig/network-scripts/ifup-local",
        notify => Exec["ifup-local-exec"],
    }

    file { "/sbin/ifup-local":
        ensure => link,
        target => "/etc/sysconfig/network-scripts/ifup-local",
    }

    file { "/etc/sysconfig/network-scripts/ifdown-local":
        mode   => 700,
        source => "puppet:///lvs/etc/sysconfig/network-scripts/ifdown-local",
    }

    file { "/sbin/ifdown-local":
        ensure => link,
        target => "/etc/sysconfig/network-scripts/ifdown-local",
    }

    exec { "ifup-local-exec":
        command     => "/etc/sysconfig/network-scripts/ifup-local lo",
        refreshonly => true,
    }


    #
    # sysctl settings
    #
    exec { "net.ipv4.ip_forward":
        command => "sed -i 's/net.ipv4.ip_forward \= 0/net.ipv4.ip_forward \= 1/' /etc/sysctl.conf",
        unless  => "test `cat /proc/sys/net/ipv4/ip_forward` = 1",
        notify  => Exec["net.ipv4.conf.eth0.rp_filter"],
    }

    exec { "net.ipv4.conf.eth0.rp_filter":
        command     => "echo \"\n# Controls source route verification for eth0\nnet.ipv4.conf.eth0.rp_filter = 0\" >> /etc/sysctl.conf",
        unless      => "grep net.ipv4.conf.eth0.rp_filter /etc/sysctl.conf",
        refreshonly => true,
        notify      => Exec["lvs-load-sysctl-settings"],
    }

    # Maximum number of conntrack, 65536 per 1GB RAM (8GB RAM: 524288)
    if $lvs_ip_conntrack_max != 0 {
        exec { "net.ipv4.netfilter.ip_conntrack_max":
            command     => "echo \"\n# Maximum number of conntrack\nnet.ipv4.netfilter.ip_conntrack_max = ${lvs_ip_conntrack_max}\" >> /etc/sysctl.conf",
            unless      => "grep net.ipv4.netfilter.ip_conntrack_max /etc/sysctl.conf",
            notify      => Exec["lvs-load-sysctl-settings"],
        }
    }

    # Timeout of conntrack for Estacblish Tcp Connection
    if $lvs_ip_conntrack_tcp_timeout_established != 0 {
        exec { "net.ipv4.netfilter.ip_conntrack_tcp_timeout_established":
            command     => "echo \"\n# Timeout of conntrack for Estacblish Tcp Connection\nip_conntrack_tcp_timeout_established = ${lvs_ip_conntrack_tcp_timeout_established}\" >> /etc/sysctl.conf",
            unless      => "grep net.ipv4.netfilter.ip_conntrack_max /etc/sysctl.conf",
            notify      => Exec["lvs-load-sysctl-settings"],
            refreshonly => true,
        }
    }

    exec { "lvs-load-sysctl-settings":
        command     => "sysctl -p",
        refreshonly => true,
    }

    #
    # keepalived
    #
    file { "/etc/keepalived/keepalived.conf":
        content => template("lvs/etc/keepalived/keepalived.conf"),
        require => Package["keepalived"],
    }

    file { "/etc/keepalived/conf.d":
        ensure  => directory,
        mode    => 600,
        require => Package["keepalived"],
    }

    if $lvs_internal_only == false {
        file { "/etc/keepalived/vrrp_master.sh":
            mode    => 700,
            content => template("lvs/etc/keepalived/vrrp_master.sh"),
            require => [ Package["keepalived"], Package["garp"] ],
        }

        file { "/etc/keepalived/vrrp_backup.sh":
            mode    => 700,
            content => template("lvs/etc/keepalived/vrrp_backup.sh"),
            require => Package["keepalived"],
        }
    }

    file { "/etc/keepalived/vrrp_state.sh":
        mode    => 700,
        source  => "puppet:///lvs/etc/keepalived/vrrp_state.sh",
        require => Package["keepalived"]
    }

    case $lvs_keepalived_service {
        "sysinit": {
            service { "keepalived":
                require => Package["keepalived"],
            }
        }
        "daemontools": {
            service { "keepalived":
                enable  => false,
                require => Package["keepalived"],
            }

            include daemontools
            daemontools::install_service {
                "keepalived-vrrp":
                    module => "lvs",
                    is_log => false;
                "keepalived-check":
                    module => "lvs",
                    is_log => false;
            }
        }
    }

    package { ["ipvsadm", "keepalived", "garp"]: }


    define install_keepalived_tcp_check($lvs_servers, $lvs_vip, $lvs_vip_port, $lvs_delay_loop = "5", $lvs_sched = "wrr", $lvs_method = "dr", $lvs_protocol = "tcp", $lvs_connect_timeout = "5") {
        file { "/etc/keepalived/conf.d/${name}.conf":
            mode     => 600,
            content  => template("lvs/etc/keepalived/conf.d/tcp_check.conf"),
            require  => File["/etc/keepalived/conf.d"],
        }
    }

    define install_keepalived_http_get($lvs_servers, $lvs_vip, $lvs_vip_port = "80", $lvs_delay_loop = "5", $lvs_sched = "wrr", $lvs_method = "dr", $lvs_protocol = "tcp", $lvs_virtualhost = "status.${domain}", $lvs_http_get_url = "/", $lvs_connect_timeout = "5") {
        file { "/etc/keepalived/conf.d/${name}.conf":
            mode     => 600,
            content  => template("lvs/etc/keepalived/conf.d/http_get.conf"),
            require  => File["/etc/keepalived/conf.d"],
        }
    }

    define install_keepalived_ssl_get($lvs_servers, $lvs_vip, $lvs_vip_port = "443", $lvs_delay_loop = "5", $lvs_sched = "wrr", $lvs_method = "dr", $lvs_protocol = "tcp", $lvs_virtualhost = "status.${domain}", $lvs_ssl_get_url = "/", $lvs_connect_port = "443", $lvs_connect_timeout = "5") {
        file { "/etc/keepalived/conf.d/${name}.conf":
            mode     => 600,
            content  => template("lvs/etc/keepalived/conf.d/ssl_get.conf"),
            require  => File["/etc/keepalived/conf.d"],
        }
    }

    define install_keepalived_vrrp($lvs_vi_vrid, $lvs_vi_ipaddress, $lvs_vi_interface = "eth0", $lvs_ve_interface = "eth1", $lvs_vrrp_ve = false, $lvs_ve_ipaddress = []) {
        file { "/etc/keepalived/conf.d/${name}.conf":
            mode     => 600,
            content  => template("lvs/etc/keepalived/conf.d/vrrp.conf"),
            require  => File["/etc/keepalived/conf.d"],
        }
    }

    define install_keepalived_conf($module = "lvs") {
        file { "/etc/keepalived/${name}":
            mode    => 600,
            source  => "puppet:///${module}/etc/keepalived/${name}",
            require => Package["keepalived"],
        }
    }

    define install_keepalived_confd($template = false, $module = "lvs") {
        file { "/etc/keepalived/conf.d/${name}":
            mode    => 600,
            require => File["/etc/keepalived/conf.d"],
        }

        if $template == false {
            File["/etc/keepalived/conf.d/${name}"] {
                source +> "puppet:///${module}/etc/keepalived/conf.d/${name}",
            }
        }
        else {
            File["/etc/keepalived/conf.d/${name}"] {
                content +> template("${module}/etc/keepalived/conf.d/${name}"),
            }
        }
    }
}
