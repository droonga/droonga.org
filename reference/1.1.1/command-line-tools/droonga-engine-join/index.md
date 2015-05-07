---
title: droonga-engine-join
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-engine-join` puts an orphan Droonga Engine node in an existing Droonga cluster as a new replica node.

For example, if there is an existing Droonga Engine node `192.168.100.50` which is a replica node in a cluster and you are logged in to a computer `192.168.100.10` which is already prepared orphan Engine node in the same network segment, the command line to put the joining node `192.168.100.10` in the cluster as a new replica node is:

~~~
(on 192.168.100.10)
$ droonga-engine-join --host 192.168.100.10 \
                      --receiver-host 192.168.100.10 \
                      --replica-source-host 192.168.100.50
Start to join a new node 192.168.100.10
       to the cluster of 192.168.100.50
                     via 192.168.100.10 (this host)
    port    = 10031
    tag     = droonga
    dataset = Default

Source Cluster ID: 8951f1b01583c1ffeb12ed5f4093210d28955988

Changing role of the joining node...
Configuring the joining node as a new replica for the cluster...
Registering new node to existing nodes...
Changing role of the source node...
Getting the timestamp of the last processed message in the source node...
The timestamp of the last processed message at the source node: 2015-05-07T02:39:50.334377Z
Setting new node to ignore messages older than the timestamp...
Copying data from the source node...
100% done (maybe 00:00:00 remaining)
Restoring role of the source node...
Restoring role of the joining node...
Done.
~~~

See also [the tutorial about adding new replica to a Droonga node](/tutorial/add-replica/).


## Parameters {#parameters}

`--no-copy`
: Don't copy data from the source node.
  If you specify this option, the node joins as a replica without synchronizing of data.

`--host=NAME`
: Host name of the new node to be joined.
  This is a required parameter.

`--replica-source-host=NAME`
: Host name of the soruce node in the cluster to join.
  This is a required parameter.

`--port=PORT`
: Port number to communicate with engine nodes.
  `10031` by default.

`--tag=TAG`
: Tag name to communicate with engine nodes.
  `droonga` by default.

`--dataset=NAME`
: Dataset name the node is going to join as a replica in.
  `Default` by default.

`--receiver-host=NAME`
: Host name of the computer you are running this command.
  A guessed host name of the computer, by default.

`--records-per-second=N`
: Maximum number of records to be copied per one second.
  `-1` means "no limit".
  `100` by default.

`--progress-interval-seconds=SECONDS`
: Interval seconds to report progress of data copying.
  `3` by default.

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

