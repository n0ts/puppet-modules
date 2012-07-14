#set global $local_name      = $getVar('local_name', '')
#set global $user_name       = $getVar('user_name', '')
#set global $group_name      = $getVar('group_name', 'wheel')
#set global $fstype          = $getVar('fstype', 'ext4')
#set global $fsoptions       = $getVar('fsoptions', '')
#set global $partition       = $getVar('partition', 'default')
#set global $swap_size       = $int($getVar('swap_size', 0))
#set global $disk_size       = $getVar('disk_size', '100 --grow')
#set global $serial_port     = $getVar('serial_port', 'ttyS0')
#set global $baud_rate       = $getVar('baud_rate', 115200)
#set global $virt_num        = $int($getVar('virt_num', 0))
#set global $virt_host_type  = $getVar('virt_host_type', '')
#set global $virt_guest_type = $getVar('virt_guest_type', '')

#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
# System bootloader configuration
bootloader --location=mbr --append="console=tty0 console=$serial_port,$baud_rate"
# Partition clearing information
clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
firewall --enabled
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
$SNIPPET('network_config')
# Reboot after installation
reboot

# Root password
$SNIPPET($local_name + '/rootpw')

# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone  Asia/Tokyo
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr


%include /tmp/partinfo

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')

# Magically figure out how to partition this thing
$SNIPPET('centos/pre_partition_calc_swap')
$SNIPPET('centos/partition_select_' + $partition)

%packages
$SNIPPET('func_install_if_enabled')
$SNIPPET('puppet_install_if_enabled')
$SNIPPET('centos/packages')
$SNIPPET($local_name + '/packages.local')

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('centos/post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('puppet_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')

$SNIPPET($local_name + '/posts.local')

$SNIPPET('centos/posts')
$SNIPPET('centos/posts_grub_conf')
$SNIPPET('centos/posts_partition')
$SNIPPET('centos/posts_iptables')
$SNIPPET('centos/posts_noipv6')
$SNIPPET('centos/posts_ssh')
$SNIPPET('centos/posts_vendor')
$SNIPPET('centos/posts_yum')

#if $virt_host_type != ""
#if $virt_host_type == "xen"
$SNIPPET('centos/posts_xen_dom0')
#else if $virt_host_type == "kvm"
$SNIPPET('centos/posts_kvm_host')
#end if
$SNIPPET('centos/posts_host_virt')
#end if
#if $virt_guest_type == "xen"
$SNIPPET('centos/posts_xen_domu')
#end if

$SNIPPET('centos/posts_local_user')

# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps
