#
# ganglia_server module
#

class ganglia::server {
    if $ganglia_grid_name == "" {
        $ganglia_grid_name = "Unspecified"
    }
    if $ganglia_web_package == "" {
        $ganglia_web_package = "ganglia-web"
    }
    if $ganglia_use_gmetad_conf == "" {
        $ganglia_use_gmetad_conf = true
    }

    if $ganglia_use_gmetad_conf == true {
        file { "/etc/ganglia/gmetad.conf":
            content => template("ganglia/etc/ganglia/gmetad.conf"),
            notify  => Service["gmetad"],
        }
    }

    service { "gmetad":
        require => Package["ganglia-gmetad"],
    }

    package { ["ganglia-gmetad", $ganglia_web_package]: }
    if $ganglia_web_package == "gweb" {
        Package[$ganglia_web_package] {
            require +> Package["php-pecl-json"],
        }
        package{ "php-pecl-json": }
    }


    define install_gmetad_conf() {
        file { "/etc/ganglia/gmetad.conf":
            source => "puppet:///${name}/etc/ganglia/gmetad.conf",
            notify => Service["gmetad"],
        }
    }

    define install_script($module = "ganglia") {
        file { "/var/www/html/ganglia/${name}":
            source => "puppet:///${module}/var/www/html/ganglia/${name}",
        }
    }

    define install_templates_dir() {
        file { "/var/www/html/ganglia/templates/${name}":
            ensure => directory,
            mode   => 755,
        }
    }

    define install_templates($module = "ganglia") {
        file { "/var/www/html/ganglia/templates/${name}":
            source => "puppet:///${module}/var/www/html/ganglia/templates/${name}",
        }
    }
}
