#
# postfix module
#

$postfix_hostname = ""
$postfix_mydoamin = ""
$postfix_alias_maps = ""
$postfix_root_alias = ""
$postfix_users_alias = ""
$postfix_smtp_helo_name = ""

class postfix {
    case $postfix_hostname {
        '': {
            $postfix_hostname = $fqdn
        }
    }
    case $postfix_mydomain {
        '': {
            $postfix_mydomain = $domain
        }
    }
    case $postfix_alias_maps {
        '': {
            $postfix_alias_maps = "hash:/etc/aliases"
        }
    }
    case $postfix_root_alias {
        '': {
            $postfix_root_alias = "root"
        }
    }

    file { "/etc/postfix/main.cf":
        content => template("postfix/etc/postfix/main.cf"),
        require => Package["postfix"],
    }

    file { "/etc/postfix/header_checks":
        content => template("postfix/etc/postfix/header_checks"),
        require => Package["postfix"],
    }

    file { "/etc/aliases":
        content => template("postfix/etc/aliases"),
    }

    exec { "newaliases":
        refreshonly => true,
        subscribe => File["/etc/aliases"],
    }

    do_postmap { [ "transport", "virtual" ]: }

    service { "postfix":
        subscribe => File["/etc/postfix/main.cf"],
        require => Package["postfix"],
    }

    package { "postfix": }


    define do_postmap() {
        file { "/etc/postfix/${name}":
            owner => "root",
            group => "root",
            mode => 644,
            source => "puppet:///postfix/etc/postfix/${name}",
            require => Package["postfix"],
        }

        exec { "postmap-${name}":
            command => "postmap /etc/postfix/${name}",
            refreshonly => true,
            subscribe => File["/etc/postfix/${name}"],
            notify => Service["postfix"],
            before => Service["postfix"],
        }
    }
}
