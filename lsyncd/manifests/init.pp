#
# lsyncd module
#

class lsyncd {
    if $lsyncd_inotify_mode == "" {
        $lsyncd_inotify_mode = "CloseWrite"
    }
    if $lsyncd_user == "" {
        $lsyncd_user = $user
    }
    if $lsyncd_conf_file == "" {
        $lsyncd_conf_file = "/etc/lsyncd-rsyncssh.conf"
    }
    if $lsyncd_pid_file == "" {
        $lsyncd_pid_file = "/var/run/lsyncd.pid"
    }
    if $lsyncd_log_file == "" {
        $lsyncd_log_file = "/var/log/lsyncd.log"
    }
    if $lsyncd_service == "" {
        $lsyncd_service = "sysinit"
    }
    if $lsyncd_status_file == "" {
        $lsyncd_status_file = "/var/run/lsyncd.stat"
    }
    if $lsyncd_status_interval == "" {
        $lsyncd_status_interval = "1"
    }
    if $lsyncd_max_delays == "" {
        $lsyncd_max_delays = "1"
    }
    if $lsyncd_max_processes == "" {
        $lsyncd_max_processes = $processorcount
    }
    if $lsyncd_rsync_opts == "" {
        $lsyncd_rsync_opts = "-ltus"
    }
    if $lsyncd_exclude_from  == "" {
        $lsyncd_exclude_from = ""
    }
    if $lsyncd_delete == "" {
        $lsyncd_delete = false
    }
    if $lsyncd_sync_servers == "" {
        $lsyncd_sync_servers = []
    }
    if $lsyncd_sync_source == "" {
        $lsyncd_sync_source = ""
    }
    if $lsyncd_sync_targetdir == "" {
        $lsyncd_sync_targetdir = ""
    }

    file { $lsyncd_conf_file:
        content => template("lsyncd/${lsyncd_conf_file}"),
    }

    file { "/etc/logrotate.d/lsyncd":
        content => template("lsyncd/etc/logrotate.d/lsyncd"),
    }

    file { "/etc/sysconfig/lsyncd":
        content => template("lsyncd/etc/sysconfig/lsyncd"),
        require => Package["lsyncd"],
    }

    case $lsyncd_service {
        "sysinit": {
            service { "lsyncd":
                require => [ File[$lsyncd_conf_file], Package["lsyncd"] ],
            }
        }
        "daemontools": {
            service { "lsyncd":
                enable  => false,
                require => Package["lsyncd"],
            }

            include daemontools
            daemontools::install_service {
                "lsyncd":
                    module   => "lsyncd",
                    template => true,
            }
        }
    }

    package { "lsyncd": }
}
