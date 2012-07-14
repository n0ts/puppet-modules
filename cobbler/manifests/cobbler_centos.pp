#
# cobbler_centos.pp
#

class cobbler_centos inherits cobbler {
    $cobbler_centos_major_version = "5"
    $cobbler_centos_minor_version = "8"
    $cobbler_centos_distro = "centos${cobbler_centos_major_version}${cobbler_centos_minor_version}"
    $cobbler_centos_local_profile_xen_repos = "xen-3.4.4-x86_64"

    # distribution
    cobbler::import_distro { $cobbler_centos_distro:
        path => "rsync://ftp.jaist.ac.jp/pub/Linux/centos/${cobbler_major_version}/${architecture}/os/",
    }

    # local yum mirror repository
    $mirror_url = "http://ftp.jaist.ac.jp/pub/Linux"
    cobbler::add_repo {
        "centos${cobbler_centos_major_version}-os":
            mirror => "${mirror_url}/CentOS/${cobbler_centos_major_version}/os/${architecture}";
        "centos${cobbler_centos_major_version}-extras":
            mirror => "${mirror_url}/CentOS/${cobbler_centos_major_version}/extras/${architecture}";
        "centos${cobbler_centos_major_version}-updates":
            mirror => "${mirror_url}/CentOS/${cobbler_centos_major_version}/updates/${architecture}";
        "centos${cobbler_centos_major_version}-origs":
            mirror => "/home/${user}/rpmbuild/RPMS",
            breed  => "rsync";
        "epel${cobbler_centos_major_version}":
            mirror => "${mirror_url}/Fedora/epel/${cobler_centos_major_version}/${architecture}/";
    }

    # local profile
    if $cobbler_local_profile != "" {
        if $cobbler_local_system == "" {
            $cobbler_local_system = $cobbler_local_profile
        }
        $ksmeta = "local_name=${cobbler_local_system} user_name=${cobbler_local_user}"
        add_profile { $cobbler_local_profile:
            distro       => $cobbler_centos_distro,
            ksmeta       => $ksmeta,
            name_servers => $cobbler_local_name_servers,
        }
        if $cobbler_centos_local_profile_xen_repos != "" {
            add_profile { "${cobbler_local_profile}-xen-host":
                distro       => $cobbler_centos_distro,
                ksmeta       => $ksmeta,
                repos        => $cobbler_centos_local_profile_xen_repos,
                name_servers => $cobbler_local_name_servers,
            }
        }
        add_profile { "${cobbler_local_profile}-xen-guest":
            distro         => $cobbler_centos_distro,
            ksmeta         => $ksmeta,
            name_servers   => $cobbler_local_name_servers,
            virt_type      => "xenpv",
            virt_bridge    => "xenbr0",
        }
        add_profile { "${cobbler_local_profile}-kvm-guest":
            distro         => $cobbler_centos_distro,
            ksmeta         => $ksmeta,
            name_servers   => $cobbler_local_name_servers,
            virt_type      => "qemu",
            virt_bridge    => "br0",
        }
    }

    # memtest86+
    $memtest86_version = "4.20"
    cobbler::add_image { "memtest86+":
        file => "/tftpboot/memtest86+-${memtest86_version}",
    }
    package { "memtest86+-${memtest86_version}":
        before => Exec["cobbler-add-image-memtest86+"],
    }


    file { "/var/lib/cobbler/snippets/centos":
        ensure  => directory,
        require => Package["cobbler"],
    }

    file { "/var/lib/cobbler/kickstarts/centos.ks":
        source => "puppet:///cobbler/var/lib/cobbler/kickstarts/centos.ks",
        require => Package["cobbler"],
    }

    install_snippets {
        "packages": ;
        "partition_select_default": ;
        "partition_select_lvm_data": ;
        "partition_select_lvm_default": ;
        "partition_select_lvm_raid": ;
        "posts": ;
        "posts_grub_conf": ;
        "posts_host_virt": ;
        "post_install_network_config": ;
        "posts_iptables": ;
        "posts_kvm_host": ;
        "posts_noipv6": ;
        "posts_local_user": ;
        "posts_partition": ;
        "posts_ssh": ;
        "posts_vendor": ;
        "posts_xen_dom0": ;
        "posts_xen_domu": ;
        "posts_yum": ;
        "pre_partition_calc_swap": ;
        "xen-network-bridge-custom": ;
    }


    define install_snippets_directory() {
        file { "/var/lib/cobbler/snippets/${name}":
            ensure  => directory,
            require => Package["cobbler"],
        }
    }

    define install_snippets($module = "cobbler", $distro = "centos", $template = false) {
        file { "/var/lib/cobbler/snippets/${distro}/${name}":
            require => File["/var/lib/cobbler/snippets/${distro}"],
        }

        if $template == false {
            File["/var/lib/cobbler/snippets/${distro}/${name}"] {
                source +> "puppet:///${module}/var/lib/cobbler/snippets/${distro}/${name}",
            }
        } else {
            File["/var/lib/cobbler/snippets/${distro}/${name}"] {
                content +> template("${module}/var/lib/cobbler/snippets/${distro}/${name}"),
            }
        }
    }

    define add_profile($distro, $kopts = "", $kopts_post = "", $repos = "", $name_servers = "", $name_servers_search = "", $ksmeta = "", $virt_auto_boot = 1, $virt_type = "", $virt_bridge = "") {
        $distro_param = $virt_type ? {
            "xenpv" => "${distro}-xen-${architecture}",
            default => "${distro}-${architecture}",
        }
        cobbler::add_profile { $name:
            distro              => $distro_param,
            base_distro         => "${distro}-${architecture}",
            kickstart           => "centos.ks",
            repos               => "centos5-os-x86_64 centos5-updates-x86_64 centos5-extras-x86_64 centos5-origs-x86_64 epel5-x86_64 ${repos}",
            kopts               => $kopts,
            ksmeta              => "partition=lvm_default ${ksmeta}",
            name_servers        => $name_servers,
            name_servers_search => $name_servers_search,
            virt_auto_boot      => $virt_auto_boot,
            virt_type           => $virt_type,
            virt_bridge         => $virt_bridge,
        }
    }

    define add_system($profile, $kopts = "", $kopts_post = "", $ksmeta = "", $is_virt = false, $virt_type = "", $virt_cpus = 1, $virt_file_size = 0, $virt_path = "vg", $virt_ram = "", $virt_bridge1 = "",  $virt_bridge2 = "", $gateway = "", $mac1 = "", $mac2 = "", $ip2 = "", $subnet2 = "", $power_type = "", $power_address = "", $power_user = "", $power_pass = "", $interface_type = "", $bonding_opts = "") {
        $ip1_major = regsubst($name, '^s(\d+)[-]u(\d+)$', '\1')
        if $ip1_major == $name {
            $ip1_minor = regsubst($name, '^s(\d+)$', '\1')
            $ip1_header = regsubst($ipaddress, '^(\d+)\.(\d+)\.(\d+)\.(\d+)$', '\1.\2')
            $ip1 = "${ip1_header}.0.${ip1_minor}"
        }
        else {
            $ip1_minor = regsubst($name, '^s(\d+)[-]u(\d+)$', '\2')
            $ip1_header = regsubst($ipaddress, '^(\d+)\.(\d+)\.(\d+)\.(\d+)$', '\1.\2')
            $ip1 = "${ip1_header}.${ip1_major}.${ip1_minor}"
        }

        if $is_virt == true {
            cobbler::add_system { $name:
                profile        => $profile,
                hostname       => "${name}.${domain}",
                gateway        => $gateway,
                kopts          => $kopts,
                kopts_post     => $kopts_post,
                ksmeta         => $ksmeta,
                virt_type      => $virt_type,
                virt_cpus      => $virt_cpus,
                virt_file_size => $virt_file_size,
                virt_path      => $virt_path,
                virt_ram       => $virt_ram,
                mac1           => $mac1,
                ip1            => $ip1,
                subnet1        => $netmask,
                virt_bridge1   => $virt_bridge1,
                ip2            => $ip2,
                subnet2        => $subnet2,
                virt_bridge2   => $virt_bridge2,
            }
        }
        else {
            # power type must be one of:
            # - apc_snmp,bladecenter,bullpap,drac,ether-wake,ilo,
            #   integrity,ipmilan,ipmitool,lpar,none,rsa,virsh,wti
            $bondig_opts_default = "mode=active-backup miimon=100 primary=eth0 fail_over_mac=follow"
            $bonding_opts_param = $bonding_opts ? {
                ""      => $bondig_opts_default,
                default => "${Bondig_opts_default} ${bonding_opts}",
            }
            cobbler::add_system { $name:
                profile         => $profile,
                hostname        => "${name}.${domain}",
                interface1      => "eth0",
                interface1_type => $interface_type,
                mac1            => $mac1,
                ip1             => $ip1,
                subnet1         => $netmask,
                interface2      => "eth1",
                interface2_type => $interface_type,
                mac2            => $mac2,
                ip2             => $ip2,
                subnet2         => $subnet2,
                bonding_opts    => $bonding_opts_param,
                gateway         => $gateway,
                kopts           => $kopts,
                kopts_post      => $kopts_post,
                ksmeta          => $ksmeta,
                power_type      => $power_type,
                power_address   => $power_address,
                power_user      => $power_user,
                power_pass      => $power_pass,
            }
        }
    }

    define add_repo_dell() {
        $mirror_url1 = "http://linux.dell.com/repo/"
        $mirror_url2 = $name ? {
            "community" => "community/content/el5-${architecture}",
            "hardware"  => "hardware/latest/platform_independent/rh50_64",
        }
        cobbler::add_repo { "dell-${name}":
            mirror       => "${mirror_url1}${mirror_url2}",
            keep_updated => "False",
        }
    }

    define add_repo_hp($mirror = "") {
        # Official page:
        # http://whp-cpq.extweb.hp.com/products/servers/management/psp/index.html
        # Yum repository:
        # http://downloads.linux.hp.com/SDR/downloads/
        # IntegritySupportPack
        # IntegrityWBEM
        # ProLiantSupportPack
        # ProLiantWBEM
        # WorkstationSupportPack
        # integritysupportpack
        # integritywbem
        # proliantsupportpack
        # proliantwbem
        # workstationsupportpack
        #
        # NOTES:
        # - latest version is here (http://downloads.linux.hp.com/SDR/downloads/proliantsupportpack/RedHatEnterpriseAS/5/${architecture}/current),
        #   but the yum repository couldn't create local yum repository...
        cobbler::add_repo { "hp-${name}-${architecture}":
            mirror       => "http://downloads.linux.hp.com/SDR/downloads/proliantsupportpack/RedHatEnterpriseAS/5/${architecture}/current",
            keep_updated => "False",
        }
    }

    define add_repo_mysql() {
        cobbler::add_repo { "mysql-${name}":
            mirror => "rsync://ftp.jaist.ac.jp/pub/mysql/Downloads/${name}/",
            breed  => "rsync",
        }
    }

    define add_repo_cdh() {
        $mirror = $osfamily ? {
            "redhat" => "http://archive.cloudera.com/redhat/cdh/${name}",
            default  => "",
        }

        if $mirror != "" {
            cobbler::add_repo { "cdh-${name}":
                mirror => $mirror,
            }
        }
    }
}
