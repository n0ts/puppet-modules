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
        subscribe => File["/etc/ssh/sshd_config"],
        require   => Package["openssh-server"],
    }

    package { ["openssh-server", "openssh-clients"]: }
}
