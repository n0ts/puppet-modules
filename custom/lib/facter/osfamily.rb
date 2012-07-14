Facter.add("osfamily") do
  setcode do
    Facter.loadfacts()

    distid = Facter.value(:lsbdistid)
    if distid.match(/RedHatEnterprise|CentOS|Fedora/)
      family = "redhat"
    elsif distid == "ubuntu"
      family = "debian"
    else
      family = distid
    end
    family
  end
end
