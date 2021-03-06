Facter.add("dell_storage_controller") do
  setcode do
    Facter.loadfacts()

    is_virtual = Facter.value(:is_virtual)
    if is_virtual == true
      Facter.value(:virtual)
    end

    manufacturer = Facter.value(:manufacturer)
    if manufacturer != "Dell Inc."
      ""
    end

    omreport = "/usr/bin/omreport"
    if File.exist?(omreport)
      storage_controller = %x{#{omreport} storage controller}.chomp
      match_data = storage_controller.match(/^Name.*\:.*\n/)
      if match_data != nil and match_data[0] != nil
        split_data = match_data[0].split(":")
        if split_data.length == 2
          split_data[1].lstrip
        end
      end
    end
  end
end
