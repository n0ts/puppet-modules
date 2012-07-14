#
# rubygems_mirror module
#

class rubygems_mirror inherits rubygems {
    $mirror_root = "/var/www/rubygems"

    file {
        "/var/www":
            ensure => directory,
            mode   => 755;
        $mirror_root:
            ensure  => directory,
            mode    => 755,
            require => File["/var/www"];
    }

    if $rubygems_gem == "/usr/bin/gem" {
        package { "builder":
            provider => gem,
            require  => Package["rubygems"],
        }
    }

    file { "/root/.gemmirrorrc":
        content => "---
- from: http://gems.rubyforge.org
  to: ${mirror_root}",
    }

    $httpd_package = $httpd_version ? {
        ""      => "httpd",
        default => "httpd-${httpd_version}",
    }

    file { "/etc/httpd/conf/local/httpd-00-rubygems.conf":
        source  => "puppet:///rubygems/etc/httpd/conf/local/rubygems.conf",
        require => [ File['/etc/httpd/conf/local'], Package[$httpd_package] ],
    }

    if $rubygems_gem == "/usr/bin/gem" {
        cron { "rubygems-mirror":
            command => "${rubygems_gem} mirror --quiet > /dev/null 2>&1 && ${rubygems_gem} generate_index --quiet -d ${mirror_root} > /dev/null 2>&1",
            user    => root,
            hour    => 4,
            minute  => 10,
        }
    }
}
