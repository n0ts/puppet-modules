Facter.add("kvm_host") do
  confine :kernel => :linux
  ENV["PATH"]="/bin:/sbin:/usr/bin:/usr/sbin"
  setcode do
    system("lsmod | grep kvm > /dev/null")
  end
end
