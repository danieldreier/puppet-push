# Class: push
# ===========================
#
# This only exists so that puppet will recognize push as a valid module.
# All the interesting stuff happens in the "push" puppet face.
#
# the sshkit gem is a dependency of the puppet face
#
class push {
  package {'sshkit':
    ensure   => present,
    provider => gem,
  }
}
