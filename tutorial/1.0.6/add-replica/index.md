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

In this case you don't have to stop the cluster working, for any read-only requests like "search".
You can add a new replica, in the backstage, without downing your service.

On the other hand, you have to stop inpouring of new data to the cluster until the new node starts working.
(In the future we'll provide mechanism to add new nodes completely silently without any stopping of data-flow, but currently can't.)

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
# service start droonga-engine
# service start droonga-http-server
~~~

Currently, the new node doesn't work as a node of the existing cluster.
You can confirm that, via the `system.status` command:

~~~
$ curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node1:10031/droonga": {
      "live": true
    }
  }
}
$ curl "http://node1:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node1:10031/droonga": {
      "live": true
    }
  }
}
$ curl "http://node2:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node2:10031/droonga": {
      "live": true
    }
  }
}
~~~

### Suspend inpouring of "write" requests

Before starting to change cluster composition, you must suspend inpouring of "write" requests to the cluster, because we have to synchronize data to the new replica.
Otherwise, the new added replica will contain incomplete data and results for requests to the cluster become unstable.

What's "write" request?
In particular, these commands modify data in the cluster:

 * `add`
 * `column_create`
 * `column_remove`
 * `delete`
 * `load`
 * `table_create`
 * `table_remove`

If you load new data via the `load` command triggered by a batch script started as a cronjob, disable the job.
If a crawler agent adds new data via the `add` command, stop it.
If you put a fluentd as a buffer between crawler or loader and the cluster, stop outgoing messages from the buffer. 

If you are reading this tutorial sequentially after the [previous topic](../dump-restore/), there is no incoming requests, so you have nothing to do.

### Joining a new replica node to the cluster

To add a new replica node to an existing cluster, you just run a command `droonga-engine-join` on one of existing replica nodes or the new replica node, in the directory the `catalog.json` is located, like:

    (on node2)
    # droonga-engine-join --host=node2 \
                          --replica-source-host=node0
    Joining new replica to the cluster...
    ...
    Update existing hosts in the cluster...
    ...
    Done.

 * You must specify the host name or the IP address of the new replica node, via the `--host` option.
 * You must specify the host name or the IP address of an existing node of the cluster, via the `--replica-source-host` option.

Then the command automatically starts to synchronize all data of the cluster to the new replica node.
After data is successfully synchronized, the node restarts and joins to the cluster automatically.
All nodes' `catalog.json` are also updated, and now, yes, the new node starts working as a replica in the cluster.

You can confirm that, via the `system.status` command:

~~~
# curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node1:10031/droonga": {
      "live": true
    },
    "node2:10031/droonga": {
      "live": true
    }
  }
}
~~~

### Resume inpouring of "write" requests

OK, it's the time.
Because all replica nodes are completely synchronized, the cluster now can process any request stably.
Resume inpouring of requests which can modify the data in the cluster - cronjobs, crawlers, buffers, and so on.

With that, a new replica node has joined to your Droonga cluster successfully.


## Remove an existing replica node from an existing cluster

A Droonga node can die by various fatal reasons - for example, OOM killer, disk-full error, troubles around its hardware, etc.
Because nodes in a Droonga cluster observe each other and they stop delivering messages to dead nodes automatically, the cluster keeps working even if there are some dead nodes.
Then you have to remove dead nodes from the cluster.

Of course, even if a node is still working, you may plan to remove it to reuse for another purpose.

Assume that there is a Droonga cluster constructed with trhee replica nodes `node0`, `node1` and `node2`, and planning to remove the last node `node2` from the cluster.

### Unjoin an existing replica from the cluster

To remove a replica from an existing cluster, you just run the `droonga-engine-unjoin` command on any existing node in the cluster, in the directory the `catalog.json` is located, like:

    (on node0)
    # cd ~/droonga
    # droonga-engine-unjoin --host=node2
    Unjoining replica from the cluster...
    ...
    Done.

 * You must specify the host name or the IP address of an existing node to be removed from the cluster, via the `--host` option.
 * You must run the command in the directory `catalog.json` is located, or specify path to the directory via the `--base-dir` option.

Then the specified node automatically unjoins from the cluster, and all nedes' `catalog.json` are also updated.
Now, the node has been successfully unjoined from the cluster.

You can confirm that, via the `system.status` command:

~~~
# curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node1:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://node1:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node1:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://node2:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node1:10031/droonga": {
      "live": true
    }
  }
}
~~~

## Replace an existing replica node in a cluster with a new one

Replacing of nodes is a combination of those instructions above.

Assume that there is a Droonga cluster constructed with two replica nodes `node0` and `node1`, the node `node1` is unstable, and planning to replace it with a new node `node2`.

### Unjoin an existing replica from the cluster

First, remove the unstable node.
Remove the node from the cluster, like:

    (on node0)
    # cd ~/droonga
    # droonga-engine-unjoin --host=node1

Now the node has been gone.
You can confirm that via the `system.status` command:

~~~
# curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    }
  }
}
~~~

### Add a new replica

Next, setup the new replica.
Install required packages, generate the `catalog.json`, and start services.

    (on node2)
    # export DROONGA_BASE_DIR=$HOME/droonga
    # echo "host:        node2"      >  $DROONGA_BASE_DIR/droonga-engine.yaml
    # echo "port:        10041"      >  $DROONGA_BASE_DIR/droonga-http-server.yaml
    # echo "environment: production" >> $DROONGA_BASE_DIR/droonga-http-server.yaml
    # droonga-engine-catalog-generate --hosts=$host \
                                      --output=$DROONGA_BASE_DIR/catalog.json
    # droonga-engine
    # droonga-http-server --cache-size=-1

Then, join the node to the cluster.

    (on node2)
    # droonga-engine-join --host=node2 \
                          --replica-source-host=node0

Finally a Droonga cluster constructed with two nodes `node0` and `node2` is here.

You can confirm that, via the `system.status` command:

~~~
# curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node2:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://node2:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node2:10031/droonga": {
      "live": true
    }
  }
}
~~~

## Conclusion

In this tutorial, you did add a new replica node to an existing [Droonga][] cluster.
Moreover, you did remove an existing replica, and did replace a replica with a new one.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
