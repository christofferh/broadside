def add_shared_deploy_configs(subcmd)
  # deployment always requires target
  subcmd.desc 'Deployment target to use, e.g. production_web'
  subcmd.arg_name 'TARGET'
  subcmd.flag [:t, :target], type: Symbol

  subcmd.action do |global_options, options, args|
    _DeployObj = Kernel.const_get("Broadside::#{Broadside.config.deploy.type.capitalize}Deploy")
    _DeployObj.new(options).public_send(subcmd.name)
  end
end

desc 'Deploy your application.'
command :deploy do |d|
  d.desc 'Deploys without running migrations'
  d.command :short do |subcmd|
    subcmd.desc 'Docker tag for application container'
    subcmd.arg_name 'TAG'
    subcmd.flag [:tag]

    add_shared_deploy_configs(subcmd)
  end

  d.desc 'Performs a full deployment (with migration)'
  d.command :full do |subcmd|
    subcmd.desc 'Docker tag for application container'
    subcmd.arg_name 'TAG'
    subcmd.flag [:tag]

    add_shared_deploy_configs(subcmd)
  end

  d.desc 'Scales application to a given count'
  d.command :scale do |subcmd|
    subcmd.desc 'Specify a new scale for application'
    subcmd.arg_name 'NUM'
    subcmd.flag [:s, :scale], type: Fixnum

    add_shared_deploy_configs(subcmd)
  end

  d.desc 'Creates a single instance of the application to run a command.'
  d.command :run do |subcmd|
    subcmd.desc 'Docker tag for application container'
    subcmd.arg_name 'TAG'
    subcmd.flag [:tag]

    subcmd.desc 'Command to run (wrap argument in quotes)'
    subcmd.arg_name 'COMMAND'
    subcmd.flag [:command], type: Array

    add_shared_deploy_configs(subcmd)
  end

  d.desc 'Rolls back n releases and deploys'
  d.command :rollback do |subcmd|
    subcmd.desc 'Number of releases to rollback'
    subcmd.arg_name 'COUNT'
    subcmd.flag [:r, :rollback], type: Fixnum

    add_shared_deploy_configs(subcmd)
  end

  d.desc 'Gets information about what is currently deployed.'
  d.command :status do |subcmd|
    add_shared_deploy_configs(subcmd)
  end

  d.desc 'Tail the logs inside the running container.'
  d.command :logtail do |subcmd|
    subcmd.desc '0-based instance index'
    subcmd.default_value 0
    subcmd.arg_name 'INSTANCE'
    subcmd.flag [:n, :instance], type: Fixnum

    subcmd.desc 'Number of lines to tail'
    subcmd.default_value 10
    subcmd.arg_name 'TAIL_LINES'
    subcmd.flag [:l, :lines], type: Fixnum

    add_shared_deploy_configs(subcmd)
  end

  d.desc 'Establish a secure shell on the instance running the container.'
  d.command :ssh do |subcmd|
    subcmd.desc '0-based instance index'
    subcmd.default_value 0
    subcmd.arg_name 'INSTANCE'
    subcmd.flag [:n, :instance], type: Fixnum

    add_shared_deploy_configs(subcmd)
  end

  d.desc 'Establish a shell inside the running container.'
  d.command :bash do |subcmd|
    subcmd.desc '0-based instance index'
    subcmd.default_value 0
    subcmd.arg_name 'INSTANCE'
    subcmd.flag [:n, :instance], type: Fixnum

    add_shared_deploy_configs(subcmd)
  end
end

