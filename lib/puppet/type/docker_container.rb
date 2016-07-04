Puppet::Type.newtype(:docker_container) do
  desc "docker container"

  newproperty(:ensure) do
    desc "State of a container. Possible: present/running, absent, stopped"

    newvalue(:running) do
      provider.start
    end

    aliasvalue(:present, :running)

    newvalue(:absent) do
      provider.rm
    end

    newvalue(:stopped) do
      provider.stop
    end

    defaultto :running
  end

  newparam(:name, :namevar => true) { desc 'container name' }

  newproperty(:id) { }
  newproperty(:image) { }
  newparam(:command) { }
  newparam(:ports, :array_matching => :all) { }
  newparam(:volumes, :array_matching => :all) { }
  newparam(:environment, :array_matching => :all) { }
  newparam(:privileged) { newvalues(true, false) }
  newparam(:restart) { }
  newparam(:remove) { newvalues(true, false) }
  newparam(:cleanup_stopped) do
    desc <<-'EOT'
      When trying to start a container, try to clean up an old dead
      one if it still exists and was not removed.
    EOT

    newvalues(:true, :false)
  end

  autorequire(:service) { 'docker' }

end
