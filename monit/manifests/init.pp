#
# monit module
#

class monit {
    file { "/etc/monit.d":
        ensure => directory,
        mode   => 700,
    }

    install_conf { "dummy": }

    if $monit_daemon == "" {
        $monit_daemon = 60
    }

    if $monit_logfile == "" {
        $monit_logfile = "/var/log/monit"
    }
    $monit_logrotate_logfile = "/var/log/monit"

    if $monit_mailserver == "" {
        $monit_mailserver = "localhost"
    }

    $monit_package = $monit_version ? {
        ""      => "monit",
        default => "monit-${monit_version}",
    }

    file { "/etc/monitrc":
        mode    => 600,
        content => template("monit/etc/monitrc"),
        require => Package[$monit_package],
    }

    file { "/etc/logrotate.d/monit":
        content => template("monit/etc/logrotate.d/monit"),
        require => Package[$monit_package],
    }

    service { "monit":
        subscribe => [ File["/etc/monit.d/dummy"], File["/etc/monitrc"] ],
        require   => Package[$monit_package],
    }

    package { $monit_package: }


    define install_conf($module = "monit", $template = false) {
        $monit_package = $monit_version ? {
            ""      => "monit",
            default => "monit-${monit_version}",
        }

        file { "/etc/monit.d/${name}":
            mode    => 600,
            require => Package[$monit_package],
            notify  => Service["monit"],
        }

        if $template == false {
            File["/etc/monit.d/${name}"] {
                source +> "puppet:///${module}/etc/monit.d/${name}",
            }
        } else {
            File["/etc/monit.d/${name}"] {
                content +> template("${module}/etc/monit.d/${name}"),
            }
        }
    }
}
