#
# trac module
#

class trac {
    $packagelist = [ "Trac", "python-genshi" ]
    package { $packagelist: }


    define do_global_conf() {
        $trac_root = $name
        $username = $global_name

        file { "${trac_root}/db":
            ensure => directory,
            owner => apache,
            group => apache,
            mode => 755,
        }

        file { "${trac_root}/db/trac.db":
            owner => apache,
            group => apache,
            replace => false,
        }

        file { "${trac_root}/bin":
            ensure => directory,
            owner => $username,
            group => $username,
            mode => 755,
        }

        file { "${trac_root}/bin/trac-post-commit-hook":
            owner => $username,
            group => $username,
            mode => 755,
            source => "puppet:///${global_name}/${trac_root}/bin/trac-post-commit-hook",
        }

        file { "${trac_root}/bin/commit-email.rb":
            owner => $username,
            group => $username,
            mode => 755,
            source => "puppet:///${global_name}/${trac_root}/bin/commit-email.rb",
        }

        file  { "${trac_root}/cgi-bin":
            ensure => directory,
            owner => $username,
            group => $username,
            mode => 755,
        }

        file { "${trac_root}/cgi-bin/trac.fcgi":
            owner => $username,
            group => $username,
            mode => 755,
            source => "puppet:///${global_name}/${trac_root}/cgi-bin/trac.fcgi",
        }

        file { "${trac_root}/conf/trac.ini":
            owner => $username,
            group => daemon,
            mode => 664,
            source => "puppet:///${global_name}/${trac_root}/conf/trac.ini",
        }
    }
}
