#
#  nagios_nrpe module
#

class nagios_nrpe {
    if $nagios_nrpe_include == "" {
        $nagios_nrpe_include = ""
    }
    if $nagios_nrpe_include_dir == "" {
        $nagios_nrpe_include_dir = "/etc/nrpe.d"
    }

    file { $nagios_nrpe_include_dir:
        ensure  => directory,
        mode    => 755,
        require => Package["nrpe"],
    }

    file { "/etc/nagios/nrpe.cfg":
        content => template("nagios_nrpe/etc/nagios/nrpe.cfg"),
        notify  => Service["nrpe"],
        require => [ Package["nrpe"], File[$nagios_nrpe_include_dir] ],
    }

    package { [ "nagios-plugins", "nagios-plugins-nrpe", "nrpe" ]: }

    service { "nrpe":
        require => Package["nrpe"],
    }

    user { "nrpe":
        gid     => "nrpe",
        home    => "/",
        shell   => "/sbin/nologin",
        require => [ Package["nrpe"], Group["nrpe"], ],
    }

    group { "nrpe":
        require => Package["nrpe"],
    }


    define install_conf($module = "nagios_nrpe", $template = false, $is_plugin = true, $nagios_plugins = "") {
        if $nagios_nrpe_dir == "" {
            $nagios_nrpe_dir = "/etc/nrpe.d"
        }

        # configuration file
        if $template == false {
            file { "${nagios_nrpe_dir}/${name}.cfg":
                source => "puppet:///${module}${nagios_nrpe_dir}/${name}.cfg",
                notify => Service["nrpe"],
            }
        } else {
            file { "${nagios_nrpe_dir}/${name}.cfg":
                content => template("${module}${nagios_nrpe_dir}/${name}.cfg"),
                notify  => Service["nrpe"],
            }
        }

        # plugin
        if $is_plugin == true {
            file { "/usr/lib64/nagios/plugins/${name}":
                mode   => 755,
                source => "puppet:///${module}/usr/lib64/nagios/plugins/${name}",
                before => File["${nagios_nrpe_dir}/$name.cfg"],
            }
        }

        # nagios-plugins
        if $nagios_plugins != "" {
            package { $nagios_plugins:
                before => Service["nrpe"],
            }
        }
    }

    define install_disk_conf($nagios_nrpe_disk_warning = "1%", $nagios_nrpe_disk_critical = "1%", $nagios_nrpe_disk_part = "/") {
        install_conf { "check_disk":
            template       => true,
            is_plugin      => false,
            nagios_plugins => "nagios-plugins-disk",
        }
    }

    define install_load_conf() {
        if $nagios_nrpe_load1_warning == "" {
            $nagios_nrpe_load1_warning = $processorcount * 3
        }
        if $nagios_nrpe_load5_warning == "" {
            $nagios_nrpe_load5_warning = $processorcount * 2
        }
        if $nagios_nrpe_load15_warning == "" {
            $nagios_nrpe_load15_warning = $processorcount * 1
        }
        if $nagios_nrpe_load1_critical == "" {
            $nagios_nrpe_load1_critical = $processorcount * 4
        }
        if $nagios_nrpe_load5_critical == "" {
            $nagios_nrpe_load5_critical = $processorcount * 3
        }
        if $nagios_nrpe_load15_critical == "" {
            $nagios_nrpe_load15_critical = $processorcount * 2
        }

        install_conf { "check_load":
            template       => true,
            is_plugin      => false,
            nagios_plugins => "nagios-plugins-load",
        }
    }

    define install_procs_conf($nagios_nrpe_zombie_procs_warning = 2, $nagios_nrpe_zombie_procs_critical = 4, $nagios_nrpe_zombie_nrpe_procs_state = "Z", $nagios_nrpe_total_procs_warning = 300, $nagios_nrpe_total_procs_critical = 400) {
        install_conf {
            "check_zombie_procs":
                template => true,
                is_plugin      => false;
            "check_total_procs":
                template => true,
                is_plugin      => false;
        }

        package { "nagios-plugins-procs":
            before => [ File["/etc/nrpe.d/check_zombie_procs.cfg"], File["/etc/nrpe.d/check_total_procs.cfg"] ],
        }
    }

    define install_swap_conf($nagios_nrpe_swap_warning = "20%", $nagios_nrpe_swap_critical = "10%") {
        install_conf { "check_swap":
            template       => true,
            is_plugin      => false,
            nagios_plugins => "nagios-plugins-swap",
        }
    }

    define install_hadoop_conf($hadoop_dfs_warning, $hadoop_dfs_critical) {
        if $nagios_nrpe_dir == "" {
            $nagios_nrpe_dir = "/etc/nrpe.d"
        }

        # configuration file
        file { "${nagios_nrpe_dir}/check_hadoop-dfs.cfg":
            content => template("nagios_nrpe/${nagios_nrpe_dir}/check_hadoop-dfs.cfg"),
            notify  => Service["nrpe"],
        }

        # plugin
        file { "/usr/lib64/nagios/plugins/check_hadoop-dfs.sh":
            mode    => 755,
            source  => "puppet:///nagios_nrpe/usr/lib64/nagios/plugins/check_hadoop-dfs.sh",
            before  => File["/etc/nrpe.d/check_hadoop-dfs.cfg"],
            require => File["/usr/sbin/get-dfsreport.sh"],
        }

        file { "/usr/sbin/get-dfsreport.sh":
            mode   => 700,
            source => "puppet:///nagios_nrpe/usr/sbin/get-dfsreport.sh",
        }
    }
}
