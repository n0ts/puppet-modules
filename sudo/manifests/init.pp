#
# sudo module
#

# default sudo user alias
$sudo_username = "root"

class sudo {
    file { "/etc/sudoers":
        mode => 440,
        content => template("sudo/etc/sudoers"),
        require => Package["sudo"],
    }

    package { "sudo": ensure => installed }
}
