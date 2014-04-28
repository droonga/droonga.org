---
title: "Droonga tutorial: How to migrate from Groonga?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to run a Droonga cluster by your hand, and use it as a [Groonga][groonga] compatible server.

## Precondition

* You must have basic knowledge and experiences to set up and operate an [Ubuntu][] Server.
* You must have basic knowledge and experiences to use the [Groonga][groonga] via HTTP.

## What's Droonga?

It is a data processing engine based on a distributed architecture, named after the terms "distributed-Groonga".
As its name suggests, it can work as a Groonga compatible server with some improvements - replication and sharding.

In a certain sense, the Droonga is quite different from Groonga, about its architecture, design, API etc.
However, you don't have to understand the whole architecture of the Droonga, if you simply use it just as a Groonga compatible server.

For example, let's try to build a database system to find [Starbucks stores in New York](http://geocommons.com/overlays/430038).

## Set up a Droonga cluster

### Prepare an environment for experiments

Prepare a computer at first.
This tutorial describes steps to set up a Droonga cluster based on existing computers.
Following instructions are basically written for a successfully prepared virtual machine of the `Ubuntu 13.10 x64` on the service [DigitalOcean](https://www.digitalocean.com/), with an available console.

NOTE: Make sure to use instances with >= 2GB memory equipped, at least during installation of required packages for Droonga.
Otherwise, you may experience a strange build error.

You need to prepare two or more computers for effective replication.

### Steps to install Droonga components

Groonga provides binary packages and you can install Groonga easily, for some environments.
(See: [how to install Groonga](http://groonga.org/docs/install.html))

However, currently there is no such an easy way to set up a database system based on Droonga.
We are planning to provide a better way (like a chef cookbook), but for now, you have to set up it by your hand.

A database system based on the Droonga is called *Droonga cluster*.
A Droonga cluster is constructed from multiple computers, called *Droonga node*.
So you have to set up multiple Droonga nodes for your Droonga cluster.

Assume that you have two computers: `192.168.0.10` and `192.168.0.11`.

 1. Install required platform packages, *on each computer*.
    
        # apt-get update
        # apt-get -y upgrade
        # apt-get install -y ruby ruby-dev build-essential nodejs npm
    
 2. Install a gem package `droonga-engine`, *on each computer*.
    It is the core component provides most features of Droonga system.
    
        # gem install droonga-engine
    
 3. Install an npm package `droonga-http-server`, *on each computer*.
    It is the frontend component required to translate HTTP requests to Droonga's native one.
    
        # npm install -g droonga-http-server
    
 4. Prepare a configuration directory for a Droonga node, *on each computer*.
    All physical databases are placed under this directory.
    
        # mkdir ~/droonga
        # cd ~/droonga
    
 5. Create a `catalog.json`, *on one of Droonga nodes*.
    The file defines the structure of your Droonga cluster.
    You'll specify the name of the dataset via the `--dataset` option and the list of your Droonga node's IP addresses via the `--nodes` option, like:
    
        # droonga-catalog-generate --dataset=Starbucks \
                                   --nodes=192.168.0.10,192.168.0.11 \
                                   --output=./catalog.json
    
    If you have only one computer and trying to set up it just for testing, then you'll do:
    
        # droonga-catalog-generate --dataset=Starbucks \
                                   --nodes=127.0.0.1 \
                                   --output=./catalog.json
    
 6. Share the generated `catalog.json` *to your all Droonga nodes*.
    
        # scp ~/droonga/catalog.json 192.169.0.2:~/droonga/
    
    (Or, of course, you can generate same `catalog.json` on each computer, instead of copying.)

All Droonga nodes for your Droonga cluster are prepared by steps described above.
Let's continue to the next step.

## Use the Droonga cluster, via HTTP

### Start and stop services on each Droonga node

You can run Groonga as an HTTP server with the option `-d`, like:

    # groonga -p 3000 -d --protocol http /tmp/databases/db

On the other hand, you have to run two servers for each Droonga node to use your Droonga cluster via HTTP.

To start them, run commands like following on each Droonga node:

    # cd ~/droonga
    # host=192.168.0.10
    # droonga-engine --host=$host &
    # cat $! > droonga-engine.pid
    # droonga-http-server --port=3000 \
                          --receive-host-name=$host \
                          --droonga-engine-host-name=$host \
                          --default-dataset=Starbucks \
                          --daemon \
                          --pid-file droonga-http-server.pid

Note that you have to specify the host name of the Droonga node itself via some options.
It will be used to communicate with other Droonga nodes in the cluster.
So you have to specify different host name on another Droonga node, like:

    # cd ~/droonga
    # host=192.168.0.11
    # droonga-engine --host=$host &
    ...

To stop services, run commands like following on each Droonga node:

    # kill $(cat ~/droonga/droonga-engine.pid)
    # kill $(cat ~/droonga/droonga-http-server.pid)

### Create a table

TBD

### Load data to a table

TBD

### Select data from a table

TBD

## Conclusion

In this tutorial, you did set up a [Droonga][] cluster on [Ubuntu Linux][Ubuntu] computers.
Moreover, you load data to it and select data from it successfully, as a [Groonga][] compatible server.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
