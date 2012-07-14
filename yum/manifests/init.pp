#
# yum module
#

class yum {
    if $yum_metadata_expire == "" {
        $yum_metadata_expire = "0"
    }
    if $yum_exclude == "" {
        $yum_exclude = "*.i386"
    }

    file { "/etc/yum.conf":
        content => template("yum/etc/yum.conf"),
        require => Package["yum"],
    }

    file {
        [ "/etc/yum.repos.d/CentOS-Base.repo",
          "/etc/yum.repos.d/CentOS-Media.repo" ]:
              ensure => absent;
    }

    package { "yum": }


    # yum repository for vendor servers
    case $manufacturer {
        "Dell Inc.": {
            install_repo {
                "dell-community":
                    cobbler_mirror => true,
                    priority       => 1;
                "dell-hardware":
                    cobbler_mirror => true,
                    priority       => 1;
            }
        }

        "HP": {
            install_repo {
                "hp-proliantsupportpack":
                    priority       => 1,
                    cobbler_mirror => true,
            }
        }
    }


    define install_repo($baseurl = "http://repos.${domain}", $priority = 99, $enabled = 1, $gpgcheck = 0, $exclude = absent, $cobbler_mirror = false) {
        $baseurl_param = $cobbler_mirror ? {
            true    => "cobbler/repo_mirror/",
            default => "",
        }
        yumrepo { "${name}-${architecture}":
            descr    => "${name}-${architecture}",
            baseurl  => "${baseurl}/${baseurl_param}${name}-${architecture}",
            enabled  => $enabled,
            priority => $priority,
            gpgcheck => $gpgcheck,
            exclude  => $exclude,
        }
    }
}
