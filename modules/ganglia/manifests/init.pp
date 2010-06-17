#
# ganglia module
#

class ganglia_server {
    $cluster_name = $global_service_name

    file { "/etc/gmetad.conf":
        content => template("ganglia/etc/gmetad.conf"),
     }

    service { "gmetad":
        subscribe => File["/etc/gmetad.conf"],
        require   => Package["ganglia-gmetad"],
    }

    $packagelist = ["php-gd", "ganglia-gmetad", "ganglia-web"]
    package { $packagelist: }


    define do_global_templates() {
        file { "/var/www/html/ganglia/templates/${global_name}/${name}":
            source => "puppet:///${global_name}/var/www/html/ganglia/templates/${global_name}/${name}",
        }
    }

    define do_global_templates_dir() {
        file { "/var/www/html/ganglia/templates/${global_name}":
            ensure => directory,
            mode => 755,
        }
    }

    define do_global_templates_images() {
        file { "/var/www/html/ganglia/templates/${global_name}/images/${name}":
            source => "puppet:///${global_name}/var/www/html/ganglia/templates/${global_name}/images/${name}",
        }
    }

    define do_global_templates_images_dir() {
        file { "/var/www/html/ganglia/templates/${global_name}/images":
            ensure => directory,
            mode => 755,
        }
    }
}

class ganglia_client {
    $cluster_name = $global_service_name
    $cluster_url = "http://${global_domain}"

    file { "/etc/sysconfig/static-routes":
        source => "puppet:///ganglia/etc/sysconfig/static-routes",
        notify => [ Exec["network_reload"], Exec["iptables_condrestart"] ],
    }

    exec { "network_reload":
        command => "/etc/init.d/network reload",
        refreshonly => true,
    }

    exec { "iptables_condrestart":
        command => "/etc/init.d/iptables condrestart",
        refreshonly => true,
    }

    file { "/etc/gmond.conf":
        content => template("ganglia/etc/gmond.conf"),
     }

    service { "gmond":
        subscribe => File["/etc/gmond.conf"],
        require   => Package["ganglia-gmond"],
    }

    package { "ganglia-gmond": }
}
