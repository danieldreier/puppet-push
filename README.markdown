## Overview

puppet-push provides a git-push based workflow for puppet apply.

## Description

Puppet Push provides an opinionated workflow for masterless puppet on a small
number of nodes. The puppet "push" face sets up a remote git repository with a
post-receive hook that runs r10k, then triggers a puppet apply of site.pp.

The resulting workflow looks something like:

Initial setup:
```shell
$ puppet push setup freebsd@web01.example.com
Notice: running puppet push setup on web01.example.com
Notice: Creating remote git repository at /home/freebsd/.puppet/push/deploy/repo
INFO [9cd66652] Running /usr/bin/env mkdir -p /home/freebsd/.puppet/push/deploy/repo as freebsd@web01.example.com
INFO [9cd66652] Finished in 0.051 seconds with exit status 0 (successful).
INFO [94699e23] Running /usr/bin/env mkdir -p /home/freebsd/.puppet/push/deploy/deploy as freebsd@web01.example.com
INFO [94699e23] Finished in 0.048 seconds with exit status 0 (successful).
INFO [1ae1eeae] Running /usr/bin/env pushd /home/freebsd/.puppet/push/deploy/repo; git init --bare; popd as freebsd@web01.example.com
INFO [1ae1eeae] Finished in 0.060 seconds with exit status 0 (successful).
INFO Uploading /home/freebsd/.puppet/push/deploy/repo/hooks/post-receive 100.0%
INFO [5f17092d] Running /usr/bin/env chmod +x /home/freebsd/.puppet/push/deploy/repo/hooks/post-receive as freebsd@web01.example.com
INFO [5f17092d] Finished in 0.049 seconds with exit status 0 (successful).
INFO Uploading /home/freebsd/.puppet/r10k.yaml 100.0%
freebsd@web01.example.com:/home/freebsd/.puppet/push/deploy/repo
```

Git deployment:
```shell
$ git push web01.example.com production
[production baae665] test
 1 file changed, 1 insertion(+)
Counting objects: 3, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 326 bytes | 0 bytes/s, done.
Total 3 (delta 1), reused 0 (delta 0)
-----> deploying branch production at commit baae665936fe39e8ebead473183cc024eff4e37c
-> detected change in: Puppetfile
-----> starting r10k code deployment
remote: INFO     -> Deploying environment /home/freebsd/.puppet/code/environments/production
remote: INFO     -> Deploying module /home/freebsd/.puppet/code/environments/production/modules/apt
remote: INFO     -> Deploying module /home/freebsd/.puppet/code/environments/production/modules/concat
remote: INFO     -> Deploying module /home/freebsd/.puppet/code/environments/production/modules/firewall
remote: INFO     -> Deploying module /home/freebsd/.puppet/code/environments/production/modules/ntp
remote: INFO     -> Deploying module /home/freebsd/.puppet/code/environments/production/modules/stdlib
-----> starting puppet run
remote: Notice: Compiled catalog for web01.example.com in environment production in 0.52 seconds
remote: Notice: puppet ran!
remote: Notice: /Stage[main]/Main/Node[default]/Notify[puppet ran!]/message: defined 'message' as 'puppet ran!'
remote: Notice: Applied catalog in 0.03 seconds
-----> puppet run complete
To freebsd@web01.example.com:/home/freebsd/.puppet/push/deploy/repo
   12206cb..baae665  production -> production
```

This is primarily aimed at the use case of ad-hoc management of one or two
servers where you just want to write a little bit of puppet and have it
applied, and don't want to deal with the overhead of figuring out code
deployment, an r10k webhook, etc.

## Setup

### What push affects
Push will create files in the ~/.puppet folder of the target system

Warning: If you're on FreeBSD and not using pkgng, the puppet install script
will automatically install it and update the system to use it.

### Setup Requirements

To get started, you must have:

- a control repo with at least a `site.pp` and a valid `Puppetfile`
- the control repo must be a git repository, with everything committed
- a host with puppet and r10k installed and available in the default path
- ssh key authentication enabled to that host
- passwordless sudo on that host, at least for the `puppet` command
- The `sshkit` gem must be installed locally to use the `puppet push` command

Additionally, you need an environment.conf in your control repo if you use
modules inside it, as in the roles and profiles pattern. (note: this has not
been tested yet; the project is still in development.

### Beginning with push

1. `cd` to wherever you store your control repo
2. run `puppet push setup username@host.example.com`
3. run `git push host.example.com production`

If you encounter problems, use the debug flag: `puppet push --debug setup username@host.example.com`


### Limitations

- you have to install puppet and r10k yourself
- private git repositories will only work if you have SSH agent forwarding turned on during a git push
- no workflow for deploying secrets (yet)
