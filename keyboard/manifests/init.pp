#
# keyboard module
#

class keyboard {
    $keymap = "/lib/kbd/keymaps/i386/qwerty/usx.map.gz"

    do_conf {
        $keymap: ;
        "/etc/sysconfig/keyboard": ;
    }

    exec { "loadkeys":
        command     => "/bin/loadkeys ${keymap}",
        refreshonly => true,
    }

    define do_conf() {
        file { $name:
            source => "puppet:///keyboard$name",
            notify => Exec['loadkeys'],
            before => Exec['loadkeys'],
        }
    }
}
