---
title: Install
layout: en
---

# Overview

The main part of Droonga consists of two components: [droonga-engine][] and [droonga-http-server][].

<!--

## Steps to install Droonga by the installation script

There are useful installation scripts.
Download them and run it by `bash`, as the root:

~~~
# curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    bash
# curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    bash
~~~

After services are installed, you can run/stop them via the `service` command:

~~~
# service droonga-engine start
# service droonga-engine stop
# service droonga-http-server start
# service droonga-http-server stop
~~~

Now you are ready for building your own data processing system with Droonga. See [tutorial](/tutorial/) to get started.

NOTE: currently the installation script works only on several environments:

 * Debian GNU/Linux (latest release)
 * Ubuntu (latest release, latest LTS)
 * CentOS 7

Otherwise you have to install components manually.
See following descriptions.

## Details for manual installation

-->

## Dependencies

### Ruby

[droonga-engine][] requires [Ruby][].

### Node.js

[droonga-http-server][] requires [Node.js][].


# Ubuntu 14.04

## Install dependencies

    sudo apt-get install -y ruby ruby-dev build-essential nodejs nodejs-legacy npm

## Install droonga-engine

    sudo gem install droonga-engine

## Install droonga-http-server

    sudo npm install -g droonga-http-server

Now you are ready for building your own data processing system with Droonga. See [tutorial](/tutorial/) to get started.

<!--

For more details, see [tutorial for manual installation](../tutorial/manual-install/).

-->

  [Ruby]: http://www.ruby-lang.org/
  [Node.js]: http://nodejs.org/
  [droonga-engine]: https://github.com/droonga/droonga-engine
  [droonga-http-server]: https://github.com/droonga/droonga-http-server
