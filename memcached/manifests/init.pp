#
# memcached module
#

class memcached {
    file { "/etc/sysconfig/memcached":
        source => "puppet:///memcached/etc/sysconfig/memcached",
    }

    service { "memcached":
        subscribe => File["/etc/sysconfig/memcached"],
        require => Package["memcached"],
    }

    package { "memcached": }
}
