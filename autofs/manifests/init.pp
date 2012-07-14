#
# autofs module
#

class autofs {
    package { "autofs": }

    service { "portmap":
        pattern => "automount",
    }

    service { "autofs":
        pattern => "automount",
    }
}
