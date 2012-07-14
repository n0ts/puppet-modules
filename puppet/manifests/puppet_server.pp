#
# puppet_server module
#

class puppet_server {
    if $puppet_puppetmaster_log == "" {
        $puppet_puppetmaster_log = "daemon"
    }
    if $puppet_puppetmaster_extra_opts == "" {
        $puppet_puppetmaster_extra_opts = ""
    }
    if $puppet_version == "" {
        $puppet_version = ""
    }

    $puppet_package_name = $puppet_version ? {
        ""      => "puppet-server",
        default => "puppet-server-${puppet_version}",
    }

    file { "/etc/sysconfig/puppetmaster":
        content => template("puppet/etc/sysconfig/puppetmaster"),
        require => Package[$puppet_package_name],
    }

    service { "puppetmaster":
        require => Package[$puppet_package_name],
    }

    package { $puppet_package_name: }
}
