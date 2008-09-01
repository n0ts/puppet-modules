#
# openssh server and client module
#

class openssh {
    file { "/etc/ssh/sshd_config":
        mode    => 600,
        source  => "puppet:///openssh/etc/ssh/sshd_config",
        require => Package["openssh-server"],
    }

    service { "sshd":
        enable    => true,
        ensure    => running,
        subscribe => File["/etc/ssh/sshd_config"],
        require   => Package["openssh-server"],
    }

    $packagelist = ["openssh-server", "openssh-clients"]
    package { $packagelist: ensure => installed }
}
