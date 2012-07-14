#
# nscd module
#

class nscd {
    file { "/etc/nscd.conf":
        source => "puppet:///nscd/etc/nscd.conf",
    }

    service { "nscd":
        subscribe => File["/etc/nscd.conf"],
        require   => Package["nscd"],
    }

    package { "nscd": }
}
