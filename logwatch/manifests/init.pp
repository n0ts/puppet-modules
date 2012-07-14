#
# logwatch module
#

class logwatch::disable {
    file { "/etc/cron.daily/0logwatch":
        ensure => absent,
    }
}
