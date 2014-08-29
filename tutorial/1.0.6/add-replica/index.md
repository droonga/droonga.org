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
* Your `catalog.json` must have `system` and `catalog` plugins in the list of plugins.
  Otherwise, you must add them, like:
  
      - "plugins": ["groonga", "crud", "search", "dump"],
      + "plugins": ["groonga", "crud", "search", "dump", "system", "catalog"],
  

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

Assume that there is a Droonga cluster constructed with two replica nodes `192.168.100.50` and `192.168.100.51`, and we are going to add a new replica node `192.168.100.52`.

### Setup a new node

First, prepare a new computer, install required softwares and configure them.

    (on 192.168.100.52)
    # apt-get update
    # apt-get -y upgrade
    # apt-get install -y ruby ruby-dev build-essential nodejs nodejs-legacy npm
    # gem install droonga-engine
    # npm install -g droonga-http-server
    # mkdir ~/droonga
    # echo "host: 192.168.100.52" > ~/droonga/droonga-engine.yaml

Then generate the `catalog.json` with only one replica, the new node itself:

    (on 192.168.100.52)
    # droonga-engine-catalog-generate --hosts=192.168.100.52 \
                                      --output=~/droonga/catalog.json

Note, you cannot add a non-empty node to an existing cluster.
If the computer was used as a Droonga node in old days, then you must clear old data at first.

    (on 192.168.100.52)
    # kill $(cat ~/droonga/droonga-engine.pid)
    # rm -rf ~/droonga
    # mkdir ~/droonga
    # droonga-engine-catalog-generate --hosts=192.168.100.52 \
                                      --output=~/droonga/catalog.json

Let's start the server.

    (on 192.168.100.52)
    # host=192.168.100.52
    # export DROONGA_BASE_DIR=$HOME/droonga
    # droonga-engine
    # droonga-http-server --port=10041 \
                          --receive-host-name=$host \
                          --droonga-engine-host-name=$host \
                          --environment=production \
                          --cache-size=-1 \
                          --daemon \
                          --pid-file=$DROONGA_BASE_DIR/droonga-http-server.pid

Currently, the new node doesn't work as a node of the cluster, because it doesn't appear in the `catalog.json`.
Even if you send requests to the new node, it just forwards all of them to other existing members of the cluster.

You can confirm that, via the `system.status` command:

~~~
# curl "http://192.168.100.50:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.100.51:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.100.52:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
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

    (on 192.168.100.52)
    # cd ~/droonga
    # droonga-engine-join --host=192.168.100.52 \
                          --replica-source-host=192.168.100.50
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
# curl "http://192.168.100.50:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
      "live": true
    },
    "192.168.100.52:10031/droonga": {
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

Assume that there is a Droonga cluster constructed with trhee replica nodes `192.168.100.50`, `192.168.100.51` and `192.168.100.52`, and planning to remove the last node `192.168.100.52` from the cluster.

### Unjoin an existing replica from the cluster

To remove a replica from an existing cluster, you just run the `droonga-engine-unjoin` command on any existing node in the cluster, in the directory the `catalog.json` is located, like:

    (on 192.168.100.50)
    # cd ~/droonga
    # droonga-engine-unjoin --host=192.168.100.52
    Unjoining replica from the cluster...
    ...
    Done.

 * You must specify the host name or the IP address of an existing node to be removed from the cluster, via the `--host` option.
 * You must run the command in the directory `catalog.json` is located, or specify path to the directory via the `--base-dir` option.

Then the specified node automatically unjoins from the cluster, and all nedes' `catalog.json` are also updated.
Now, the node has been successfully unjoined from the cluster.

You can confirm that, via the `system.status` command:

~~~
# curl "http://192.168.100.50:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.100.51:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.100.52:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
      "live": true
    }
  }
}
~~~

## Replace an existing replica node in a cluster with a new one

Replacing of nodes is a combination of those instructions above.

Assume that there is a Droonga cluster constructed with two replica nodes `192.168.100.50` and `192.168.100.51`, the node `192.168.100.51` is unstable, and planning to replace it with a new node `192.168.100.52`.

### Unjoin an existing replica from the cluster

First, remove the unstable node.
Remove the node from the cluster, like:

    (on 192.168.100.50)
    # cd ~/droonga
    # droonga-engine-unjoin --host=192.168.100.51

Now the node has been gone.
You can confirm that via the `system.status` command:

~~~
# curl "http://192.168.100.50:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    }
  }
}
~~~

### Add a new replica

Next, setup the new replica.
Install required packages, generate the `catalog.json`, and start services.

    (on 192.168.100.52)
    # host=192.168.100.52
    # export DROONGA_BASE_DIR=$HOME/droonga
    # echo "host: $host" > $DROONGA_BASE_DIR/droonga-engine.yaml
    # droonga-engine-catalog-generate --hosts=$host \
                                      --output=$DROONGA_BASE_DIR/catalog.json
    # droonga-engine
    # droonga-http-server --port=10041 \
                          --receive-host-name=$host \
                          --droonga-engine-host-name=$host \
                          --environment=production \
                          --cache-size=-1 \
                          --daemon \
                          --pid-file=$DROONGA_BASE_DIR/droonga-http-server.pid

Then, join the node to the cluster.

    (on 192.168.100.52)
    # cd ~/droonga
    # droonga-engine-join --host=192.168.100.52 \
                          --replica-source-host=192.168.100.50

Finally a Droonga cluster constructed with two nodes `192.168.100.50` and `192.168.100.52` is here.

You can confirm that, via the `system.status` command:

~~~
# curl "http://192.168.100.50:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.52:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.100.52:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.52:10031/droonga": {
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
