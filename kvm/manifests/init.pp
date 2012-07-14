#
# kvm module
#

class kvm {
    if $ksm_sleep == "" { 
        $ksm_sleep = "-10000"
    }

    file { "/usr/bin/ksm.sh":
        mode    => 755,
        content => template("kvm/usr/bin/ksm.sh"),
        notify  => Exec["kvm-add-ksm"],
    }

    exec { "kvm-add-ksm":
        command     => "/bin/echo '\n/usr/bin/ksm.sh -d > /dev/null' >> /etc/rc.local",
        refreshonly => true,
        require     => File["/usr/bin/ksm.sh"],
    }
}
