#
# mailman module
#

class mailman {
    include httpd

    package { "mailman": }

    $servicelist = [ "mailman" ]
    service { $servicelist: }

 
    define do_global_conf() {
        file { "/usr/lib/mailman/Mailman/mm_cfg.py":
            group  => mailman,
            source => "puppet:///${global_name}/usr/lib/mailman/Mailman/mm_cfg.py",
            notify => Exec["genaliases-${name}"],
        }

        exec { "genaliases-${name}":
            command => "/usr/lib/mailman/bin/genaliases",
            refreshonly => true,
            notify => Exec["aliases-db-${name}"],
        }

        exec { "aliases-db-${name}":
            command => "chmod g+w /etc/mailman/aliases.db",
            refreshonly => true,
            notify => Exec["newlist-mailman-${name}"],
        }

        exec { "newlist-mailman-${name}":
            command => "/usr/lib/mailman/bin/newlist mailman",
            refreshonly => true,
            notify => Exec["mmsitepass-${name}"],
        }

        exec { "mmsitepass-${name}":
            command => "/usr/lib/mailman/bin/mmsitepass mailman",
            refreshonly => true,
            notify => Service["mailman"],
        }
    }
}
