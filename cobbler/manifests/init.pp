#
# cobbler module
#
import "cobbler_centos"

class cobbler {
    if $cobbler_server == "" {
        $cobbler_server = $ipaddress
    }
    if $cobbler_manage_dhcp == "" {
        $cobbler_manage_dhcp = 1
    }
    if $cobbler_pxe_just_once == "" {
        $cobbler_pxe_just_once = 1
    }
    if $cobbler_default_virt_bridge == "" {
        $cobbler_default_virt_bridge = "br0"
    }
    if $cobbler_default_virt_ram == "" {
        $cobbler_default_virt_ram = "1024"
    }
    if $cobbler_default_virt_file_size == "" {
        $cobbler_default_virt_file_size = "10"
    }
    if $cobbler_default_virt_type == "" {
        $cobbler_default_virt_type = "qemu"
    }
    if $cobbler_reposync_flags == "" {
        $cobbler_reposync_flags = "-l -m -d"
    }
    if $cobbler_kernel_options == "" {
        $cobbler_kernel_options = []
    }
    if $cobbler_dhcpdargs == "" {
        $cobbler_dhcpdargs = "eth0"
    }


    if $cobbler_manage_dhcp == 1 {
        file { "/etc/sysconfig/dhcpd":
            content => template("cobbler/etc/sysconfig/dhcpd"),
            notify  => [ Service["cobblerd"], Exec["cobbler-sync"] ],
            require => Package["cobbler"],
        }
    }

    file {
        "/etc/xinetd.d/rsync":
            source  => "puppet:///cobbler/etc/xinetd.d/rsync",
            notify  => Service["xinetd"],
            require => Package["cobbler"];
        "/etc/xinetd.d/tftp":
            source => "puppet:///cobbler/etc/xinetd.d/tftp",
            notify  => Service["xinetd"],
            require => Package["cobbler"];
    } 

    file { "/etc/cobbler/settings":
        content => template("cobbler/etc/cobbler/settings"),
        notify  => Service["cobblerd"],
        require => Package["cobbler"],
    }

    cobbler::install_conf {
        "rsync.exclude": ;
        "modules.conf": ;
    }

    file { "/etc/cobbler/pxe/pxedefault.template":
        content => template("cobbler/etc/cobbler/pxe/pxedefault.template"),
        require => Package["cobbler"],
    }


    exec { "cobbler-sync":
        command     => "cobbler sync",
        require     => Service["cobblerd"],
        refreshonly => true,
    }

    if $cobbler_manage_dhcp == "1" {
        service { "dhcpd": 
            require => Package["cobbler"],
        }
    }

    service { "cobblerd":
        require => Package["cobbler"],
    }

    service { "xinetd": }

    package { [ "cobbler", "cobbler-web", "dhcp", "yum-utils", "cman" ]: }


    define install_conf($module = "cobbler") {
        file { "/etc/cobbler/${name}":
            source  => "puppet:///${module}/etc/cobbler/${name}",
            notify  => Exec["cobbler-sync"],
            require => Package["cobbler"],
        }
    }

    define install_dhcpd_conf($module = "cobbler", $cobbler_dhcp_subnet = $network_eth0, $cobbler_dhcp_netmask = $netmask, $cobbler_dhcp_routers = $ipaddress, $cobbler_dhcp_dns = $ipaddress, $cobbler_dhcp_range = "192.168.0.10 192.168.0.100") {
        file { "/etc/cobbler/dhcp.template":
            content => template("${module}/etc/cobbler/dhcp.template"),
            notify  => Exec["cobbler-sync"],
            require => [ Package["cobbler"], Package["dhcp"] ],
        }
    }

    define install_kickstarts($module = "cobbler") {
        file { "/var/lib/cobbler/kickstarts/${name}":
            source => "puppet:///${module}/var/lib/cobbler/kickstarts/${name}",
            require => Package["cobbler"],
        }
    }

    define install_snippets_directory() {
        file { "/var/lib/cobbler/snippets/${name}":
            ensure  => directory,
            mode    => 755,
            require => Package["cobbler"],
        }
    }

    define install_snippets($module = "cobbler") {
        file { "/var/lib/cobbler/snippets/${name}":
            source  => "puppet:///${module}/var/lib/cobbler/snippets/${name}",
            mode    => 600,
            require => Package["cobbler"],
        }
    }

    define import_distro($path) {
        exec { "cobbler-add-distro-${name}-${architecture}":
            command => "cobbler import --name=\"${name}-${architecture}\" --path=\"${path}\" --arch=${architecture}",
            timeout => 1800,
            unless  => "test `cobbler distro find --name=\"${name}-${architecture}\"` = \"${name}-${architecture}\"",
            require => Service["cobblerd"],
        }
    }

    define add_image($file) {
        exec { "cobbler-add-image-${name}":
            command => "cobbler image add --name=\"${name}\" --file=\"${file}\" --image-type=direct",
            unless  => "test `cobbler image find --name=\"${name}\"` = \"${name}\"",
            require => Service["cobblerd"],
        }
    }

    define add_profile($distro, $base_distro = $distro, $kickstart = "", $repos = "", $kopts = "", $kopts_post = "", $ksmeta = "", $name_servers = "", $name_servers_search = "", $virt_auto_boot = 1, $virt_type = "", $virt_bridge = "") {
        $kickstart_param = $kickstart ? {
            ""      => "",
            default => "--kickstart=\"/var/lib/cobbler/kickstarts/${kickstart}\"",
        }
        $repos_param = $repos ? {
            ""      => "",
            default => "--repos=\"${repos}\"",
        }
        $name_servers_param = $name_servers ? {
            ""      => "",
            default => "--name-servers=\"${name_servers}\"",
        }
        $name_servers_search_param = $name_servers_search ? {
            ""      => "--name-servers-search=\"${domain}\"",
            default => "--name-servers-search=\"${name_servers_search}\"",
        }
        $virt_param = $virt_type ? {
            ""      => "",
            default => "--virt-type=\"${virt_type}\" --virt-bridge=\"${virt_bridge}\" --virt-auto-boot=${virt_auto_boot}",
        }

        exec { "cobbler-add-profile-${name}":
            command => "cobbler profile add --name=\"${name}\" --distro=\"${distro}\" ${kickstart_param} ${repos_param} --kopts=\"${kopts}\" --kopts-post=\"${kopts_post}\" --ksmeta=\"${ksmeta}\" ${name_servers_param} ${name_servers_search_param} ${virt_param}",
            unless  => "test `cobbler profile find --name=\"${name}\"` = \"${name}\"",
            require => [ Exec["cobbler-add-distro-${base_distro}"], Service["cobblerd"] ],
        }

        if $repos == "" {
            Exec["cobbler-add-profile-${name}"] {
                notify +> Exec["cobbler-edit-profile-repos-${name}"],
            }

            exec { "cobbler-edit-profile-repos-${name}":
                command     => "/usr/bin/cobbler_edit_profile_repos.sh ${name}",
                refreshonly => true,
                require     => File["/usr/bin/cobbler_edit_profile_repos.sh"],
            }
        }
    }

    define add_system($profile, $hostname, $gateway, $kopts = "", $kopts_post = "", $ksmeta = "", $power_type = "", $power_address = "", $power_user = "", $power_pass = "", $virt_type = "", $virt_cpus = 1, $virt_file_size = 0, $virt_path = "", $virt_ram = 0, $interface1 = "eth0", $interface1_type = "", $ip1, $mac1 = "", $subnet1, $virt_bridge1 = "", $interface2 = "eth1", $interface2_type = "", $ip2 = "", $mac2 = "", $subnet2 = "", $virt_bridge2 = "", $bonding_opts = "") {
        # base
        exec { "cobbler-add-system-${name}":
            command => "cobbler system add --name=\"${name}\" --profile=\"${profile}\" --hostname=\"${hostname}\" --gateway=${gateway} --kopts=\"${kopts}\" --kopts-post=\"${kopts_post}\" --ksmeta=\"${ksmeta}\"",
            unless  => "test `cobbler system find --name=\"${name}\"` = \"${name}\"",
            require => [ Exec["cobbler-add-profile-${profile}"], Service["cobblerd"] ],
            notify  => [ Exec["cobbler-sync"], Exec["cobbler-edit-system-interface-${name}-${interface1}"], Exec["cobbler-edit-system-interface-${name}-${interface2}"], Exec["cobbler-add-system-${name}-power"], Exec["cobbler-add-system-${name}-virt"] ],
        }

        # interface1
        cobbler::edit_system_interface { "${name}-${interface1}":
            base_name       => $name,
            interface       => $interface1,
            interface_type  => $interface1_type,
            interface2      => $interface2,
            mac1            => $mac1,
            ip              => $ip1,
            subnet          => $subnet1,
            virt_bridge     => $virt_bridge1,
            mac2            => $mac2,
            bonding_opts    => $bonding_opts,
        }

        # interface2
        cobbler::edit_system_interface { "${name}-${interface2}":
            base_name      => $name,
            interface      => $interface2,
            interface_type => $interface2_type,
            interface2     => $interface2,
            ip             => $ip2,
            mac1           => $mac2,
            subnet         => $subnet2,
            virt_bridge    => $virt_bridge2,
        }

        # power
        exec { "cobbler-add-system-${name}-power":
            command     => "cobbler system edit --name=\"${name}\" --power-type=\"${power_type}\" --power-address=\"${power_address}\" --power-user=\"${power_user}\" --power-pass=\"${power_pass}\" --power-id=\"${name}\"",
            unless      => "test -z \"${power_type}\"",
            refreshonly => true,
        }

        # virtualization
        exec { "cobbler-add-system-${name}-virt":
            command     => "cobbler system edit --name=\"${name}\" --virt-type=\"${virt_type}\" --virt-cpus=\"${virt_cpus}\" --virt-file-size=\"${virt_file_size}\" --virt-path=\"${virt_path}\" --virt-ram=\"${virt_ram}\"",
            unless      => "test -z \"${virt_type}\"",
            refreshonly => true,
        }
    }

    define edit_system_interface($base_name, $interface = "eth0", $interface_type = "", $mac1, $ip, $subnet = "255.255.255.0", $virt_bridge = "", $interface2 = "eth1", $mac2 = "", $bonding_opts = "") {
        $interface_param = $interface_type ? {
            "bridge_slave" => "--interface-type=bridge_slave --interface-master=br0",
            "bond_slave"   => "--interface-type=bond_slave --interface-master=bond0",
            default        => "",
        }
        exec { "cobbler-edit-system-interface-${name}":
            command     => "cobbler system edit --name=${base_name} --interface=${interface} --mac=${mac1} --static=1 ${interface_param}",
            unless      => "test -z \"${mac1}\"",
            refreshonly => true,
            require     => Exec["cobbler-add-system-${base_name}"],
            notify      => Exec["cobbler-edit-system-interface-${name}-mac2"],
        }

        exec { "cobbler-edit-system-interface-${name}-mac2":
            command     => "cobbler system edit --name=${base_name} --interface=${interface2} --mac=${mac2} --static=1 ${interface_param}",
            unless      => "test -z \"${mac2}\"",
            refreshonly => true,
            notify      => Exec["cobbler-edit-system-interface-${name}-virt-bridge"],
        }

        exec { "cobbler-edit-system-interface-${name}-virt-bridge":
            command     => "cobbler system edit --name=${base_name} --interface=${interface} --virt-bridge=${virt_bridge}",
            unless      => "test -z ${virt_bridge}",
            refreshonly => true,
            notify      => Exec["cobbler-edit-system-interface-${name}-network"],
        }

        $interface_network = $interface_type ? {
            "bridge_slave" => "br0",
            "bond_slave"   => "bond0",
            default        => $interface,
        }

        $interface_network_param = $interface_type ? {
            "bridge_slave" => "--interface-type=bridge",
            "bond_slave"   => "--interface-type=bond --bonding-opts=\"${bonding_opts}\"",
            default        => "",
        }

        exec { "cobbler-edit-system-interface-${name}-network":
            command     => "cobbler system edit --name=${base_name} --interface=${interface_network} --ip-address=${ip} --subnet=${subnet} --static=1 ${interface_network_param}",
            unless      => "test -z \"${ip}\"",
            refreshonly => true,
        }
    }

    define add_repo($createrepo_flags = "-c cache -d", $environment = "", $comment = "", $breed = "yum", $rpmlist = "", $priority = "1", $keep_updated = "True", $mirror) {
        exec { "cobbler-add-repo-${name}-${architecture}":
            command => "cobbler repo add --name=\"${name}-${architecture}\" --createrepo-flags=\"${createrepo_flags}\" --mirror=\"${mirror}\" --breed=\"${breed}\" --arch=\"${architecture}\" --environment=\"${environment}\" --comment=\"${comment}\" --rpm-list=\"${rpmlist}\" --priority=\"${priority}\" --keep-updated=\"${keep_updated}\"",
            unless  => "test `cobbler repo find --name=\"${name}-${architecture}\"` = \"${name}-${architecture}\"",
            require => Service["cobblerd"],
        }
    }

    define install_repo_cron() {
        cron { "cobbler-repo-cron-${name}":
            command => "/bin/sleep `/usr/bin/expr \$RANDOM \% 300`; /usr/bin/cobbler reposync --tries=3 --no-fail > /dev/null 2>&1",
            user    => root,
            hour    => 4,
            minute  => 45,
            require => Service["cobblerd"],
        }
    }

    define install_repo_cron_script($cobbler_reposync_url, $cobbler_reposync_repo_url) {
        cron { "cobbler-repo-cron-script-${name}":
            command => "/usr/bin/cobbler_reposync.sh",
            user    => root,
            hour    => 4,
            minute  => 45,
            require => [ Service["cobblerd"], Package["repoview"], File["/usr/bin/cobbler_reposync.sh"] ],
        }

        file { "/usr/bin/cobbler_reposync.sh":
            mode    => 755,
            content => template("cobbler/usr/bin/cobbler_reposync.sh"),
        }

        package { "repoview": }
    }
}
