#
# nfs module
#

class nfs {
    package { ["portmap", "nfs-utils"]: }

    service { [ "netfs", "nfs", "nfslock", "portmap" ]:
        require => [ Package["portmap"], Package["nfs-utils"] ],
    }
}
