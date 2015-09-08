include ChefRvmCookbook::RvmProviderMixin
use_inline_resources
action :install do
  unless rvm.rvm?
    rvm.rvm_install
    new_resource.updated_by_last_action(true)
  end

  rubies = new_resource.rubies
  if rubies
    rubies = Array(rubies) if rubies.is_a?(String)
    rubies.each do |ruby_string, options|
      options ||= {}
      chef_rvm_ruby "#{new_resource.user}:#{ruby_string}" do
        user new_resource.user
        version ruby_string
        patch options['patch']
        default options['default']
      end
    end
  end
  create_or_update_rvmvc
end

action :upgrade do
  if rvm.rvm?
    Chef::Log.info "Upgrade RVM for user #{new_resource.user}"
    rvm.rvm_get(:stable)
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "Rvm is not installed for #{new_resource.user}"
  end
end

action :implode do
  if rvm.rvm?
    Chef::Log.info "Implode RVM for user #{new_resource.user}"
    rvm.rvm_implode
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "Rvm is not installed for #{new_resource.user}"
  end
end

def create_or_update_rvmvc
  if rvm.system?
    rvmrc_file = '/etc/rvmrc'
    gemrc_file = '/etc/gemrc'
    rvm_path = '/usr/local/rvm/'
  else
    rvmrc_file = "#{rvm.user_home}/.rvmrc"
    gemrc_file = "#{rvm.user_home}/.gemrc"
    rvm_path = "#{rvm.user_home}/.rvm"
  end

  template rvmrc_file do
    cookbook 'chef_rvm'
    source 'rvmrc.erb'
    owner new_resource.user
    mode '0644'
    variables(
      system_install: rvm.system?,
      rvmrc: new_resource.rvmrc_properties.merge(
        rvm_path: rvm_path
      )
    )
    action :create
  end

  template gemrc_file do
    cookbook 'chef_rvm'
    source 'gemrc.erb'
    owner new_resource.user
    mode '0644'
    variables(
        system_install: rvm.system?,
        gemrc: new_resource.gemrc_properties
    )
    action :create
  end
end
