desc 'Bootstrap your service and task definition from the configured definition.'
command :bootstrap do |b|
  add_shared_deploy_configs(b)
end
