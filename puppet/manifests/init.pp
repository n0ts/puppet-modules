#
# puppet module
#

import "puppet_server"

class puppet {
    if $puppet_report == "" {
        $puppet_report = false
    }
    if $puppet_pluginsync == "" {
        $puppet_pluginsync = false
    }
    if $puppet_allow == "" {
        $puppet_allow = "*.${domain}"
    }
    if $puppet_server == "" {
        $puppet_server = "puppet.${domain}"
    }
    if $puppet_log == "" {
        $puppet_log = "/var/log/puppet/puppet.log"
    }
    if $puppet_extra_opts == "" {
        $puppet_extra_opts = ""
    }
    if $puppet_version == "" {
        $puppet_version = ""
    }
    if $puppet_syslogfacility == "" {
        $puppet_syslogfacility = "daemon"
    }

    $puppet_package_name = $puppet_version ? {
        ""      => "puppet",
        default => "puppet-${puppet_version}",
    }

    file { "/etc/puppet/puppet.conf":
        content => template("puppet/etc/puppet/puppet.conf"),
        require => Package[$puppet_package_name],
    }

    file { "/etc/puppet/namespaceauth.conf":
        content => template("puppet/etc/puppet/namespaceauth.conf"),
        require => Package[$puppet_package_name],
    }

    file { "/etc/sysconfig/puppet":
        content => template("puppet/etc/sysconfig/puppet"),
        require => Package[$puppet_package_name],
    }

    service { "puppet":
        enable => false,
        ensure => stopped,
        require => Package[$puppet_package_name],
    }

    package { $puppet_package_name: }
}
