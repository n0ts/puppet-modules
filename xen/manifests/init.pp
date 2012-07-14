#
# xen module
#

class xen {
    # xen virtual guest
    if $virtual == "xen0" {
        file { "/usr/bin/xen_check_memory.sh":
            mode   => 755,
            source => "puppet:///xen/xen_check_memory.sh",
        }
    }
}
