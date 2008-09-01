#
# cobbler module
#

class cobbler {
    do_conf { [
               "/etc/cobbler/settings",
               "/etc/cobbler/kickstart.ks.in",
               "/etc/cobbler/dhcp.template"
               ]:
    }

    exec { "cobbler_sync":
        command     => "/usr/bin/cobbler sync",
        refreshonly => true,
    }

    service { "cobblerd":
        subscribe => File["/etc/cobbler/settings"],
        require   => Package["cobbler"],
    }

    $packagelist = ["cobbler", "dhcp", "memtest86+"]
    package { $packagelist: }


    #
    # How to generate kickstart.ks from kickstart.ks.in
    #
    # 1. sed "s/@@SSH_BEGIN_PRIVATE_KEY@@/`cat $USER_HOME/.ssh/id_rsa | head -2 | tail -1`/g" /etc/cobbler/kickstart.ks.in > /tmp/kickstart.ks
    # 2. sudo mv /tmp/kickstart.ks /etc/cobbler
    # 3. sudo chown root:root /etc/cobbler/kickstart.ks
    # 4. sudo cobbler sync
    
    define do_conf() {
        file { $name:
            source => "puppet:///cobbler${name}",
            notify => Exec["cobbler_sync"],
            before => Exec["cobbler_sync"],
        }
    }
}
