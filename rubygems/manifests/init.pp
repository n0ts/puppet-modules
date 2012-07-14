#
# rubygems module
#
import "rubygems_mirror"

class rubygems {
    if $rubygems_gem == "" {
        $rubygems_gem = "/usr/bin/gem"
    }
    if $rubygems_is_mirror == "" {
        $rubygems_is_mirror = false
    }

    if $rubygems_is_mirror {
        $mirror_url = "http://rubygems.${domain}/rubygems"
        $gemrc = "gem: --no-rdoc --no-ri --no-update-sources --backtrace --source ${mirror_url}"
    } else {
        $gemrc = "gem: --no-rdoc --no-ri --no-update-sources --backtrace"
    }

    file { "/root/.gemrc":
        content => $gemrc,
    }

    if $rubygems_gem == "/usr/bin/gem" {
        package { [ "ruby-devel", "rubygems" ]: }
    }


    define install_gem_with_file($source) {
        exec { "get-gem-${name}":
            command => "wget --output-document=/tmp/${name}.gem ${source}",
            creates => "/tmp/${name}.gem",
            before  => Package[$name],
            require => [ Package["ruby-devel"], Package["rubygems"] ],
        }
        package { $name:
            provider => gem,
            source   => "/tmp/${name}.gem",
            require  => [ Package["ruby-devel"], Package["rubygems"] ],
        }
    }

    define install_gem($version = "", $depedency_package = "") {
        if $version == "" {
            package { $name:
                provider => gem,
                require  => [ Package["ruby-devel"], Package["rubygems"] ],
            }
        } else {
            package { $name:
                provider => gem,
                ensure   => $version,
                require  => [ Package["ruby-devel"], Package["rubygems"] ],
           }
        }

        if $depedency_package != "" {
            package { $depedency_package:
                before => Package[$name],
            }
        }

        case $name {
            "mysql": {
                package { "mysql-devel":
                    before => Package[$name],
                }
            }

            "nokogiri": {
                package { "libxml2-devel":
                    before => Package[$name],
                }

                package { "libxslt-devel":
                    before => Package[$name],
                }
            }

            "rmagick": {
                package { "ImageMagick-devel":
                    before => Package[$name],
                }

                package { "fontconfig-devel":
                    before => Package[$name],
                }

                package { "libtool-ltdl-devel":
                    before => Package[$name],
                }
            }

            "sqlite3-ruby": {
                package { "sqlite-devel":
                    before => Package[$name],
                }
            }
        }
    }

    define install_gem_with_options($version = "", $options = "", $source = "", $depedency_package = "") {
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
        if $source == "" {
            $source_param = ""
        } else {
            $source_param = "--source ${options}"
        }

        exec { "rubygems-install_gem_with_options-${name}":
            command => "gem install ${name} ${version_param} ${source_param} ${options_param}",
            unless  => "test `${rubygems_gem} list --installed ${name} ${version_param}` = true",
            require => [ Package["ruby-devel"], Package["rubygems"] ],
        }

        if $depedency_package != "" {
            package { $depedency_package:
                before => Package[$name],
            }
        }

        case $name {
            "mysql": {
                package { "mysql-devel":
                    before => Exec["rubygems-install_gem_with_options-${name}"],
                }
            }

            "nokogiri": {
                package { "libxml2-devel":
                    before => Exec["rubygems-install_gem_with_options-${name}"],
                }

                package { "libxslt-devel":
                    before => Exec["rubygems-install_gem_with_options-${name}"],
                }
            }

            "rmagick": {
                package { "ImageMagick-devel":
                    before => Exec["rubygems-install_gem_with_options-${name}"],
                }

                package { "fontconfig-devel":
                    before => Exec["rubygems-install_gem_with_options-${name}"],
                }

                package { "freetype-devel":
                    before => Exec["rubygems-install_gem_with_options-${name}"],
                }

                package { "libtool-ltdl-devel":
                    before => Exec["rubygems-install_gem_with_options-${name}"],
                }
            }

            "sqlite3-ruby": {
                package { "sqlite-devel":
                    before => Package[$name],
                }
            }
        }
    }
}
