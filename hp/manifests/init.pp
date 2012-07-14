#
# hp module
#

class hp {
    if $hp_admin_group == "" {
        $hp_admin_group = "wheel"
    }

    file { "/etc/redhat-release":
        content => "Red Hat Enterprise Linux AS release 5",
    }

    service {
        "hp-asrd":
            require => Service["hp-health"];
        "hp-health":
            require => Package["hp-health"];
        "hp-snmp-agents":
            hasstatus => false,
            status    => "/sbin/pidof -x cmahealthd",
            require   => [ File["/etc/snmp/snmpd.conf"], Package["hp-snmp-agents"] ];
        "hpsmhd":
            require => Package["hpsmh"],
            before  => Exec["hp-shmconfig-admingroup"],
    }

    exec { "hp-shmconfig-admingroup":
        command => "/opt/hp/hpsmh/sbin/smhconfig --admin-group=${hp_admin_group}",
        unless  => "test -z `/opt/hp/hpsmh/sbin/smhconfig --display-current-settings | grep a1dmin-group`",
    }

    package {
        [
         # The HP Array Configuration Utility is the web-based disk array
         # configuration program for Array Controllers.
         # /usr/sbin/cpqacuxe, i386 only,
         #"cpqacuxe",

         # This package contains the System Management Homepage Templates for
         # all hp Proliant systems with ASM, ILO, & ILO2 embedded management
         # asics.
         # /opt/hp/hp-smh-templates/bin/add-sudo-entries ...
         "hp-smh-templates",

         # Identifies and exercises system components.
         #"hpdiags",

         # The HP System Management Homepage v6.2.0.12
         # /etc/init.d/hpsmhd start
         # port 2381
         "hpsmh",

         # This is an upgraded version of the OpenIPMI device driver that is
         # shipped as part of the standard Linux kernel. This release is for
         # Linux 2.6.18+ kernels.
         #"hp-OpenIPMI",

         # This package contains the SNMP server, storage, and nic agents for
         # all hp Proliant systems with ASM, ILO, & ILO2 embedded management
         # asics
         "hp-snmp-agents",

         # This package provides Linux/Xwindows support for the High
         # Performance Remote Console mouse for HP Proliant system with the
         # ILO2 management processor
         #"hpmouse",

         # This package contains the System Health Monitor and Advanced Server
         # Reset Daemon for all hp Proliant systems with ASM, ILO, & ILO2
         # embedded management asics. Also contained are the command line
         # utilities
         "hp-health",

         # The HP Command Line Array Configuration Utility is the disk
         # array configuration program for Array Controllers.
         # i386 only
         #"hpacucli",

         # Hponcfg is a command line utility that can be used to configure
         # iLO/RILOE II from with in the operating system without requiring a
         # reboot of the server.
         "hponcfg",
         ]:
             require => [ Yumrepo["hp-proliantsupportpack-x86_64"], File["/etc/redhat-release"] ],
    }

    if $raidcontroller != "" {
        package_yum { "hpacucli": }
    }
}
