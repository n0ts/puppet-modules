#
# yum module
#

class yum {
    file { "/etc/yum/yum.conf":
        source => "puppet:///yum/etc/yum/yum.conf",
    }


    define do_global_conf() {
        file { "/etc/${name}":
            source => "puppet:///${global_name}/etc/${name}",
        }
    }

    define do_repo($baseurl, $gpgkey = "", $gpgcheck = 0, $exclude = "", $priority = 99, $enabled = 1) {
        case $exclude {
            "": {
                yumrepo { "${name}":
                    descr => "${name}",
                    baseurl => "${baseurl}/${name}",
                    enabled => $enabled,
                    priority => $priority,
                    gpgcheck => $gpgcheck,
                    gpgkey => $gpgkey,
                }
            }
            default: {
                yumrepo { "${name}":
                    descr => "${name}",
                    baseurl => "${baseurl}/${name}",
                    enabled => $enabled,
                    priority => $priority,
                    gpgcheck => $gpgcheck,
                    gpgkey => $gpgkey,
                    exclude => $exclude,
                }
            }
        }
    }
}
