#
# postfix module
#

class postfix {
    if $postfix_myhostname == "" {
        $postfix_myhostname = $fqdn
    }
    if $postfix_mydomain == "" {
        $postfix_mydomain = $domain
    }
    if $postfix_alias_maps == "" {
        $postfix_alias_maps = "hash:/etc/aliases"
    }
    if $postfix_root_alias == "" {
        $postfix_root_alias = ""
    }
    if $postfix_users_alias == "" {
        $postfix_users_alias = ""
    }
    if $postfix_smtp_helo_name == "" {
        $postfix_smtp_helo_name = $domain
    }
    if $postfix_ignore_received_header == "" {
        $postfix_ignore_received_header = ""
    }

    file { "/etc/postfix/main.cf":
        content => template("postfix/etc/postfix/main.cf"),
        require => Package["postfix"],
    }

    file { "/etc/postfix/header_checks":
        content => template("postfix/etc/postfix/header_checks"),
        require => Package["postfix"],
    }

    mailalias { "root":
        recipient => $postfix_root_alias,
        notify    => Exec["postfix-newaliases"],
    }

    exec { "postfix-newaliases":
        command     => "newaliases",
        refreshonly => true,
    }

    install_postmap { [ "transport", "virtual" ]: }

    service { "postfix":
        subscribe => File["/etc/postfix/main.cf"],
        require   => Package["postfix"],
    }

    package { "postfix": }


    define install_postmap() {
        file { "/etc/postfix/${name}":
            source  => "puppet:///postfix/etc/postfix/${name}",
            require => Package["postfix"],
        }

        exec { "postmap-${name}":
            command     => "postmap /etc/postfix/${name}",
            refreshonly => true,
            subscribe   => File["/etc/postfix/${name}"],
            notify      => Service["postfix"],
        }
    }

    define alias($recipient) {
        mailalias { $name:
            recipient => $recipient,
            notify    => Exec["postfix-newaliases"],
        }
    }
}
