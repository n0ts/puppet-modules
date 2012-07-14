#
# mailman module
#

class mailman {
    include httpd

    package { "mailman": }

    service { "mailman":
        require => Package["mailman"],
    }


    define install_conf($module = "mailman") {
        file { "/usr/lib/mailman/Mailman/mm_cfg.py":
            group   => mailman,
            source  => "puppet:///${module}/usr/lib/mailman/Mailman/mm_cfg.py",
            notify  => Exec["genaliases-${name}"],
            require => Package["mailman"],
        }

        exec { "genaliases-${name}":
            command     => "/usr/lib/mailman/bin/genaliases",
            refreshonly => true,
            notify      => Exec["aliases-db-${name}"],
        }

        exec { "aliases-db-${name}":
            command     => "chmod g+w /etc/mailman/aliases.db",
            refreshonly => true,
            notify      => Exec["newlist-mailman-${name}"],
        }

        exec { "newlist-mailman-${name}":
            command     => "/usr/lib/mailman/bin/newlist mailman",
            refreshonly => true,
            notify      => Exec["mmsitepass-${name}"],
        }

        exec { "mmsitepass-${name}":
            command     => "/usr/lib/mailman/bin/mmsitepass mailman",
            refreshonly => true,
            notify      => Service["mailman"],
        }
    }
}
