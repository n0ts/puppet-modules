Facter.add("raidtype") do
  confine :kernel => :linux
  ENV["PATH"]="/bin:/sbin:/usr/bin:/usr/sbin"
  setcode do
    raidtype = []
    if FileTest.exists?("/proc/mdstat")
      txt = File.read("/proc/mdstat")
      raidtype.push("software") if txt =~ /^md/i
    end

    lspciexists = system "/bin/bash -c 'which lspci >&/dev//null'"
    if $?.exitstatus == 0
      output = %x{lspci}
      output.each { |s|
        raidtype.push("hardware") if s =~ /RAID/i
      }
    end
    raidtype
  end
end
