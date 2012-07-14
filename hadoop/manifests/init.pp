#
# hadoop module
#

class hadoop {
    if $hadoop_conf_module == "" {
        notice "Failed to setting hadop_conf_module variable."
    }
    if $hadoop_major_version == "" {
        $hadoop_major_version = "0.20"
    }
    if $hadoop_version == "" {
        $hadoop_version = ""
    }
    if $hadoop_conf == "" {
        $hadoop_conf = "empty"
    }
    if $hadoop_priority == "" {
        $hadoop_priority = "50"
    }
    if $hadoop_create_user == "" {
        $hadoop_create_user = false
    }

    if $hadoop_yumrepo == "" {
        package { "hadoop-${hadoop_version}": }
    } else {
        package { "hadoop-${hadoop_version}":
            require => Yumrepo[$hadoop_yumrepo],
        }
    }

    if $hadoop_namenode == true {
        $hadoop_dfs_dir = true
        file { "/var/lib/hadoop-${hadoop_major_version}/cache/hadoop/dfs/name":
            ensure  => directory,
            mode    => 775,
            owner   => hdfs,
            group   => hadoop,
            require => File["/var/lib/hadoop-${hadoop_major_version}/cache/hadoop/dfs"],
        }
    }
    if $hadoop_jobtracker == true {
        if $hadoop_dfs_dir == ture {
            $hadoop_dfs_dir = true
        }
    }
    if $hadoop_secondarynamenode == true {
        $hadoop_dfs_dir = true
        file { "/var/lib/hadoop-${hadoop_major_version}/cache/hadoop/dfs/namesecondary":
            ensure  => directory,
            mode    => 775,
            owner   => hdfs,
            group   => hadoop,
            require => File["/var/lib/hadoop-${hadoop_major_version}/cache/hadoop/dfs"],
        }
    }
    if $hadoop_tasktracker == true {
        $hadoop_dfs_dir = true
    }

    file { "/etc/hadoop-${hadoop_major_version}/conf.${hadoop_conf}":
        source  => "puppet:///${hadoop_conf_module}/etc/hadoop-${hadoop_major_version}/conf.${hadoop_conf}",
        recurse => true,
        require => Package["hadoop-${hadoop_version}"],
        notify  => Exec["hadoop_conf-${hadoop_conf}"],
    }

    # $ alternatives --display hadoop-${hadoop_version}-conf
    exec { "hadoop_conf-${hadoop_conf}":
        command     => "alternatives --install /etc/hadoop-${hadoop_major_version}/conf hadoop-${hadoop_major_version}-conf /etc/hadoop-${hadoop_major_version}/conf.${hadoop_conf} ${hadoop_priority}",
        refreshonly => true,
        require     => [ Package["hadoop-${hadoop_version}"], File["/etc/hadoop-${hadoop_major_version}/conf.${hadoop_conf}"] ],
    }

    file { "/var/lib/hadoop-${hadoop_major_version}":
        ensure  => directory,
        mode    => 775,
        owner   => root,
        group   => hadoop,
        require => Package["hadoop-${hadoop_version}"],
    }

    file { "/var/lib/hadoop-${hadoop_major_version}/cache":
        ensure  => directory,
        mode    => 775,
        owner   => root,
        group   => hadoop,
        require => File["/var/lib/hadoop-${hadoop_major_version}"],
    }

    file { "/var/lib/hadoop-${hadoop_major_version}/cache/hadoop":
        ensure  => directory,
        mode    => 775,
        owner   => root,
        group   => hadoop,
        require => File["/var/lib/hadoop-${hadoop_major_version}/cache"],
    }

    if $hadoop_dfs_dir == "" {
        $hadoop_dfs_dir = false
    }
    if $hadoop_dfs_dir == true {
        file { "/var/lib/hadoop-${hadoop_major_version}/cache/hadoop/dfs":
            ensure  => directory,
            mode    => 775,
            owner   => hdfs,
            group   => hadoop,
            require => File["/var/lib/hadoop-${hadoop_major_version}/cache/hadoop"],
        }
    }

    if $hadoop_lzo == true {
        file { "/usr/lib/hadoop/lib/hadoop-lzo-0.4.4.jar":
            source  => "puppet:///hadoop/usr/lib/hadoop/lib/hadoop-lzo-0.4.4.jar",
            require => [ Package["hadoop-${hadoop_version}"], Package["lzop"] ],
        }

        file { "/usr/lib/hadoop/lib/native":
            source  => "puppet:///hadoop/usr/lib/hadoop/lib/native",
            recurse => true,
            require => Package["hadoop-${hadoop_version}"],
        }

        package { "lzop": }
    }

    if $hadoop_create_user == true {
        user { "hdfs":
            home    => "/home/hdfs",
            shell   => "/bin/bash",
            require => [ Package["hadoop-${hadoop_version}"], File["/home/hdfs"] ],
        }
        install_home_dir { "hdfs":
            authorized_keys => $hadoop_user_ssh_authorized_keys,
        }

        user { "mapred":
          home    => "/home/mapred",
          shell   => "/bin/bash",
          require => [ Package["hadoop-${hadoop_version}"], File["/home/mapred"] ],
        }
        install_home_dir { "mapred":
            authorized_keys => $hadoop_user_ssh_authorized_keys,
        }
    }


    define install_home_dir($authorized_keys) {
        file { "/home/${name}":
            ensure  => directory,
            owner   => $name,
            group   => hadoop,
            mode    => 700,
            require => Package["hadoop-${hadoop_version}"],
        }

        file { "/home/${name}/.ssh":
            ensure  => directory,
            owner   => $name,
            group   => hadoop,
            mode    => 700,
            require => File["/home/${name}"],
        }

        file { "/home/${name}/.ssh/authorized_keys":
            owner   => $name,
            group   => hadoop,
            mode    => 600,
            content => $authorized_keys,
            require => File["/home/${name}/.ssh"],
        }
    }
}
