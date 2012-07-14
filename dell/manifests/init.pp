#
# dell module
#

class dell {
    if $dell_webserver == "" {
        $dell_webserver = false
    }

    package { "srvadmin-base": }

    if $dell_webserver == true {
        package { "srvadmin-webserver":
            notify  => Exec["dell-start-rvadmin"],
            require => Package["srvadmin-base"],
        }

        exec { "dell-start-rvadmin":
            command     => "/etc/init.d/dsm_om_connsvc start",
            refreshonly => true,
        }
    }

    if $dell_storage_controller != "" {
        package { "srvadmin-storageservices": }
    }

    #
    # Nagios NRPE plugin for DELL storage
    #
    define install_nagios_nrpe() {
        if $dell_storage_controller != "" {
            include nagios_nrpe
            nagios_nrpe::install_conf { "check_dell_storage_pdisk":
                module => "dell",
            }
        }

        if $dell_storage_battery != "" {
            include nagios_nrpe
            nagios_nrpe::install_conf { "check_dell_storage_battery":
                module => "dell",
            }
        }
    }
}
