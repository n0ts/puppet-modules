#
# mysql module
#

$mysql_server_type = "slave"
$mysql_binlog_do_db = ""
$mysql_master_ipaddr = ""
$mysql_repl_user = ""
$mysql_repl_password = ""
$mysql_repl_limited_host = ""
$mysql_repl_sqlfile = ""

class mysql {
    $server_type = $mysql_server_type
    case $server_type {
        master: {
            $binlog_do_db = $mysql_binlog_do_db
        }
    }

    file { "/etc/my.cnf":
        content => template("mysql/etc/my.cnf"),
        require => Package["mysql-server"],
    }

    service { "mysqld":
        require   => Package["mysql-server"],
        subscribe => File["/etc/my.cnf"],
    }

    package { "mysql-server": }


    #
    # Setup slave server
    #
    # $name: database name
    # $root_password: root password
    # $repl_user_name: replication user name
    # $repl_user_password: replication user password
    # $master_host: master host name
    # $master_log: master log file
    # $master_pos: master log position
    #
    define do_slave($root_password = "",
                       $repl_user_name, $repl_user_password,
                       $master_host, $master_log, $master_pos) {
        case $root_password {
            "":      { $cmd_root_password = "" }
            default: { $cmd_root_password = "-p${root_password}" }
        }

        $sqlfile = "${name}_mysql-bin.${master_log}_${master_pos}.sql"

        file { "/tmp/${sqlfile}":
            source => "puppet:///${global_name}/tmp/${sqlfile}",
        }

        exec { "mysqldump-${name}":
            command => "mysql -u root ${cmd_root_password} ${name} < /tmp/${sqlfile}",
            unless  => "test -f /var/lib/mysql/master.info",
            notify  => Exec["wait_change_master_to-${name}"],
        }

        exec { "wait_change_master_to-${name}":
            command     => "sleep 3",
            refreshonly => true,
            notify      => Exec["change_master_to-${name}"],
        }

        exec { "change_master_to-${name}":
            command     => "mysql -u root -e 'CHANGE MASTER TO MASTER_HOST=\"${master_host}\", master_user=\"${repl_user_name}\", master_password=\"${repl_user_password}\", master_log_file=\"mysql-bin.${master_log}\", master_log_pos=${master_pos}'",
            notify      => Exec["start_slave-${name}"],
            refreshonly => true,
        }

        exec { "start_slave-${name}":
            command     => "mysql -u root -e 'START SLAVE'",
            refreshonly => true,
            require     => Service['mysqld'],
        }
    }

    #
    # set user password
    #
    # $name: user name
    # $password: user password
    #
    define set_user_password($password) {
        exec { "set_user_password-${name}":
            command => "mysqladmin -u${name} password ${password}",
            unless  => "mysqladmin -u${name} -p${password} status",
            require => Service['mysqld'],
        }
    }

    #
    # Create user
    #
    # $name: user name
    # $password: user password
    # $root_password: root password
    # $limited_host: limited host name
    # $priv_param: privileages parameter
    #  - replication: replication privilege
    #  - read: read only
    #  - write: write & read
    #  - "": all privileges
    # $database_name: database name
    #
    define create_user($password, $root_password = "", 
                       $limited_host = "localhost",
                       $priv_param = "read",
                       $database_name = "*") {
        case $root_password {
            "":      { $cmd_root_password = "" }
            default: { $cmd_root_password = "-p${root_password}" }
        }

        case $priv_param {
            "replication": { $priv_type = "replication slave" }
            "read":        { $priv_type = "select" }
            "write":       { $priv_type = "select,insert,update,drop,create,delete" }
            default:       { $priv_type = "all privieages" }
        }

        exec { "create_user-${name}":
            command => "mysql -uroot ${cmd_root_password} -e 'grant ${priv_type} on ${database_name}.* to ${name}@\"${limited_host}\" identified by \"${password}\"'",
            unless  => "mysqladmin -u${name} -p${password} -hlocalhost status",
            notify  => Exec["flush-${name}"],
            require => Service['mysqld'],
        }

        exec { "flush-${name}":
            command => "mysql -uroot ${cmd_root_password} -e 'flush privileges'",
            refreshonly => true,
        }
    }

    #
    # create database
    #
    # $name: database name
    # $root_password: root password
    #
    define create_database($root_password = "") {
        case $root_password {
            "":      { $cmd_root_password = "" }
            default: { $cmd_root_password = "-p${root_password}" }
        }

        exec { "create-database-${name}":
            command => "mysql -uroot ${cmd_root_password} -e 'CREATE DATABASE ${name}'",
            unless  => "mysql -uroot ${cmd_root_password} ${name} -e 'show tables'",
        }
    }
}
