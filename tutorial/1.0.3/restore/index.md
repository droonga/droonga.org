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
  Please complete [the "getting started" tutorial](../groonga/) before this.
* The `dump` plugin must be registered to the `catalog.json` of your Droonga cluster.
  If not, you must add the plugin to the list of `plugins`, like:
  
      - "plugins": ["groonga", "crud", "search"],
      + "plugins": ["groonga", "crud", "search", "dump"],

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

For example, if your cluster is constructed from two nodes `192.168.0.10` and `192.168.0.11`, and now your are logged in to the host `192.168.0.12` then the command line is:

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

 * You must specify valid host name or IP address of one of nodes, via the option `--host`.
 * You must specify valid host name or IP address of the computer you are logged in, via the option `--receiver-host`.
   It is used by the Droonga cluster, to send messages.

The result is printed to the standard output.
To save it as a JSONs file, you'll use a redirection like:

    # drndump --host=192.168.0.10 \
               --receiver-host=192.168.0.12 \
        > dump.jsons


## Restore data to a Droonga cluster

TBD

### Install `droonga-client`

TBD

### Restore data from a dump result

TBD

### Replicate data from another Droonga cluster

TBD

## Conclusion

In this tutorial, you did backup a [Droonga][] cluster and restore the data.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
