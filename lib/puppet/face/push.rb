require 'puppet/face'
require 'puppet/util/colors'
require 'puppet/application/push'
require 'puppet_x/push/push'

Puppet::Face.define(:push, '1.0.0') do
  summary 'Git push workflow for puppet apply'

  # Ensures that the user has the needed features to use puppet strings
  def check_required_features
    fail 'This face requires Ruby >= 1.9.' if RUBY_VERSION.match(/^1\.8/)
  end

  action(:setup) do
    default

    summary 'configure remote host for git push'
    arguments '[username@]hostname'

    when_invoked do |*args|
      check_required_features
      PuppetX::Push.git_setup(args[0..-2])
      ''
    end
  end
end
