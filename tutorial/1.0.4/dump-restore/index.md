---
title: "Droonga tutorial: How to backup and restore the database?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to backup and restore data by your hand.

## Precondition

* You must have an existing [Droonga][] cluster with some data.
  Please complete the ["getting started" tutorial](../groonga/) before this.
* Your `catalog.json` must have the dataset `Default`.
  Otherwise, you must change the name of the dataset, like:

        "datasets": {
      -   "Starbucks": {
      +   "Default": {
  
* Your `catalog.json` must have the plugin `dump` in the list of plugins.
  Otherwise, you must add the plugin to the list of `plugins`, like:
  
      - "plugins": ["groonga", "crud", "search"],
      + "plugins": ["groonga", "crud", "search", "dump"],
  
* Your `catalog.json` must not have any information in its `schema` section.
  Otherwise, you must make the `schema` section empty, like:
  
      "datasets": {},
  

## Backup data in a Droonga cluster

### Install `drndump`

First, install a command line tool named `drndump` via rubygems:

    # gem install droonga-engine

After that, establish that the `drndump` command has been installed successfully:

    # drndump --version
    drndump 1.0.0

### Dump all data in a Droonga cluster

The `drndump` command extracts all schema and data as JSONs.
Let's dump contents of existing your Droonga cluster.

For example, if your cluster is constructed from two nodes `192.168.0.10` and `192.168.0.11`, and now you are logged in to the host `192.168.0.12` then the command line is:

~~~
# drndump --host=192.168.0.10 \
           --receiver-host=192.168.0.12
{
  "type": "table_create",
  "dataset": "Default",
  "body": {
    "name": "Location",
    "flags": "TABLE_HASH_KEY",
    "key_type": "WGS84GeoPoint"
  }
}
...
{
  "dataset": "Default",
  "body": {
    "table": "Store",
    "key": "Fashion Inst of Technology - New York NY",
    "values": {
      "location": "146689013x-266380405"
    }
  },
  "type": "add"
}
{
  "type": "column_create",
  "dataset": "Default",
  "body": {
    "table": "Location",
    "name": "store",
    "type": "Store",
    "flags": "COLUMN_INDEX",
    "source": "location"
  }
}
{
  "type": "column_create",
  "dataset": "Default",
  "body": {
    "table": "Term",
    "name": "store__key",
    "type": "Store",
    "flags": "COLUMN_INDEX|WITH_POSITION",
    "source": "_key"
  }
}
~~~

Note to these things:

 * You must specify valid host name or IP address of one of nodes in the cluster, via the option `--host`.
 * You must specify valid host name or IP address of the computer you are logged in, via the option `--receiver-host`.
   It is used by the Droonga cluster, to send messages.
 * The result includes complete commands to construct a dataset, same to the source.

The result is printed to the standard output.
To save it as a JSONs file, you'll use a redirection like:

    # drndump --host=192.168.0.10 \
              --receiver-host=192.168.0.12 \
        > dump.jsons


## Restore data to a Droonga cluster

### Install `droonga-client`

The result of `drndump` command is a list of Droonga messages.

You need to use `droonga-request` command to send it to your Droogna cluster.
Install the command included in the package `droonga-client`, via rubygems:

    # gem install droonga-client

After that, establish that the `droonga-request` command has been installed successfully:

    # droonga-request --version
    droonga-request 0.1.7

### Restore data from a dump result, to an empty Droonga cluster

Because the result of the `drndump` command includes complete information to construct a dataset same to the source, you can re-construct your cluster from a dump file, even if the cluster is broken.
You just have to pour the contents of the dump file to an empty cluster, by the `droonga-request` command.

For example, if your cluster is empty and constructed from two nodes `192.168.0.10` and `192.168.0.11`, now your are logged in to the host `192.168.0.12`, and there is a dump file `dump.jsons` in the current directory, then the command line is:

~~~
# droonga-request --host=192.168.0.10 \
                    --receiver-host=192.168.0.12 \
                    dump.jsons
Elapsed time: 0.027541763
{
  "inReplyTo": "1401099940.5548894",
  "statusCode": 200,
  "type": "table_create.result",
  "body": [
    [
      0,
      1401099940.591563,
      0.00031876564025878906
    ],
    true
  ]
}
...
Elapsed time: 0.008678467
{
  "inReplyTo": "1401099941.0794394",
  "statusCode": 200,
  "type": "column_create.result",
  "body": [
    [
      0,
      1401099941.1154332,
      0.00027871131896972656
    ],
    true
  ]
}
~~~

Note to these things:

 * You must specify valid host name or IP address of one of nodes in the cluster, via the option `--host`.
 * You must specify valid host name or IP address of the computer you are logged in, via the option `--receiver-host`.
   It is used by the Droonga cluster, to send response messages.


### Duplicate data from another Droonga cluster, to an empty Droonga cluster

If you have multiple Droonga clusters, then you can duplicate one to another with `drndump` and `droonga-request` commands.

The command `drndump` reports its result to the standard output.
On the other hand, `droonga-request` can receive messages from the standard input.
So, you just connect them with a pipe, to duplicate contents of a cluster to another.

For example, if there are two clusters: the source has two nodes `192.168.0.10` and `192.168.0.11`, the destination has two nodes `192.168.0.20` and `192.168.0.21`, and now your are logged in to the host `192.168.0.12`, then the command line is:

~~~
# drndump --host=192.168.0.10 \
           --receiver-host=192.168.0.12 | \
    droonga-request --host=192.168.0.20 \
                    --receiver-host=192.168.0.12
Elapsed time: 0.027541763
{
  "inReplyTo": "1401099940.5548894",
  "statusCode": 200,
  "type": "table_create.result",
  "body": [
    [
      0,
      1401099940.591563,
      0.00031876564025878906
    ],
    true
  ]
}
...
Elapsed time: 0.008678467
{
  "inReplyTo": "1401099941.0794394",
  "statusCode": 200,
  "type": "column_create.result",
  "body": [
    [
      0,
      1401099941.1154332,
      0.00027871131896972656
    ],
    true
  ]
}
~~~


## Conclusion

In this tutorial, you did backup a [Droonga][] cluster and restore the data.
Moreover, you did duplicate contents of an existing Droogna cluster to another empty cluster.

Next, let's learn [how to add a new replica to an existing Droonga cluster](../add-replica/).

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
