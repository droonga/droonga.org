---
title: droonga-engine-unjoin
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-engine-unjoin` removes a Droonga Engine node from an existing Droonga cluster.

For example, if there is an existing Droonga Engine node `192.168.100.50` which is a replica node in a cluster and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to remove the node `192.168.100.50` from the cluster is:

~~~
(on 192.168.100.10)
$ droonga-engine-unjoin --host 192.168.100.50 \
                        --receiver-host 192.168.100.10
Start to unjoin a node 192.168.100.50:10031/droonga
                    by 192.168.100.10 (this host)

Unjoining replica from the cluster...
Done.
~~~

See also [the tutorial about adding new replica to a Droonga cluster](/tutorial/add-replica/).


## Parameters {#parameters}

`--host=NAME`
: Host name of the node to be removed.
  A guessed host name of the computer you are running the command, by default.

`--port=PORT`
: Port number to communicate with the engine node.
  `10031` by default.

`--tag=TAG`
: Tag name to communicate with the engine node.
  `droonga` by default.

`--dataset=NAME`
: Dataset name the node is going to be removed from.
  `Default` by default.

`--receiver-host=NAME`
: Host name of the computer you are running this command.
  A guessed host name of the computer, by default.

`--verbose`
: Output details for internal operations.
  This is mainly for debugging.

`-h`, `--help`
: Shows the usage of the command.

## How to install {#install}

This is installed as a part of a rubygems package `droonga-engine`.

~~~
# gem install droonga-engine
~~~

