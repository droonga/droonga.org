---
title: "Droonga tutorial: How to add a new replica to an existing cluster?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to add a new replica node, remove an existing replica, and replace a replica with new one, for your existing [Droonga][] cluster.

## Precondition

* You must have an existing Droonga cluster with some data.
  Please complete the ["getting started" tutorial](../groonga/) before this.
* You must know how to duplicate data between multiple clusters.
  Please complete the ["How to backup and restore the database?" tutorial](../dump-restore/) before this.

This tutorial assumes that there are two existing Droonga nodes prepared by the [first tutorial](../groonga/): `node0` (`192.168.100.50`) and `node1` (`192.168.100.51`), and there is another computer `node2` (`192.168.100.52`) for a new node.
If you have Droonga nodes with other names, read `node0`, `node1` and `node2` in following descriptions as yours.

## What's "replica"?

There are two axes, "replica" and "slice", for Droonga nodes.

All "replica" nodes have completely equal data, so they can process your requests (ex. "search") parallelly.
You can increase the capacity of your cluster to process increasing requests, by adding new replicas.

On the other hand, "slice" nodes have different data, for example, one node contains data of the year 2013, another has data of 2014.
You can increase the capacity of your cluster to store increasing data, by adding new slices.

Currently, for a Droonga cluster which is configured as a Groonga compatible system, only replicas can be added, but slices cannot be done.
We'll improve extensibility for slices in the future.

Anyway, this tutorial explains how to add a new replica node to an existing Droogna cluster.
Here we go!

## Add a new replica node to an existing cluster

*To do "hot-add" (dynamic changing of cluster members without downtime) a new replica to a cluster, you must have two or more existing replicas in the cluster.*
While the operation is in progress, one of existing replicas becomes the "source" to copy data to the newly added replica, and other replicas provide the service.

If you have only one replica in the cluster, *you must stop any modification on the database until the operation completely finishes*.
Otherwise, databases in each replica can be irregularity.
This is the list of typical built-in commands which can modify the database:

 * `add`
 * `column_create`
 * `column_remove`
 * `delete`
 * `load`
 * `table_create`
 * `table_remove`

However, messages which never change existing data (like `search`, `system.status`, and others) are still acceptable.
In short, *you only have to stop your crawler while new replica is being added*, when there is no extra existing replica.

Assume that there is a Droonga cluster constructed with two replica nodes `node0` and `node1`, and we are going to add a new replica node `node2`.

### Setup a new node

First, prepare a new computer, install required softwares and configure them.

~~~
(on node2)
# curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    HOST=node2 bash
# curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    ENGINE_HOST=node2 HOST=node2 bash
~~~

Note, you cannot add a non-empty node to an existing cluster.
If the computer was used as a Droonga node in old days, then you must clear old data at first.

~~~
(on node2)
# droonga-engine-configure --quiet \
                           --clear --reset-config --reset-catalog \
                           --host=node2
# droonga-http-server-configure --quiet --reset-config \
                                --droonga-engine-host-name=node2 \
                                --receive-host-name=node2
~~~

Let's start services.

~~~
(on node2)
# service droonga-engine start
# service droonga-http-server start
~~~

Currently, the new node doesn't work as a node of the existing cluster.
You can confirm that, via the `system.status` command:

~~~
$ curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "status": "active"
    },
    "node1:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
$ curl "http://node2:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node2:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
~~~

### Setting up constant inpouring messages

If you are reading this tutorial sequentially after the [previous topic](../dump-restore/), you'll have no inpouring messages to the cluster yet.
To try hot-adding, let's prepare a virtual data source which adds new records constantly, like:

~~~
(on node0)
$ count=0; maxcount=500; \
  while [ "$count" -lt "$maxcount" ]; \
  do \
    droonga-add --host node0 --table Store --key "dummy-store$count" --name "Dummy Store $count"; \
    count=$(($count + 1)); \
    sleep 1; \
  done
~~~

This is an example to add totally 500 records (1 record for every seconds.)
`droonga-add` is one of Droonga's command line utilities, but currently you don't have to know details.

### Joining a new replica node to the cluster

To add a new replica node to an existing cluster, you just run the command `droonga-engine-join` on one of existing replica nodes or the new replica node, like:

~~~
(on node2)
$ droonga-engine-join --host=node2 \
                      --replica-source-host=node0 \
                      --receiver-host=node2
Start to join a new node node2
       to the cluster of node0
                     via node2 (this host)
    port    = 10031
    tag     = droonga
    dataset = Default

Source Cluster ID: 8951f1b01583c1ffeb12ed5f4093210d28955988

Changing role of the joining node...
Configuring the joining node as a new replica for the cluster...
Registering new node to existing nodes...
Changing role of the source node...
Getting the timestamp of the last processed message in the source node...
The timestamp of the last processed message at the source node: xxxx-xx-xxTxx:xx:xx.xxxxxxZ
Setting new node to ignore messages older than the timestamp...
Copying data from the source node...
100% done (maybe 00:00:00 remaining)
Restoring role of the source node...
Restoring role of the joining node...
Done.
~~~

You can run the command on different node, like:

~~~
(on node1)
$ droonga-engine-join --host=node2 \
                      --replica-source-host=node0 \
                      --receiver-host=node1
Start to join a new node node2
       to the cluster of node0
                     via node1 (this host)
...
~~~

 * You must specify the host name (or the IP address) of the new replica node, via the `--host` option.
 * You must specify the host name (or the IP address) of an existing node of the cluster, via the `--replica-source-host` option.
 * You must specify the host name (or the IP address) of the working machine via the `--receiver-host` option.

Then the command automatically starts to synchronize all data of the cluster to the new replica node.
After all data is successfully synchronized, the new node starts working as a replica in the cluster seamlessly.

With that, a new replica node has successfully joined to your Droonga cluster.
You can confirm that they are working as a cluster, via the `system.status` command:

~~~
$ curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "status": "active"
    },
    "node1:10031/droonga": {
      "status": "active"
    },
    "node2:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
~~~

Because the new node `node2` has become a member of the cluster, `droonga-http-server` on each node distributes messages to `node2` also automatically.


## Remove an existing replica node from an existing cluster

A Droonga node can die by various fatal reasons - for example, OOM killer, disk-full error, troubles around its hardware, etc.
Because nodes in a Droonga cluster observe each other and they stop delivering messages to dead nodes automatically, the cluster keeps working even if there are some dead nodes.
Then you have to remove dead nodes from the cluster.

Of course, even if a node is still working, you may plan to remove it to reuse for another purpose.

Assume that there is a Droonga cluster constructed with trhee replica nodes `node0`, `node1` and `node2`, and planning to remove the last node `node2` from the cluster.

### Unjoin an existing replica from the cluster

To remove a replica from an existing cluster, you just run the `droonga-engine-unjoin` command on any existing node in the cluster, like:

~~~
(on node0)
$ droonga-engine-unjoin --host=node2 \
                        --receiver-host=node0
Start to unjoin a node node2
                    by node0 (this host)

Unjoining replica from the cluster...
...
Done.
~~~

 * You must specify the host name (or the IP address) of an existing node to be removed from the cluster, via the `--host` option.
 * You must specify the host name (or the IP address) of the working machine via the `--receiver-host` option.

Then the specified node automatically unjoins from the cluster, and all nedes' `catalog.json` are also updated.
Now, the node has been successfully unjoined from the cluster.

You can confirm that the `node2` is successfully unjoined, via the `system.status` command:

~~~
$ curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "status": "active"
    },
    "node1:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
$ curl "http://node1:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "status": "active"
    },
    "node1:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
$ curl "http://node2:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node2:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
~~~

Because the node `node2` is not a member of the cluster anymore, `droonga-http-server` on `node0` and `node1` never send messages to the `droonga-engine` on `node2`.
On the other hand, because `droonga-http-server` on `node2` is associated only to the `droonga-engine` on same node, it never sends messages to other nodes.



## Replace an existing replica node in a cluster with a new one

Replacing of nodes is a combination of those instructions above.

Assume that there is a Droonga cluster constructed with two replica nodes `node0` and `node1`, the node `node1` is unstable, and planning to replace it with a new node `node2`.

### Unjoin an existing replica from the cluster

First, remove the unstable node.
Remove the node from the cluster, like:

~~~
(on node0)
$ droonga-engine-unjoin --host=node1
~~~

Now the node has been gone.
You can confirm that via the `system.status` command:

~~~
$ curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
~~~

### Add a new replica

Next, setup the new replica `node2`.
Install required packages, generate the `catalog.json`, and start services.

~~~
(on node2)
# curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    HOST=node2 bash
# curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    ENGINE_HOST=node2 HOST=node2 bash
~~~

If the computer was used as a Droonga node in old days, then you must clear old data instead of installation:

~~~
(on node2)
# droonga-engine-configure --quiet \
                           --clear --reset-config --reset-catalog \
                           --host=node2
# droonga-http-server-configure --quiet --reset-config \
                                --droonga-engine-host-name=node2 \
                                --receive-host-name=node2
~~~

Then, join the node to the cluster.

~~~
(on node2)
$ droonga-engine-join --host=node2 \
                      --replica-source-host=node0
~~~

Finally a Droonga cluster constructed with two nodes `node0` and `node2` is here.

You can confirm that, via the `system.status` command:

~~~
$ curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "status": "active"
    },
    "node2:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
$ curl "http://node2:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "status": "active"
    },
    "node2:10031/droonga": {
      "status": "active"
    }
  },
  "reporter": "..."
}
~~~

## Conclusion

In this tutorial, you did add a new replica node to an existing [Droonga][] cluster.
Moreover, you did remove an existing replica, and did replace a replica with a new one.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
