---
title: "Droonga tutorial: How to prepare virtual machines for experiments?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to prepare multiple (three) virtual machines for experiments.

## Why virtual machines?

Because Droonga is a distributed data processing system, you have to prepare multiple computers to construct a cluster.
For safety (and good performance) you should use dedicated computers for Droonga nodes.

You need two or more computers for effective replication.
If you are trying to manage node structure of your cluster effectively, three or more computers are required.

However, it may cost money that using multiple server instances on virtual private server services, even if you just want to do testing or development.
So we recommend you to use private virtual machines on your own PC for such cases.

Luckly, there is a useful software [Vagrant][] to manage virtual machines easily.
This tutorial describes *how to prepare three virtual machines* by Vagrant.

## Prepare a host machine

First, you have to prepare a PC as the host of VMs.
Because each VM possibly requires much size RAM for building of native extensions, the host machine should have much more RAM - hopefully, 8GB or larger.

In most cases you don't have to prepare much size RAM for each VM because there are pre-built binaries for major platforms.
However, if your VM is running with a minor distribution or an edge version, there may be no binary package for your platform. Then it will be compiled automatically, requiring 2GB RAM.
If you see any strange error while building native extensions, enlarge the size of RAM of each VM and try installation again.
(See also the [appendix of this tutorial](#less-size-memory).)

## Steps to prepare VMs

### Install the VirtualBox

The Vagrant requires a backend to run VMs, so you have to install the most recommended one: [VirtualBox][].
For example, if you use an [Ubuntu][] PC, it can be installed via the `apt` command, like:

~~~
$ sudo apt-get install virtualbox
~~~

Otherwise go to the [VirtualBox web site][VirtualBox] and install it as instructed.

### Install the Vagrant

Next, install [Vagrant][].
Go to the [Vagrant web site][Vagrant] and install it as instructed.
For example, if you use an Ubuntu PC (x64):

~~~
$ wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.6.5_x86_64.deb
$ sudo dpkg -i vagrant_1.6.5_x86_64.deb
~~~

NOTE: You can install Vagrant via `apt-get install vagrant` on Ubuntu 14.04, but don't use it because the version is too old to import boxes from [Vagrant Cloud][].

### Determine a box and prepare a Vagrantfile

Go to the [Vagrant Cloud][] and find a box for your experiments.
For example, if you use a [box for Ubuntu Trusty (x64)](https://vagrantcloud.com/ubuntu/boxes/trusty64), you just have to do:

~~~
$ mkdir droonga-ubuntu-trusty
$ cd droonga-ubuntu-trusty
$ vagrant init ubuntu/trusty64
~~~

Then a file `Vagrantfile` is automatically generated there.
However you should rewrite it completely for experiments of Droonga cluster, like following:

`Vagrantfile`:

~~~
n_machines = 3
box        = "ubuntu/trusty64"

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  n_machines.times do |index|
    config.vm.define :"node#{index}" do |node_config|
      node_config.vm.box = box
      node_config.vm.network(:private_network,
                             :ip => "192.168.100.#{50 + index}")
      node_config.vm.host_name = "node#{index}"
      node_config.vm.provider("virtualbox") do |virtual_box|
        virtual_box.memory = 2048
      end
    end
  end
end
~~~

Note, this `Vagrantfile` defines three VMs with 2GB (2048MB) RAM for each.
So your host machine must have 6GB or more RAM.
If your machine has less RAM, set the size to `512` (meaning 512MB) for now.

### Start virtual machines

To start VMs, you just run the command `vagrant up`:

~~~
$ vagrant up
Bringing machine 'node0' up with 'virtualbox' provider...
Bringing machine 'node1' up with 'virtualbox' provider...
Bringing machine 'node2' up with 'virtualbox' provider...
...
~~~

Then Vagrant automatically downloads VM image from the [Vagrant Cloud][] web site and starts VMs.
After preparation processes, there are three running VMs with IP address in a virtual private network: `192.168.100.50`, `192.168.100.51`, and `192.168.100.52`.

Let's confirm that they are correctly working.
You can log in those VMs by the command `vagrant ssh`, like:

~~~
$ vagrant ssh node0
Welcome to Ubuntu 14.04.1 LTS (GNU/Linux 3.13.0-36-generic x86_64)
...
vagrant@node0:~$ exit
~~~


### Register your VMs to your SSH client

You have to use `vagrant ssh` instead of regular `ssh`, to log in VMs.
Moreover you have to `cd` to the `Vagrantfile`'s directory before running the command.
It is annoying a little.

So, let's register VMs to your local config file of the SSH client, like:

~~~
$ vagrant ssh-config node0 >> ~/.ssh/config
$ vagrant ssh-config node1 >> ~/.ssh/config
$ vagrant ssh-config node2 >> ~/.ssh/config
~~~

After that you can log in to your VMs from the host computer by their name, without `vagrant ssh` command:

~~~
$ ssh node0
~~~

### Configure your VMs to access each other by their host name

Because there is no name server, each VM cannot resolve host names of others.
So you have to type their raw IP addresses for now.
It's very annoying.

So, let's modify hosts file on VMs, like:

`/etc/hosts`:

~~~
127.0.0.1 localhost
192.168.100.50 node0
192.168.100.51 node1
192.168.100.52 node2
~~~

After that your VMs can communicate with each other by their host name.

### Shutdown VMs

You can shutdown all VMs by the command `vagrant halt`:

~~~
$ vagrant halt
~~~

Then Vagrant shuts down all VMs completely.

### Cleanup VMs

If you want to clear all changes in VMs, then simply remove the hidden `.vagrant` directory in the `Vagrantfile`'s directory:

~~~
$ vagrant halt
$ rm -rf .vagrant
$ vagrant up
~~~

Then all changes will go away and you can start fresh VMs again.
This will help you to improve installation scripts or something.

### Appendix: if your host machine has less size RAM... {#less-size-memory}

Even if your computer has less size RAM, you don't have to give up.

2GB RAM for each virtual machine is required just for building native extensions of [Rroonga][].
In other words, Droonga nodes can work with less size RAM, if there are existing (already built) binary libraries.

So you can install Droonga services for each VM step by step, like:

 1. Shutdown all VMs by `vagrant halt`.
 2. Open the VirtualBox console by `virtualbox`.
 3. Go to `properties` of a VM, and enlarge the size of RAM to 2GB (2048MB).
 4. Start the VM, from the VirtualBox console.
 5. Log in to the VM and install Droonga services.
 6. Shutdown the VM.
 7. Go to `properties` of the VM, and decrease the size of RAM to the original size.
 8. Repeat steps from 3 to 7 for each VM.

## Conclusion

In this tutorial, you did prepare three virtual machines for Droonga nodes.

You can try [the "getting started" tutorial](../groonga/) and others with multiple nodes.

  [Vagrant]: https://www.vagrantup.com/
  [Vagrant Cloud]: https://vagrantcloud.com/
  [VirtualBox]: https://www.virtualbox.org/
  [Groonga]: http://groonga.org/
  [Rroonga]: https://github.com/ranguba/rroonga
  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
