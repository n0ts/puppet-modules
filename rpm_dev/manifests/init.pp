#
# rpm_dev module
#

class rpm_dev {
    if $rpm_dev_user == "" {
        $rpm_dev_user = "root"
    }
    if $rpm_dev_user_group == "" {
        $rpm_dev_user_group = "wheel"
    }
    if $rpm_dev_home == "" {
        $rpm_dev_home = $centos_rpm_user ? {
            root    => "/root",
            default => "/home/${rpm_dev_user}",
        }
    }
    if $rpm_dev_dist == "" {
        $rpm_dev_dist = ".el5"
    }

    file { "${rpm_dev_home}/.rpmmacros":
        owner   => $rpm_dev_user,
        group   => $rpm_dev_user_group,
        content => "%_topdir                %(echo \$HOME)/rpmbuild
%_smp_mflags            -j3
%__arch_install_post    /usr/lib/rpm/check-buildroot
%debug_package          %{nil}
%dist                   ${rpm_dev_dist}
",
    }

    package { "rpmdevtools":
        notify => Exec["rpm_dev-setuptree"],
    }

    exec { "rpm_dev-setuptree":
        command     => "rpmdev-setuptree",
        user        => $rpm_dev_user,
        refreshonly => true,
        unless      => "test -d /home/${rpm_dev_user}/rpmbuild",
    }
}
