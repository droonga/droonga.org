---
title: droonga-engine-set-role
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-engine-set-role` changes the role of a Droonga Engine node to any specified role.

A Droonga Engine node determines that an incoming message should be processed by self or not, based on [the messaeg's `targetRole` field](../../message/#request-targetRole).
[The `droonga-engine-join` command](../droonga-engine-join/) changes role of operated nodes, so if its operation is unexpectedly aborted, those nodes can stay inactive as a service provider.
Then you can reactivate nodes by changing of their role with this command.

For example, if there is an existing Droonga Engine node `192.168.100.50` used as a source node for newly joining replica node, and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to reactivate the node `192.168.100.50` is:

~~~
(on 192.168.100.10)
$ droonga-engine-set-role --host 192.168.100.50 \
                          --role service-provider
Setting role of 192.168.100.50:10031/droonga to service-provider...
Done.
~~~

See also [the tutorial about adding new replica to a Droonga cluster](/tutorial/add-replica/).


## Parameters {#parameters}

`--role=ROLE`
: New role for the engine node.
  This is a required parameter.
  Possible values:
  
  * `service-provider`:
    The node is activated as a service provider.
  * `absorb-source`:
    The node is deactivated as a service provider and becomes to a source node to copy data.
  * `absorb-destination`:
    The node is deactivated as a service provider and becomes to a destination node to copy data.

`--host=NAME`
: Host name of the engine node to be changed its role.
  A guessed host name of the computer you are running the command, by default.

`--port=PORT`
: Port number to communicate with the engine node.
  `10031` by default.
  
  This value is not used to process this operation actually, but used to identify the node itself.

`--tag=TAG`
: Tag name to communicate with the engine node.
  `droonga` by default.
  
  This value is not used to process this operation actually, but used to identify the node itself.

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

