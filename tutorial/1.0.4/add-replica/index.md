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
* Your `catalog.json` must have the plugin `system` in the list of plugins.
  Otherwise, you must add it, like:
  
      - "plugins": ["groonga", "crud", "search", "dump"],
      + "plugins": ["groonga", "crud", "search", "dump", "system"],
  

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

Assume that there is a Droonga cluster constructed with two replica nodes `192.168.0.10` and `192.168.0.11`, and we are going to add a new replica node `192.168.0.12`.

### Setup a new node

First, prepare a new computer, install required softwares and configure them.

    (on 192.168.0.12)
    # apt-get update
    # apt-get -y upgrade
    # apt-get install -y ruby ruby-dev build-essential nodejs nodejs-legacy npm
    # gem install droonga-engine
    # npm install -g droonga-http-server
    # mkdir ~/droonga

For the new node, you have to setup a `catalog.json` includes only one node, based on the existing one on another node.

    (on 192.168.0.12)
    # scp 192.168.0.10:~/droonga/catalog.json ~/droonga/
    # droonga-engine-modify-catalog --source=~/droonga/catalog.json \
                                    --update \
                                    --hosts=192.168.0.12

Let's start the server.

    (on 192.168.0.12)
    # cd ~/droonga
    # host=192.168.0.12
    # DROONGA_BASE_DIR=$PWD
    # droonga-engine --host=$host \
                     --log-file=$DROONGA_BASE_DIR/droonga-engine.log \
                     --daemon \
                     --pid-file=$DROONGA_BASE_DIR/droonga-engine.pid
    # env NODE_ENV=production \
        droonga-http-server --port=10041 \
                            --receive-host-name=$host \
                            --droonga-engine-host-name=$host \
                            --cache-size=-1 \
                            --daemon \
                            --pid-file=$DROONGA_BASE_DIR/droonga-http-server.pid

Then there are two separate Droonga clusters on this time.

 * The existing cluster including two replicas.
   Let's give a name *"alpha"* to it, for now.
   * `192.168.0.10`
   * `192.168.0.11`
 * The new cluster including just one replica.
   Let's give a name *"beta"* to it, for now.
   * `192.168.0.12`

You can confirm that, via the `system.status` command:

~~~
(for the cluster alpha)
# curl "http://192.168.0.10:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.0.11:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    }
  }
}
~~~

`192.168.0.10` and `192.168.0.11` are members of the cluster alpha, so they return same result.
`192.168.0.12` doesn't appear in the result because it is not a member of the cluster alpha.

On the other hand, `192.168.0.12` returns a result like:

~~~
(for the cluster beta)
# curl "http://192.168.0.12:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
~~~

It is a result for the cluster beta, so `192.168.0.10` and `192.168.0.11` don't appear.


### Suspend inpouring of "write" requests

Before starting  duplication of data, you must suspend inpouring of "write" requests to the cluster alpha, because we have to synchronize data in clusters alpha and beta completely.
Otherwise, the new added replica node will contain incomplete data.
Because data in replicas will be inconsistent, results for any request to the cluster become unstable.

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

### Duplicate data from the existing cluster to the new replica

Duplicate data from the cluster alpha to the cluster beta.
It can be done by the command `droonga-engine-absorb-data`.
Run it *on the new replica node*, like:

    (on 192.168.0.12)
    # droonga-engine-absorb-data --source-host=192.168.0.10 \
                                 --receiver-host=192.168.0.12

Note that you must specify the host name or the IP address of the new replica node itself, via the `--receiver-host` option.

### Join the new replica to the cluster

After the duplication is successfully done, join the new replica to the existing clster.
Update the `catalog.json` on the newly joining node `192.168.0.12`, like:

    (on 192.168.0.12)
    # droonga-engine-modify-catalog --source=~/droonga/catalog.json \
                                    --update \
                                    --add-replica-hosts=192.168.0.10,192.168.0.11

The server process detects new `catalog.json` and restats itself automatically.

Then there are two overlapping Droonga clusters theoretically on this time.

 * The existing cluster "alpha", including two replicas.
   * `192.168.0.10`
   * `192.168.0.11`
 * The new cluster including three replicas.
   Let's give a name *"charlie"* to it, for now.
   * `192.168.0.10`
   * `192.168.0.11`
   * `192.168.0.12`

You can confirm that, via the `system.status` command for each cluster:

~~~
(for the cluster alpha)
# curl "http://192.168.0.10:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.0.11:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    }
  }
}
~~~

Because `catalog.json` on nodes `192.168.0.10` and `192.168.0.11` have no change, the result says that there is still the cluster alpha with only two nodes.
Any incoming request to the cluster alpha is never delivered to the new replica `192.168.0.12` yet.

However, the new node `192.168.0.12` has a new `catalog.json`.
It knows the cluster charlie includes three nodes, even if other two existing nodes don't know that:

~~~
(for the cluster charlie)
# curl "http://192.168.0.12:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    },
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
~~~

Note that the temporary cluster named "beta" is gone.

Next, update existing `catalog.json` on other nodes, like:

    (on 192.168.0.10, 192.168.0.11)
    # droonga-engine-modify-catalog --source=~/droonga/catalog.json \
                                    --update \
                                    --add-replica-hosts=192.168.0.12

Servers detect new `catalog.json` and restart themselves automatically.

Then there is just one Droonga clusters on this time.

 * The new cluster "charlie",including three replicas.
   * `192.168.0.10`
   * `192.168.0.11`
   * `192.168.0.12`

You can confirm that, via the `system.status` command:

~~~
# curl "http://192.168.0.10:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    },
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.0.11:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    },
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.0.12:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    },
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
~~~

Any node returns same result.

Note that the old cluster named "alpha" is gone.
Now the new cluster "charlie" with three replicas works perfectly, instead of the old one with two replicas.

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

Assume that there is a Droonga cluster constructed with trhee replica nodes `192.168.0.10`, `192.168.0.11` and `192.168.0.12`, and planning to remove the last node `192.168.0.12` from the cluster.

### Unjoin an existing replica from the cluster

To remove a replica from an existing cluster, you just have to update the "catalog.json" with new list of replica nodes except the node to be removed:

    (on 192.168.0.10)
    # droonga-engine-modify-catalog --source=~/droonga/catalog.json \
                                    --update \
                                    --remove-replica-hosts=192.168.0.12

Then there are two overlapping Droonga clusters theoretically on this time.

 * The existing cluster "charlie" including three replicas.
   * `192.168.0.10`
   * `192.168.0.11`
   * `192.168.0.12`
 * The new cluster including two replicas.
   Let's give a name *"delta"* to it, for now.
   * `192.168.0.10`
   * `192.168.0.11`

You can confirm that, via the `system.status` command for each cluster:

~~~
(for the cluster charlie)
# curl "http://192.168.0.11:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    },
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.0.12:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    },
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
~~~

Because `catalog.json` on nodes `192.168.0.11` and `192.168.0.12` have no change, they still detect three nodes in the cluster charlie.

On the other hand, the node `192.168.0.10` with new `catalog.json` knows the cluster delta includes only two nodes:

~~~
(for the cluster delta)
# curl "http://192.168.0.10:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    }
  }
}
~~~

So the node `192.168.0.10` doesn't deliver incoming messages to the missing node `192.168.0.12` anymore.

Next, update existing `catalog.json` on other nodes, like:

    (on 192.168.0.11, 192.168.0.12)
    # droonga-engine-modify-catalog --source=~/droonga/catalog.json \
                                    --update \
                                    --remove-replica-hosts=192.168.0.12

Then there is only one Droonga cluster on this time.

 * The new cluster "delta" including two replicas.
   * `192.168.0.10`
   * `192.168.0.11`

You can confirm that, via the `system.status` command for each cluster:

~~~
(for the cluster delta)
# curl "http://192.168.0.10:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.0.11:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.0.12:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.11:10031/droonga": {
      "live": true
    }
  }
}
~~~

Any incoming request is delivered to member nodes of the cluster delta.
Because the orphan node `192.168.0.12` is not a member, it never process requests by self.

OK, the node is ready to be removed.
Stop servers and shutdown it if needed.

    (on 192.168.0.12)
    # kill $(cat ~/droonga/droonga-engine.pid)
    # kill $(cat ~/droonga/droonga-http-server.pid)

## Replace an existing replica node in a cluster with a new one

Replacing of nodes is a combination of those instructions above.

Assume that there is a Droonga cluster constructed with two replica nodes `192.168.0.10` and `192.168.0.11`, the node `192.168.0.11` is unstable, and planning to replace it with a new node `192.168.0.12`.

### Unjoin an existing replica from the cluster

First, remove the unstable node.
Re-generate `catalog.json` without the node to be removed, and spread it to other nodes in the cluster:

    (on 192.168.0.10)
    # droonga-engine-catalog-generate --hosts=192.168.0.10 \
                                      --output=~/droonga/catalog.json
    # scp ~/droonga/catalog.json 192.168.0.11:~/droonga/

After that the node `192.168.0.11` unjoins from the cluster successfully.

Now there is a cluster without the node `192.168.0.11`.
You can confirm that via the `system.status` command:

~~~
# curl "http://192.168.0.10:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    }
  }
}
~~~

### Add a new replica

Next, setup the new replica.
Construct a temporary cluster with only one node `192.168.0.12`.
The result of the `system.status` command will be:

~~~
# curl "http://192.168.0.12:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
~~~

Then, duplicate data from the existing cluster:

    (on 192.168.0.12)
    # droonga-engine-catalog-generate --hosts=192.168.0.12 \
                                      --output=~/droonga/catalog.json
    # drndump --host=192.168.0.10 \
              --receiver-host=192.168.0.12 | \
        droonga-request --host=192.168.0.12 \
                        --receiver-host=192.168.0.12

After the duplication successfully finished, the node is ready to join the cluster.
Re-generate `catalog.json` and spread it to all nodes in the cluster:

    (on 192.168.0.12)
    # droonga-engine-catalog-generate --hosts=192.168.0.10,192.168.0.12 \
                                      --output=~/droonga/catalog.json
    # scp ~/droonga/catalog.json 192.168.0.10:~/droonga/

Finally a Droonga cluster constructed with two nodes `192.168.0.10` and `192.168.0.12` is here.

You can confirm that, via the `system.status` command:

~~~
# curl "http://192.168.0.10:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.12:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.0.12:10041/droonga/system/status"
{
  "nodes": {
    "192.168.0.10:10031/droonga": {
      "live": true
    },
    "192.168.0.12:10031/droonga": {
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
