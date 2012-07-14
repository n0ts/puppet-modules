#
# ngircd module
#

class ngircd {
    file { "/etc/init.d/ngircd":
        mode   => 755,
        source => "puppet:///ngircd/etc/init.d/ngircd",
    }

    file { "/var/run/ngircd":
        ensure => directory,
        mode   => 755,
        owner  => nobody,
        group  => nobody,
    }

    package { "ngircd": }

    service { "ngircd":
        require => [ Package["ngircd"], File["/etc/init.d/ngircd"], File["/var/run/ngircd"] ],
    }


    define install_conf($module = "ngircd") {
        file { $name:
            mode   => 600,
            source => "puppet:///${module}/${name}",
            notify => Service["ngircd"],
        }
    }
}
