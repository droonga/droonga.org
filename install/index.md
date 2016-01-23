---
title: Install
layout: en
---

# Overview

The main part of Droonga consists of two components: [droonga-engine][] and [droonga-http-server][].

## Steps to install Droonga by the installation script

There are useful installation scripts.
Download them and run it by `bash`, as the root:

~~~
# curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    bash
# curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    bash
~~~

After services are installed, you can run/stop them via the `systemctl` command:

~~~
# systemctl start droonga-engine
# systemctl stop droonga-engine
# systemctl start droonga-http-server
# systemctl stop droonga-http-server
~~~

Now you are ready for building your own data processing system with Droonga. See [tutorial](/tutorial/) to get started.

NOTE: currently the installation script works only on several environments:

 * Debian GNU/Linux (latest release)
 * Ubuntu (latest release, latest LTS)
 * CentOS 7

## Dependencies

### Ruby

[droonga-engine][] requires [Ruby][].

### Node.js

[droonga-http-server][] requires [Node.js][].


  [Ruby]: http://www.ruby-lang.org/
  [Node.js]: http://nodejs.org/
  [droonga-engine]: https://github.com/droonga/droonga-engine
  [droonga-http-server]: https://github.com/droonga/droonga-http-server
