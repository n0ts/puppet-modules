#
# dotfiles module
#

class dotfiles {
    define install_user_to_homedir($module = "dotfiles", $template = false) {
        if $template == false {
            file { "/home/${user}/.${name}":
                owner  => $user,
                group  => $group,
                mode   => 755,
                source => "puppet:///${module}/dot.${name}",
            }
        } else {
            file { "/home/${user}/.${name}":
                owner  => $user,
                group  => $group,
                mode   => 755,
                content => template("${module}/dot.${name}"),
            }
        }
    }
}
