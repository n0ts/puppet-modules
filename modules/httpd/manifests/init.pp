#
# httpd module
#

$httpd_mpm = "perfork"

class httpd {
    case $httpd_mpm {
        "worker": {
            file { "/etc/sysconfig/httpd":
                mode => 644,
                source => "puppet:///httpd/etc/sysconfig/httpd",
                notify => Exec["httpd_restart"],
            }
        }
    }

    exec { "httpd_restart":
        command => "httpd condrestart",
        refreshonly => true,
    }

    file { "/etc/httpd/conf/httpd.conf":
        source => "puppet:///httpd/etc/httpd/conf/httpd.conf",
    }

    file  { "/var/www/html/index.html":
        content => template("httpd/var/www/html/index.html"),
    }

    file { "/etc/httpd/conf.d-local":
        ensure => directory,
        mode => 755,
    }

    do_conf { [ "ssl.conf" ]: }
    do_global_local_conf { [ "AA_local.conf" ]: }

    service { "httpd":
        subscribe => File["/etc/httpd/conf/httpd.conf"],
        require => Package["httpd"],
    }

    $packagelist = [ "httpd", "mod_ssl" ]
    package { $packagelist: }


    define do_conf() {
        file { "/etc/httpd/conf.d/${name}":
            source => "puppet:///httpd/etc/httpd/conf.d/${name}",
            before => Service["httpd"],
            notify => Service["httpd"],
        }
    }

    define do_local_conf() {
        file { "/etc/httpd/conf.d-local/${name}":
            source => "puppet:///httpd/etc/httpd/conf.d-local/${name}",
            before => Service["httpd"],
            notify => Service["httpd"],
        }
    }

    define do_global_local_conf() {
        file { "/etc/httpd/conf.d-local/${name}":
            source => "puppet:///${global_name}/etc/httpd/conf.d-local/${name}",
            before => Service["httpd"],
            notify => Service["httpd"],
        }
    }
}
