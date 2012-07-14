#
# mysqld_multi module
#

class mysqld_multi {
    $mysql_use_mysqld_multi = true
    include mysql

    if $mysqld_multi_parameter == "" {
        $mysqld_multi_parameter = ""
    }

    if $mysqld_multi_parameter != "" {
        file { "/etc/my.cnf":
            content => template("mysqld_multi/etc/my.cnf"),
            replace => false,
        }
    }

    file { "/etc/init.d/mysqld_multi":
        mode   => 755,
        source => "puppet:///mysqld_multi/etc/init.d/mysqld_multi",
    }

    service { "mysqld_multi":
        pattern => "mysqld",
        require => [ File["/etc/my.cnf"], File["/etc/init.d/mysqld_multi"] ],
    }

    service { "mysql":
        enable => false,
        ensure => stopped,
        notify => File["/etc/init.d/mysql"],
    }

    file { "/etc/init.d/mysql":
        ensure => absent,
    }


    #
    # install database
    #
    define install_database() {
        exec { "mysqld_multi-install_databas-${name}":
            command => "/usr/bin/mysql_install_db --user=mysql --datadir=/var/lib/mysql/${name}",
            require => File["/var/lib/mysql/${name}"],
            unless  => "test -d /var/lib/mysql/${name}/mysql",
        }
    }


    #
    # setup logrotate for mysqld_multi
    #
    define setup_logrotate($mysql_log = "/var/lib/mysql/mysqld.log /var/lib/mysql/mysql-slow.log /var/lib/mysql/mysqld-slow.log", $mysql_slowlog = "/var/log/mysqld-slow.log", $mysql_logrorate_slowlog = false, $mysql_logrotate_slowlog_mailto = "", $mysql_socket = "") {

        file { "/etc/logrotate.d/${name}":
            content => template("mysqld_multi/etc/logrotate.d/mysqld"),
        }
    }
}
