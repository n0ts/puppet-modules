Facter.add("raidcontroller") do
  confine :kernel => :linux
  ENV["PATH"]="/bin:/sbin:/usr/bin:/usr/sbin"
  setcode do
    controllers = []
    lspciexists = system "/bin/bash -c 'which lspci >&/dev//null'"
    if $?.exitstatus == 0
      output = %x{lspci}
      output.each {|s|
        controllers.push($1) if s =~ /RAID bus controller: (.*)/
      }
    end
    controllers
  end
end
