#
# nagios module
#

class nagios {
    if $nagios_user_authentication == "" {
        $nagios_user_authentication = 1
    }
    if $nagios_default_user_name == "" {
        $nagios_default_user_name = "guest"
    }
    if $nagios_cfg_dirs == "" {
        $nagios_cfg_dirs = []
    }
    if $nagios_interval_length == "" {
        $nagios_interval_length = "60"
    }
    if $nagios_service_check_timeout == "" {
        $nagios_service_check_timeout = "60"
    }
    if $nagios_process_performance_data == "" {
        $nagios_process_performance_data = "0"
    }
    if $nagios_admin_email == "" {
        $nagios_admin_email = "nagios@localhost"
    }
    if $nagios_admin_pager == "" {
        $nagios_admin_pager = "pagenagios@localhost"
    }
    if $nagios_plugins_all == "" {
        $nagios_plugins_all = "nagios-plugins-all"
    }

    file { "/etc/nagios/nagios.cfg":
        content => template("nagios/etc/nagios/nagios.cfg"),
        notify  => Service["nagios"],
        require => Package["nagios"],
    }

    file { "/etc/nagios/cgi.cfg":
        content => template("nagios/etc/nagios/cgi.cfg"),
        notify  => Service["nagios"],
        require => Package["nagios"],
    }

    service { "nagios":
        require => Package["nagios"],
    }

    package { [ "nagios", $nagios_plugins_all ]: }


    define install_local_conf_dir() {
        file { "/etc/nagios/${name}":
            group   => "nagios",
            ensure  => directory,
            mode    => 750,
            require => Package["nagios"],
        }
    }

    define install_local_conf($is_template = false, $module = "nagios", $dir = "local") {
       file { "/etc/nagios/${dir}/${name}":
            notify  => Service["nagios"],
            require => [ Package["nagios"], File["/etc/nagios/${dir}"] ],
        }

        if $is_template == false {
            File["/etc/nagios/${dir}/${name}"] {
                source +> "puppet:///${module}/etc/nagios/${dir}/${name}",
            }
        }
        else {
            File["/etc/nagios/${dir}/${name}"] {
                content +> template("${module}/etc/nagios/${dir}/${name}"),
            }
        }
    }

    define install_host_service($members, $host_use = "linux-server", $service_use_ping = "warn-service", $service_use_ssh = "warn-service", $service_use_disk = "warn-service", $service_use_load = "warn-service", $service_use_ntp = "warn-service", $dir = "local", $ntp_enable = false, $snmp_load_warn = "2,1,1", $snmp_load_crit = "4,2,2") {
        file { "/etc/nagios/${dir}/${name}.cfg":
            content => template("nagios/etc/nagios/host_service.cfg"),
            notify  => Service["nagios"],
            require => [ File["/etc/nagios/${dir}"], Package["nagios"] ],
        }
    }

    define install_template() {
        file { "/etc/nagios/${name}/_templates_${name}.cfg":
            content => template("nagios/etc/nagios/templates.cfg"),
            notify  => Service["nagios"],
            require => [ File["/etc/nagios/${name}"], Package["nagios"] ],
        }
    }

    define install_plugin($module = "nagios") {
        file { "/usr/lib64/nagios/plugins/${name}":
            mode    => 755,
            source  => "puppet:///${module}//usr/lib64/nagios/plugins/${name}",
            require => Package["nagios"],
        }
    }
}

