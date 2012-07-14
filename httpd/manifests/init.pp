#
# httpd module
#

class httpd {
    if $httpd_version == "" {
        $httpd_version = ""
    }
    if $httpd_mpm == "" {
        $httpd_mpm = "prefork"
    }
    if $httpd_with_ssl == "" {
        $httpd_with_ssl = true
    }
    if $httpd_default_conf == "" {
        $httpd_default_conf = "default"
    }
    if $httpd_server_name == "" {
        $httpd_server_name = $fqdn
    }
    if $httpd_server_admin == "" {
        $httpd_server_admin = "info@${fqdn}"
    }
    if $httpd_errorlog_syslog == "" {
        $httpd_errorlog_syslog = false
    }
    if $httpd_log_rotate_interval == "" {
        $httpd_log_rotate_interval = 86400
    }
    if $httpd_delete_log_dirs == "" {
        $httpd_delete_log_dirs = [ "/var/log/httpd" ]
    }
    if $httpd_delete_log_mtime == "" {
        $httpd_delete_log_mtime = "30"
    }

    $httpd_package = $httpd_version ? {
        ""      => "httpd",
        default => "httpd-${httpd_version}",
    }

    file { "/etc/logrotate.d/httpd":
        ensure  => absent,
        require => Package[$httpd_package],
    }

    file { "/etc/sysconfig/httpd":
        source  => "puppet:///httpd/etc/sysconfig/httpd.${httpd_mpm}",
        notify  => Service["httpd"],
        require => Package[$httpd_package],
    }

    file { "/etc/cron.daily/httpd-log.cron":
        mode    => 755,
        content => template("httpd/etc/cron.daily/httpd-log.cron"),
        require => Package[$httpd_package],
    }

    file  { "/var/www/html/index.html":
        content => template("httpd/var/www/html/index.html"),
        require => Package[$httpd_package],
    }

    file { "/etc/httpd/conf/httpd.conf":
        source  => "puppet:///httpd/etc/httpd/conf/httpd.conf.${httpd_default_conf}",
        require => Package[$httpd_package],
        notify  => Service["httpd"],
    }

    file { "/etc/httpd/conf/local":
        ensure  => directory,
        mode    => 755,
        require => Package[$httpd_package],
    }

    file { "/etc/cron.daily/httpd":
        source => "puppet:///httpd/etc/cron.daily/httpd",
        mode   => 755,
    }

   install_local_conf {
       "httpd-11-log-rotate.conf":
           template => true;
    }

    service { "httpd":
        require => Package[$httpd_package],
    }

    package {
        $httpd_package: ;
        "cronolog":
            require => Package[$httpd_package];
        "mod_log_rotate":
            require => Package[$httpd_package];
    }
 
    if $httpd_with_ssl == true {
        if $httpd_default_conf != "default" {
            file { "/etc/httpd/conf/local/httpd-00-ssl.conf":
                ensure => "/etc/httpd/conf.d/ssl.conf",
            }
        }

        $mod_ssl_package = $httpd_version ? {
            ""      => "mod_ssl",
            default => "mod_ssl-${httpd_version}",
        }

        package { $mod_ssl_package:
            require => Package[$httpd_package],
        }
    }


    define install_devel_package() {
        $httpd_package = $httpd_version ? {
            ""      => "httpd",
            default => "httpd-${httpd_version}",
        }
        $httpd_devel_package = $httpd_version ? {
            ""      => "httpd-devel",
            default => "httpd-devel-${httpd_version}",
        }

        package { $httpd_devel_package:
            require => Package[$httpd_package],
        }
    }

    define install_default_local_conf($server_name = "", $server_admin = "", $errorlog_syslog = false, $errorlog_syslog_facility = "") {
        if $server_name == "" {
            $httpd_server_name = $fqdn
        }
        else {
            $httpd_server_name = $server_name
        }
        if $server_admin == "" {
            $httpd_server_admin = "info@example.com"
        }
        else {
            $httpd_server_admin = $server_admin
        }
        $httpd_errorlog_syslog = $errorlog_syslog
        $httpd_errorlog_syslog_facility = $errorlog_syslog_facility

        file { "/etc/httpd/conf/local/httpd-01-local.conf":
            content => template("httpd/etc/httpd/conf/local/httpd-01-local.conf"),
            require => File["/etc/httpd/conf/local"],
        }
    }

    define install_local_conf($module = "httpd", $template = false) {
        $httpd_package = $httpd_version ? {
            ""      => "httpd",
            default => "httpd-${httpd_version}",
        }

        file { "/etc/httpd/conf/local/${name}":
            notify  => Service["httpd"],
            require => [ Package[$httpd_package], File["/etc/httpd/conf/local"] ],
        }

        if $template == false {
            File["/etc/httpd/conf/local/${name}"] {
                source +> "puppet:///${module}/etc/httpd/conf/local/${name}",
            }
        } else {
            File["/etc/httpd/conf/local/${name}"] {
                content +> template("${module}/etc/httpd/conf/local/${name}"),
            }
        }
    }

    define install_asis_conf($owner = "apache", $group = "apache") {
        file { "${name}/200.asis":
            owner   => $owner,
            group   => $group,
            content => template("httpd/htdocs/200.asis"),
            require => File[$name],
        }

        file { "${name}/503.asis":
            owner   => $owner,
            group   => $group,
            content => template("httpd/htdocs/200.asis"),
            require => File[$name],
        }

        file { "${name}/check.asis":
            owner   => $owner,
            group   => $group,
            ensure  => "${name}/200.asis",
            replace => false,
            require => File["${name}/200.asis"],
        }
    }
}

