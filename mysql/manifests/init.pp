#
# mysql module
#

class mysql {
    $mysql_client_package = $mysql_version ? {
        ""      => "MySQL-client-community",
        default => "MySQL-client-community-${mysql_version}",
    }

    $mysql_server_package = $mysql_version ? {
        ""      => "MySQL-server-community",
        default => "MySQL-server-community-${mysql_version}",
    }

    if $mysql_bin_log == "" {
        $mysql_bin_log = true
    }
    if $mysql_binlog_do_db == "" {
        $mysql_binlog_do_db = []
    }
    if $mysql_relay_log == "" {
        $mysql_relay_log = true
    }
    if $mysql_expire_logs_days == "" {
        $mysql_expire_logs_days = "90"
    }
    if $mysql_log_slave_updates == "" {
        $mysql_log_slave_updates = false
    }
    if $mysql_slave == "" {
        $mysql_slave = false
    }
    if $mysql_conf_module == "" {
        $mysql_conf_module = "mysql"
    }
    if $mysql_log == "" {
        $mysql_log = "/var/log/mysql.log"
    }
    if $mysql_max_connections == "" {
        $mysql_max_connections = "2048"
    }
    if $mysql_table_cache == "" {
        $mysql_table_cache = "2048"
    }
    if $mysql_thread_cache == "" {
        $mysql_thread_cache = "2048"
    }
    if $mysql_wait_timeout == "" {
        $mysql_wait_timeout = "28800"
    }
    if $innodb_buffer_pool_size == "" {
        $innodb_buffer_pool_size = "1024M"
    }
    if $innodb_data_file_path_max == "" {
        $innodb_data_file_path_max = "200G"
    }
    if $innodb_file_format == "" {
        $innodb_file_format = ""
    }
    if $innodb_flush_log_at_trx_commit == "" {
        $innodb_flush_log_at_trx_commit = "1"
    }
    if $innodb_log_file_size == "" {
        $innodb_log_file_size = "512M"
    }
    if $innodb_thread_concurrency == "" {
        $innodb_thread_concurrency = "4"
    }
    if $mysql_additional_parameter == "" {
        $mysql_additional_parameter = ""
    }
    if $mysql_slowlog == "" {
        $mysql_slowlog = ""
    }
    if $mysql_logrotate_slowlog_mailto == "" {
        $mysql_logrotate_slowlog_mailto = ""
    }
    if $mysql_use_mysqld_multi == "" {
        $mysql_use_mysqld_multi = false
    }

    create_dir { "/var/run/mysql": }

    if $mysql_use_mysqld_multi == false {
        file { "/etc/my.cnf":
            content => template("${mysql_conf_module}/etc/my.cnf"),
            require => Package[$mysql_server_package],
            replace => false,
        }

        file { "/etc/logrotate.d/mysql":
            content => template("mysql/etc/logrotate.d/mysql"),
            require => Package[$mysql_server_package],
        }

        create_var_dir { ["binlog", "ibdata", "iblog"]: }

        if $mysql_log == "/var/log/mysql.log" {
            create_file { "/var/log/mysql.log": }
        }
        if $mysql_slowlog == "/var/log/mysql-slow.log" {
            create_file { "/var/log/mysql-slow.log": }
        }

        service { "mysql":
            require => [ Package[$mysql_server_package], File["/etc/my.cnf"], File["/var/lib/mysql/binlog"], File["/var/lib/mysql/ibdata", "/var/lib/mysql/iblog"] ],
        }
    }

    package {
        $mysql_client_package: ;
        $mysql_server_package: ;
    }


    #
    # install devel package
    #
    define install_devel_package() {
        $mysql_devel_package = $mysql_version ? {
            ""      => "MySQL-devel-community",
            default => "MySQL-devel-community-${mysql_version}",
        }
        package { $mysql_devel_package: }
    }

    #
    # create mysql directory
    #
    define create_var_dir() {
        create_dir { "/var/lib/mysql/${name}": }
    }

    define create_dir() {
        file { $name:
            ensure  => directory,
            mode    => 755,
            owner   => "mysql",
            group   => "mysql",
            require => Package[$mysql_server_package],
        }
    }


    #
    # create mysql empty file
    #
    define create_file() {
        file { $name:
            content => "",
            replace => false,
            mode    => 600,
            owner   => "mysql",
            group   => "mysql",
            require => Package[$mysql_server_package],
        }
    }


    #
    # set user password
    #
    define set_user_password($socket = "/var/lib/mysql/mysql.sock", $password) {
        $cmd_socket = $socket ? {
            ""      => "",
            default => "--socket=${socket}",
        }

        exec { "mysql-set-user-password-${name}":
            command => "mysqladmin ${cmd_socket} --user=${name} password ${password}",
            unless  => "mysqladmin ${cmd_socket} --user=${name} --password=${password} status",
            require => Service["mysql"],
        }
    }

    #
    # create user
    #
    define create_user($real_name = "", $password, $root_password = "", $socket = "/var/lib/mysql/mysql.sock", $limited_host = "%", $priv_param = "read", $database_name = "*") {
        $user_name = $real_name ? {
            ""      => $name,
            default => $real_name,
        }
        $cmd_password = $password ? {
            ""      => "",
            default => "--password=${password}",
        }
        $cmd_root_password = $root_password ? {
            ""      => "" ,
            default => "--password=${root_password}",
        }
        $cmd_socket = $socket ? {
            ""      => "",
            default => "--socket=${socket}",
        }

        case $priv_param {
            "replication": { $priv_type = "replication slave" }
            "read":        { $priv_type = "select" }
            "write":       { $priv_type = "select,insert,update,drop,create,delete,index,alter" }
            "all":         { $priv_type = "all privileges" }
            default:       { $priv_type = $priv_param }
        }

        exec { "mysql-create-user-${user_name}-${socket}":
            command  => "mysql --user=root ${cmd_root_password} ${cmd_socket} -e 'GRANT ${priv_type} ON ${database_name}.* TO ${user_name}@\"${limited_host}\" IDENTIFIED BY \"${password}\"'",
            unless   => "mysql --user=${user_name} ${cmd_password} ${cmd_socket} --host=localhost -e 'show status'",
            notify   => [ Exec["mysql-create-user-${user_name}-${socket}-localhost"], Exec["mysql-create-user-${user_name}-${socket}-localhost-ip"], Exec["mysql-flush-${user_name}-${socket}"] ],
        }
        if $database_name == "*" {
            Exec["mysql-create-user-${user_name}-${socket}"] {
                require +> Service["mysql"],
            }
        }
        else {
            Exec["mysql-create-user-${user_name}-${socket}"] {
                require +> [ Exec["mysql-create-database-${database_name}"], Service["mysql"] ],
            }
        }

        # same user for localhost
        exec { "mysql-create-user-${user_name}-${socket}-localhost":
            command     => "mysql --user=root ${cmd_root_password} ${cmd_socket} -e 'GRANT ${priv_type} ON ${database_name}.* TO ${user_name}@\"localhost\" IDENTIFIED BY \"${password}\"'",
            refreshonly => true,
            notify      => Exec["mysql-flush-${user_name}-${socket}"],
        }
        if $database_name == "*" {
            Exec["mysql-create-user-${user_name}-${socket}-localhost"] {
                require +> Service["mysql"],
            }
        }
        else {
            Exec["mysql-create-user-${user_name}-${socket}-localhost"] {
                require +> [ Exec["mysql-create-database-${database_name}"], Service["mysql"] ],
            }
        }

        # same user for 127.0.0.1
        exec { "mysql-create-user-${user_name}-${socket}-localhost-ip":
            command     => "mysql --user=root ${cmd_root_password} ${cmd_socket} -e 'GRANT ${priv_type} ON ${database_name}.* TO ${user_name}@'127.0.0.1' IDENTIFIED BY \"${password}\"'",
            refreshonly => true,
            notify      => Exec["mysql-flush-${user_name}-${socket}"],
        }
        if $database_name == "*" {
            Exec["mysql-create-user-${user_name}-${socket}-localhost-ip"] {
                require +> Service["mysql"],
            }
        }
        else {
            Exec["mysql-create-user-${user_name}-${socket}-localhost-ip"] {
                require +> [ Exec["mysql-create-database-${database_name}"], Service["mysql"] ],
            }
        }

        exec { "mysql-flush-${user_name}-${socket}":
            command     => "mysql --user=root ${cmd_root_password} ${cmd_socket} -e 'FLUSH PRIVILEGES'",
            refreshonly => true,
        }
    }

    #
    # drop user
    #
    define drop_user($password = "", $root_password = "", $socket = "/var/lib/mysql/mysql.sock", $limited_host = "localhost") {
        $cmd_root_password = $root_password ? {
            ""      => "" ,
            default => "--password=${root_password}",
        }
        $cmd_socket = $socket ? {
            ""      => "",
            default => "--socket=${socket}",
        }

        exec { "mysql-drop-user-${name}":
            command  => "mysql --user=root ${cmd_root_password} ${cmd_socket} -e 'DROP USER ${name}@${limited_host}'",
            unless   => "mysql --user=${name} ${cmd_password} ${cmd_socket} --host=${limited_host} -e 'show status'",
        }
    }

    #
    # create database
    #
    define create_database($root_password = "", $socket = "/var/lib/mysql/mysql.sock") {
        $cmd_root_password = $root_password ? {
            ""      => "" ,
            default => "--password=${root_password}",
        }
        $cmd_socket = $socket ? {
            ""      => "",
            default => "--socket=${socket}",
        }

        exec { "mysql-create-database-${name}":
            command => "mysql --user=root ${cmd_root_password} ${cmd_socket} -e 'CREATE DATABASE ${name}'",
            unless  => "mysql --user=root ${cmd_root_password} ${cmd_socket} ${name} -e 'show tables'",
            require => Service["mysql"],
        }
    }


    define install_master($root_password = "", $socket = "/var/lib/mysql/mysql.sock", $write_user_name, $write_user_password, $read_user_name = "", $read_user_password = "") {
        mysql::create_database { $name:
            root_password => $root_password,
            socket        => $socket,
        }

        mysql::create_user { $write_user_name:
            root_password => $root_password,
            socket        => $socket,
            password      => $write_user_password,
            priv_param    => "write",
            database_name => $name,
        }

        if $read_user_name == "" {
            $read_user_name     = $write_user_name
            $read_user_password = $write_user_password
        }

        mysql::create_user { $read_user_name:
            root_password => $root_password,
            socket        => $socket,
            password      => $read_user_password,
            priv_param    => "read",
            database_name => $name,
        }
    }

    define create_master_repl_user($root_password = "", $socket = "/var/lib/mysql/mysql.sock", $user_password = "repl_password") {
        mysql::create_user { $name:
            root_password => $root_password,
            socket        => $socket,
            password      => $user_password,
            priv_param    => "replication",
        }
    }

    #
    # create replication monitoring user for nagios
    #
    define create_slave_repl_client_user($real_name = "", $root_password = "", $socket = "/var/lib/mysql/mysql.sock", $user_password = "") {
        mysql::create_user { $name:
            real_name     => $real_name,
            root_password => $root_password,
            socket        => $socket,
            password      => $user_password,
            priv_param    => "replication client",
            database_name => "*",
        }
    }

    define install_slave($mysql_master_host, $root_password = "", $socket = "/var/lib/mysql/mysql.sock", $read_user_name, $read_user_password) {
        mysql::create_database { $name:
            root_password => $root_password,
            socket        => $socket,
        }

        mysql::create_user { "${name}-${read_user_name}":
            real_name     => $read_user_name,
            password      => $read_user_password,
            socket        => $socket,
            priv_param    => "read",
            database_name => $name,
        }

       mysql::create_slave_repl_client_user { "${name}-repl_client":
           real_name     => "repl_client",
           root_password => $root_password,
           socket        => $socket,
           user_password => "repl_pass",
       }
    }

    define install_slave_script($path, $mysql_database, $mysql_socket = "/var/lib/mysql/mysql.sock", $mysql_backup_dir, $mysqldump_opt = "--single-transaction --master-data=0 --default-character-set=utf8 --hex-blob", $mysql_master_host, $mysql_repl_user, $mysql_repl_password) {
        file { "${path}/mysql_backup_slave_${name}.sh":
            mode    => 755,
            content => template("mysql/mysql_backup_slave.sh"),
            require => File[$path],
        }

        file { "${path}/mysql_create_slave_${name}.sh":
            mode    => 755,
            content => template("mysql/mysql_create_slave.sh"),
            require => File[$path],
        }
    }
}
