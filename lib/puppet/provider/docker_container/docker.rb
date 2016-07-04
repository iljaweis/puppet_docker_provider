require 'json'

Puppet::Type.type(:docker_container).provide(:docker) do

  commands :docker => '/bin/docker'
  def self.instances
    instances = []
    containers_by_id.each do |id|
      instances << new(
      :ensure => container_state(id),
      :id => id,
      :name => inspect_container(id, '.Name').sub('/', ''),
      :image => inspect_container(id, '.Config.Image')
      )
    end
    instances
  end

  def self.inspect_container(name, field)
    docker(['inspect','-f',"{{#{field}}}",name]).to_s.chomp
  end

  def inspect_container(name, field)
    docker(['inspect','-f',"{{#{field}}}",name]).to_s.chomp
  end

  def self.prefetch(resources)
    containers = instances
    resources.keys.each do |name|
      if provider = containers.find { |c| c.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.containers_by_id
    docker(%w[ps -a --no-trunc=true]).split("\n").select { |x| !x.match(/^CONTAINER ID/)}.map { |x| x.split(/\s+/)[0] }
  end

  def self.container_state(name, exists=false)
    begin
      case inspect_container(name, '.State.Running')
      when 'true'
        :running
      when 'false'
        :stopped
      else
        :absent
      end
    rescue Puppet::ExecutionFailure => e
      false
    end
  end

  def start
    self.debug("start #{@resource[:name]}, current state=#{@property_hash[:ensure]}")
    if @property_hash[:ensure] == :stopped
      if @resource[:cleanup_stopped] == :true
        self.debug("#{@resource[:name]} is stopped, trying to remove and create new")
        docker(['rm','-f',@resource[:name]])
        create_container
      else
        self.debug("#{@resource[:name]} is stopped, trying to start")
        docker(['start',@resource[:name]])
        @property_hash[:ensure] = :running
      end
    else
      self.debug("#{@resource[:name]} does not exist, trying to create")
      create_container
    end
  end

  def stop
    self.debug("stop #{@resource[:name]}, current state=#{@property_hash[:ensure]}")
    docker(['stop',@resource[:name]])
    @property_hash[:ensure] = :stopped
  end

  def rm
    self.debug("remove #{@resource[:name]}, current state=#{@property_hash[:ensure]}")
    docker(['rm','-f',@resource[:name]])
    @property_hash[:ensure] = :absent
  end

  def create_container
    self.debug("create_container #{resource[:name]}")

    docker_cmd = ["run", "-d", "--name=#{@resource[:name]}"]

    if @resource[:privileged] == true
      docker_cmd << '--privileged'
    end
    if @resource[:ports].is_a?(String)
      docker_cmd << ["-p", @resource[:ports]]
    elsif @resource[:ports].is_a?(Array)
      @resource[:ports].each do |p|
        docker_cmd << ["-p", p]
      end
    end
    if @resource[:volumes].is_a?(String)
      docker_cmd << ["-v", @resource[:volumes]]
    elsif @resource[:volumes].is_a?(Array)
      @resource[:volumes].each do |v|
        docker_cmd << ["-v", v]
      end
    end
    if @resource[:environment].is_a?(String)
      docker_cmd << ["-e", @resource[:environment]]
    elsif @resource[:environment].is_a?(Array)
      @resource[:environment].each do |e|
        docker_cmd << ["-e", e]
      end
    end
    if @resource[:restart].is_a?(String) and @resource[:restart].length > 0
      docker_cmd << ["--restart=#{@resource[:restart]}"]
    end
    if @resource[:remove] == true
      docker_cmd << ["--rm"]
    end
    docker_cmd << @resource[:image]
    docker_cmd << @resource[:command].split(/\s+/) if @resource[:command].is_a?(String)
    self.debug("Running docker #{docker_cmd}")
    r = docker(docker_cmd)
    self.debug("Result from running docker: #{r}")
    @property_hash[:ensure] = :running
  end

  def exists?
    self.debug("exists? ensure in property_hash: #{@property_hash[:ensure]}")
    [:present, :running, :stopped].include?(@property_hash[:ensure])
  end

  def ensure
    @property_hash[:ensure]
  end

  def ensure=(e)
  end

  def image
    @property_hash[:image]
  end

  def image=(i)
  end

  def id
    @property_hash[:id]
  end

  def id=(i)
  end

  def command
    @property_hash[:command]
  end

  def command=(c)
  end

  def ports
    @property_hash[:ports]
  end

  def ports=(p)
  end

  def volumes
    @property_hash[:volumes]
  end

  def volumes=(v)
  end

  def privileged
    @property_hash[:privileged]
  end

  def privileged=(p)
  end

  def environment
    @property_hash[:environment]
  end

  def environment=(e)
  end

  def restart
    @property_hash[:restart]
  end

  def restart=(r)
  end

  def remove
    @property_hash[:remove]
  end

  def remove=(r)
  end

  def cleanup_stopped
    @property_hash[:cleanup_stopped]
  end

  def cleanup_stopped=(c)
  end

end
