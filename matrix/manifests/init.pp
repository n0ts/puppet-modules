#
# matrix module
#

class matrix {
    file { "/etc/sysconfig/matrix":
        content => template("matrix/etc/sysconfig/matrix"),
    }
}
