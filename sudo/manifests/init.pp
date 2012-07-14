#
# sudo module
#

class sudo {
    if $sudo_user_alias == ""  {
        $sudo_user_alias = "root"
    }
    if $sudo_use_default_conf == "" {
        $sudo_use_default_conf = true
    }

    if $sudo_use_default_conf == true {
        file { "/etc/sudoers":
            mode    => 440,
            content => template("sudo/etc/sudoers"),
            require => Package["sudo"],
        }
    }

    package { "sudo": }


    define install_conf($template = false) {
        file { "/etc/sudoers":
            mode    => 440,
            require => Package["sudo"],
        }

        if $template == false {
            File["/etc/sudoers"] {
                source +> "puppet:///${name}/etc/sudoers",
            }
        } else {
            File["/etc/sudoers"] {
                content +> template("${name}/etc/sudoers"),
            }
        }
    }
}
