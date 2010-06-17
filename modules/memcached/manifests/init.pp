#
# memcached module
#


class memcached {
    if $memcached_port == "" {
        $memcached_port = "11211"
    }
    if $memcached_user == "" {
        $memcached_user = "nobody"
    }
    if $memcached_cachesize == "" {
        $memcached_cachesize = "512"
    }
    if $memcached_maxconn == "" {
        $memcached_maxconn = "1024"
    }
    if $memcached_options == "" {
        $memcached_options = ""
    }

    file { "/etc/sysconfig/memcached":
        content => template("memcached/etc/sysconfig/memcached"),
    }

    service { "memcached":
        subscribe => File["/etc/sysconfig/memcached"],
        require   => Package["memcached"],
    }

    package { "memcached": }
}
