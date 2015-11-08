require 'puppet'
require 'sshkit'
require 'sshkit/dsl'
require "securerandom"

module PuppetX
end

module PuppetX::Push
  def self.install_puppet(hosts)
    unique_run_id = SecureRandom.hex(5)
    hosts.each do |raw_host|
      on raw_host do |host|
        Puppet.notice "pushing puppet install to #{host}"
        Puppet.debug "uploading puppet install script"
        install_script = File.open(File.join(File.dirname(__FILE__),
                                                'install_puppet.sh'))
        install_script_path = "/tmp/install_puppet_#{unique_run_id}.sh"
        upload! install_script, install_script_path
        execute("chmod +x #{install_script_path}", out: $stdout, err: $stderr)
        Puppet.notice "executing puppet install script at #{install_script_path}"
        puts capture("sh #{install_script_path}", out: $stdout, err: $stderr)
        execute("rm -f #{install_script_path}", out: $stdout, err: $stderr)

        Puppet.notice "using puppet to install git"
        execute("puppet resource package git ensure=present", out: $stdout, err: $stderr)
        execute("puppet resource package sudo ensure=present", out: $stdout, err: $stderr)
        execute("puppet resource package r10k ensure=present provider=gem", out: $stdout, err: $stderr)
      end
    end
  end

  def self.git_setup(hosts)

    # hosts is an array of hosts names, optionally prefixed with user names:
    # hosts = ['www-data@web01.example.com', 'web02.example.com']
    # we iterate over hosts instead of letting sshkit do it so that we get
    # the full string including the username, to set up a git remote
    hosts.each do |raw_host|
      on raw_host do |host|
        Puppet.notice "running puppet push setup on #{host}"

        # set some basic path variables
        home        = capture('echo $HOME')
        code_path   = '.puppet/push/deploy'
        repo_path   = File.join(home, code_path, 'repo')
        deploy_path = File.join(home, code_path, 'deploy')

        # create a remote git repository
        Puppet.debug "checking for a remote git repository at #{repo_path}/HEAD"
        unless test "[ -f #{repo_path}/HEAD ]"
          Puppet.notice "Creating remote git repository at #{repo_path}"
          execute("mkdir -p #{repo_path}")
          execute("mkdir -p #{deploy_path}")
          execute("cd #{repo_path}; git init --bare; cd $OLDPWD")
        end

        # upload post-receive hook
        hook_path = File.join(home, '.puppet', 'push', 'deploy', 'repo',
                              'hooks', 'post-receive')
        Puppet.debug "Creating remote post-receive hook at #{hook_path}"
        post_receive_hook = File.open(File.join(File.dirname(__FILE__),
                                                'post-receive'))
        upload! post_receive_hook, hook_path
        execute "chmod +x #{hook_path}"

        # create and upload an r10k configuration file
        r10k_conf = <<-CONFIG
---
cachedir: #{home}/.puppet/r10k
sources:
  puppet:
    basedir: #{home}/.puppet/code/environments
    remote:  #{home}/.puppet/push/deploy/repo
CONFIG
        contents = StringIO.new(r10k_conf)
        upload! contents, File.join(home, '.puppet', 'r10k.yaml')

        # configure a git remote locally
        if system("git config remote.#{host}.url")
          Puppet.debug 'detected existing local git remote, skipping setup'
        else
          Puppet.notice 'no git remote detected, setting up'
          system("git remote add #{host} #{raw_host}:#{repo_path}", out: $stdout, err: $stderr)

          git_branch = `git symbolic-ref HEAD`.split('/').last
          Puppet.notice "you can now do a git push to #{host} with:"
          Puppet.notice "git push #{host} #{git_branch}"
        end
      end
    end
  end
end
