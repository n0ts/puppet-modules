#
# daemontools module
#

class daemontools {
    service { "svscan":
        require => Package["daemontools"],
    }

    package { "daemontools": }


    define install_service($module, $template = false, $is_log = true) {
        file { "/service/${name}":
            ensure  => directory,
            require => Package["daemontools"],
        }

        file { "/service/${name}/run":
            mode    => 755,
            notify  => Exec["daemontools-start-${name}"],
            require => File["/service/${name}"],
        }
        if $template == false {
            File["/service/${name}/run"] {
                source +> "puppet:///${module}/service/${name}/run",
            }
        }
        else {
            File["/service/${name}/run"] {
                content +> template("${module}/service/${name}/run"),
            }
        }

        if $is_log == true {
            file { "/service/${name}/log":
                ensure  => directory,
                require => File["/service/${name}"],
            }

            file { "/service/${name}/log/run":
                mode    => 755,
                notify  => Exec["daemontools-start-${name}"],
                require => File["/service/${name}/log"],
            }
            if $template == false {
                File["/service/${name}/log/run"] {
                    source +> "puppet:///${module}/service/${name}/log/run",
                }
            }
            else {
                File["/service/${name}/log/run"] {
                    content +> template("${module}/service/${name}/log/run"),
                }
            }
        }

        exec { "daemontools-start-${name}":
            command     => "svc -u /service/${name}",
            refreshonly => true,
        }
    }

    define terminate() {
        exec { "daemontools-terminate-${name}":
            command => "svc -t /service/${name}",
            require => [ File["/service/${name}"], Package["daemontools"] ],
        }
    }
}
