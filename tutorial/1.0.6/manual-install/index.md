---
title: "Droonga tutorial: How to setup Droonga services without installation script?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to setup a Droonga node manually, without installation script.

## Why manual install?

The installation script of `droonga-engine` and `droonga-http-server` works only on several environments, for now:

 * Debian GNU/Linux (latest release)
 * Ubuntu (latest release, latest LTS)
 * CentOS 7

Otherwise, you have to install services maually.
(If you have knowledge to support other platforms, please send a pull request!)

This tutorial describes how to setup `droonga-engine` and `droonga-http-server` without installation script.

## Requirements

 * 2GB or larger size RAM.
   Because the gem package `rroonga` (required by `droonga-engine`) includes a native extension, you won't be able to install it successfully if you have only less RAM.
 * Available `gem` command for the RubyGems.
 * Available `npm` command for the npmjs.org.

## Steps to install services

 1. Install platform packages required to install `gem` and `npm` packages with native extensions.
    For example, on an Ubuntu server you'll have to install these packages via `apt`: `ruby`, `ruby-dev`, `build-essential`, `nodejs`, `nodejs-legacy`, and `npm`.
    On a CentOS 6.x server, you can prepare required environment by these steps:
    
        # yum -y groupinstall development
        # curl -L get.rvm.io | bash -s stable
        # source /etc/profile.d/rvm.sh
        # rvm reload
        # rvm install 2.1.2
        # yum -y install npm
    
 2. Install a gem package `droonga-engine`.
    It is the core component provides most features of Droonga system.
    
        # gem install droonga-engine
    
 3. Install an npm package `droonga-http-server`.
    It is the frontend component required to translate HTTP requests to Droonga's native one.
    
        # npm install -g droonga-http-server
    
 4. Prepare users for each service.
    All configuration files and physical databases are placed under their home directories.
    
        # useradd -m droonga-engine
        # useradd -m droonga-http-server
    
 5. Prepare a configuration directory `droonga` under the home directory of each user.
    
        # mkdir ~droonga-engine/droonga
        # mkdir ~droonga-http-server/droonga
    
 6. Define an accessible host name or an IP address of the computer, for the node name.
    [It must be resolvable from other computers.](../groonga/#accessible-host-name)
    
        # host=192.168.100.50
    
 7. Create a `droonga-engine.yaml` and `catalog.json` for `droonga-engine`.
    Currently you have to specify the name of the node itself.
    
        # cd ~droonga-engine/droonga
        # droonga-engine-configure --quiet --reset-config --reset-catalog \
                                   --host=$host \
                                   --daemon \
                                   --pid-file=droogna-engine.pid
        # chown -R droogna-engine:droonga-engine ~droonga-engine/droonga
    
 8. Create a `droonga-http-server.yaml` for `droonga-http-server`.
    Currently you have to specify the host name of the droonga-engine node and the name of the node itself.
    For example, if both services work on the computer:
    
        # cd ~droonga-http-server/droonga
        # droonga-http-server-configure --quiet --reset-config \
                                        --droonga-engine-host-name=$host \
                                        --receiver-host-name=$host \
                                        --daemon \
                                        --pid-file=droonga-http-server.pid
        # chown -R droogna-http-server:droonga-http-server ~droonga-http-server/droonga

## How to start services {#start-services}

To start the `droonga-engine` service, run the `droonga-engine` command in the configuration directory, like:

    # cd ~droonga-engine/droonga
    # sudo -u droogna-engine -H droonga-engine

To start the `droonga-http-server` service, run the `droonga-http-server` command in the configuration directory, like:

    # cd ~droonga-http-server/droonga
    # sudo -u droogna-http-server -H droonga-http-server

Then, PID files are automatically generated and services start as daemons.

## How to stop services {#stop-services}

To stop the `droonga-engine` service, run the `droonga-engine-stop` command, like:

    # cd ~droonga-engine/droonga
    # sudo -u droogna-engine -H droonga-engine-stop

To start the `droonga-http-server-stop` service, run the `droonga-http-server` command, like:

    # cd ~droonga-http-server/droonga
    # sudo -u droogna-http-server -H droonga-http-server-stop

These commands automatically detect the location of PID files and stop daemon processes.

