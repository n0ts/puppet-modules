#
# activemq module
#

class activemq {
    file { "/etc/init.d/activemq":
        mode    => 755,
        source  => "puppet:///centos/etc/init.d/activemq",
        require => Package["apache-activemq"],
    }

    service { "activemq":
        require => File["/etc/init.d/activemq"],
    }
}
