#
# rubyenterprise module
#

class rubyenterprise {
    $ruby_enterprise_package = $ruby_enterprise_version ? {
        ""      => "ruby-enterprise",
        default => "ruby-enterprise-${ruby_enterprise_version}",
    }

    package { $ruby_enterprise_package:
        name => "ruby-enterprise",
    }


    define install_gem($version = "", $options = "", $depedency_package = "") {
        if $version == "" {
            $version_param = ""
        } else {
            $version_param = "-v ${version}"
        }
        if $options == "" {
            $options_param = ""
        } else {
            $options_param = "-- ${options}"
        }

        exec { "rubyenterprise-install-gem-${name}":
            command => "/opt/ruby/bin/gem install ${name} ${version_param} ${options_param}",
            unless  => "test `/opt/ruby/bin/gem list --installed ${name} ${version_param}` = true",
            require => Package["ruby-enterprise"],
        }

        if $depedency_package != "" {
            package { $depedency_package:
                before => Package[$name],
            }
        }

        case $name {
            "mysql": {
                package { "mysql-devel":
                    before => Exec["rubyenterprise-install-gem-${name}"],
                }
            }

            "nokogiri": {
                package { "libxml2-devel":
                    before => Exec["rubyenterprise-install-gem-${name}"],
                }

                package { "libxslt-devel":
                    before => Exec["rubyenterprise-install-gem-${name}"],
                }
            }

            "rmagick": {
                package { "ImageMagick-devel":
                    before => Exec["rubyenterprise-install-gem-${name}"],
                }

                package { "fontconfig-devel":
                    before => Exec["rubyenterprise-install-gem-${name}"],
                }

                package { "freetype-devel":
                    before => Exec["rubyenterprise-install-gem-${name}"],
                }

                package { "libtool-ltdl-devel":
                    before => Exec["rubyenterprise-install-gem-${name}"],
                }
            }

            "sqlite3-ruby": {
                package { "sqlite-devel":
                    before => Package[$name],
                }
            }
        }
    }

    define install_passenger($enterprise_key = "") {
        install_gem { "passenger":
            version => $name,
        }

        $httpd_devel_package = $httpd_version ? {
            ""      => "httpd-devel",
            default => "httpd-devel-${httpd_version}",
        }

        $apr_util_package = $apr_version ? {
             ""      => "apr-util",
             default => "apr-util-${apr_version}",
        }

        $apr_util_devel_package = $apr_version ? {
            ""      => "apr-util-devel",
            default => "apr-util-devel-${apr_version}",
        }

        package { $apr_util_package: }

        package { $apr_util_devel_package:
            require => Package[$apr_util_package],
        }

        package { ["curl-devel", "gcc-c++"]: }

        exec { "rubyenterprise-build-apache2-module":
            command => "yes | /opt/ruby/bin/passenger-install-apache2-module",
            unless  => "test -f /opt/ruby/lib/ruby/gems/1.8/gems/passenger-${passenger_version}/ext/apache2/mod_passenger.so",
            before  => Service["httpd"],
            require => [ Package[$httpd_devel_package], Package[$apr_util_devel_package], Exec["rubyenterprise-install-gem-passenger"], Package["curl-devel"], Package["gcc-c++"] ],
        }

        if $enterprise_key != "" {
            Exec["rubyenterprise-build-apache2-module"] {
                notify +> Exec["rubyenterprise-enterprisey"],
            }
        }

        exec { "rubyenterprise-enterprisey":
            command     => "yes ${enterprise_key} | /opt/ruby/bin/passenger-make-enterprisey",
            unless      => "test -n ${enterprise_key}",
            refreshonly => true,
        }
    }
}
